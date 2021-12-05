imgui = require 'imgui'

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local mem = require 'memory'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local Matrix3X3 = require'matrix3x3'
local Vector3D = require'vector3d'

local ffi = require "ffi"
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

local script_loaded = false

local font_dmginformer = renderCreateFont('Calibri', 10)
local hits = {}
local warnings = {}

local notify_data = {}


local damage_informer_change_pos = false
local damage_informer = {
    pattern = '[{H}:{M}:{S}] {O-NAME}[{O-ID}] > {WEAPON}[{WEAPON-ID}], {DISTANCE} m, ls {LS}, {O-SPEED} vs {T-SPEED} > {T-NAME}[{T-ID}] B: {B-NAME}[{B-ID}] {FF2222} {WARNINGS}',
    pattern_misses = '[{H}:{M}:{S}] {O-NAME}[{O-ID}] > {WEAPON}[{WEAPON-ID}], ls {LS} > {6495ED}ПРОМАХ',
    draw = {
        active = true,
        spectate = false,
        count = 5,
        positions = {
            x = 500,
            y = 500,
        },
        font = {
            name = 'Calibri',
            size = 10,
            style = 0,
        }
    }
}

local notepad = {}

local additionally = {
    vehicle = {
        speedhack = {
            active = false,
            smooth = 1.0,
            max_speed = 60.0,
        },
        flip_on_wheels = {
            active = false,
        },
        god_mode = {
            active = false,
            on = false,
        },
        anti_boom = {
            active = false,
        },
        engine = {
            active = false,
        },
        anti_bike_fall = {
            active = false,
        }
    },
    player = {
        god_mode = {
            active = false,
            on = false,
        },

    },
    guns = {
        aim = {
            active = false,
        }
    },
    visual = {
        wallhack = {
            active = false,
            name_tag = false,
            bones = false,
        },
        info_bar = {
            active = false,
            ping = false,
            fps = false,
            time = false,
            coords = false,
            id = false,
        },
        tracers = {
            active = false,
        },
        aim_line = {
            active = false,
        },
    },
    other = {
        airbrake = {
            active = false,
            on = false,
            speed = 60.0,
        },
        click_warp = {
            active = false,
            on = false,
        },
        fast_map = {
            active = false,
        },
        hud_fix = {
            active = false,
        }
    }
}

local navigation = {
    current = 1,
    show = true,
    list = {"Commands", "Fast Actions", "Damage Informer", "Warnings", "Notepad", 'Logs', 'Additionally', 'Settings', 'Credits'}
}

-- 
local spectate_id
local spectate_status
local current_report_actions = {}
local report_status 
local report_all_actions = {
    help = {
        ['"Сейчас помогу" в /ames'] = {'/ames {id} Сейчас попробую помочь вам.'},
        ['Войти в слежку за {id}'] = {'/re {id}'},
        ['Пожелать приятной игры'] = {'/ames {id} Приятной игры!'},
        ['Слапнуть игрока'] = {'/slap {id}'},
    },
    aim = {
        ['"Жалоба принята" в /ames'] = {'/ames {id} Понятно, проверим.'},
        ['Войти в слежку за {id}'] = {'/re {id}'},
        ['Войти в слежку за {report-id}'] = {'/re {report-id}'},
        ['Включить shotinfo+keyinfo'] = {'/shotinfo', '/keyinfo'},
    },
    wh = {
        ['"Жалоба принята" в /ames'] = {'/ames {id} Понятно, проверим.'},
        ['Войти в слежку за {id}'] = {'/re {id}'},
        ['Войти в слежку за {report-id}'] = {'/re {report-id}'},
    },
    speed = {
        ['"Жалоба принята" в /ames'] = {'/ames {id} Понятно, проверим.'},
        ['Войти в слежку за {id}'] = {'/re {id}'},
        ['Войти в слежку за {report-id}'] = {'/re {report-id}'},
    },
    dm = {
        ['"Жалоба принята" в /ames'] = {'/ames {id} Понятно, проверим.'},
        ['/chlog жертвы'] = {'/re {id}'},
        ['/chlog нападающего'] = {'/re {report-id}'},
        ['/dhist жертвы'] = {'/re {id}'},
    },
    other = {
        ['"Работаю по вашей ЖБ" в /ames'] = {'/ames {id} Окей.'},
        ['Войти в слежку за {id}'] = {'/re {id}'},
        ['Войти в слежку за {report-id}'] = {'/re {report-id}'},
    },
}

local admin_commands = {}

local fast_actions = {}

local settings = {
    report_handler = {
        active = false,
        fast_ames = {
            active = false,
            key = '0x65',
        },
        report_actions = {
            active = false,
        }
    },
    cmd_helper = {
        active = false,
        lines = 10,
        y = 10,
    },
}

local font = renderCreateFont("Arial", 8, 5)
local id_global
local regex = "Жалоба от (%S+) %[ID (%d+)]: (.+)"
local target_menu_key = 0x02
local keys_cursor = {0x12, 0xA2}

local window = imgui.ImBool(false)
local find_commands_buffer = imgui.ImBuffer(128)
local fast_actions_active_buffer = imgui.ImBool(true)
local fast_actions_imgui_model = {
    active = imgui.ImBool(true),
    category = imgui.ImInt(0),
    commands = imgui.ImBuffer(512),
    commands_delay = imgui.ImInt(0),
    keycode = imgui.ImBuffer(28),
    description = imgui.ImBuffer(256)
}
local dmg_informer_imgui_model = {
    pattern = imgui.ImBuffer(512),
    pattern_misses = imgui.ImBuffer(512),
    combo_player = imgui.ImInt(0),
    combo_page = imgui.ImInt(0),
    max_in_page = imgui.ImInt(25),
    min_in_page = imgui.ImInt(10),
    to = imgui.ImBool(false),
    draw = {
        active = imgui.ImBool(true),
        spectate = imgui.ImBool(false),
        count = imgui.ImInt(5),
        font = {
            name = imgui.ImBuffer(128),
            size = imgui.ImInt(10),
            style = imgui.ImInt(0),
        }
    }
}

local warnings_imgui_model = {
    combo_player = imgui.ImInt(0),
    combo_page = imgui.ImInt(0),
    max_in_page = imgui.ImInt(25),
    min_in_page = imgui.ImInt(10),
    to = imgui.ImBool(false),
}

local notepad_imgui_model = {
    name = imgui.ImBuffer(256),
    text = imgui.ImBuffer(2048),
    show_id = 0
}

local additionally_imgui_model = {
    vehicle = {
        speedhack = {
            active = imgui.ImBool(false),
            smooth = imgui.ImFloat(1.0),
            max_speed = imgui.ImFloat(60.0),
        },
        flip_on_wheels = {
            active = imgui.ImBool(false),
        },
        god_mode = {
            active = imgui.ImBool(false),
            on = imgui.ImBool(false),
        },
        anti_boom = {
            active = imgui.ImBool(false),
        },
        engine = {
            active = imgui.ImBool(false)
        },
        anti_bike_fall = {
            active = imgui.ImBool(false)
        }
    },
    player = {
        god_mode = {
            active = imgui.ImBool(false),
            on = imgui.ImBool(false),
        },

    },
    guns = {
        aim = {
            active = imgui.ImBool(false),
        }
    },
    visual = {
        wallhack = {
            active = imgui.ImBool(false),
            name_tag = imgui.ImBool(false),
            bones = imgui.ImBool(false),
        },
        info_bar = {
            active = imgui.ImBool(false),
            ping = imgui.ImBool(false),
            fps = imgui.ImBool(false),
            time = imgui.ImBool(false),
            coords = imgui.ImBool(false),
            id = imgui.ImBool(false),
        },
        tracers = {
            active = imgui.ImBool(false),
        },
        aim_line = {
            active = imgui.ImBool(false),
        },
    },
    other = {
        airbrake = {
            active = imgui.ImBool(false),
            on = imgui.ImBool(false),
            speed = imgui.ImFloat(60.0),
        },
        click_warp = {
            active = imgui.ImBool(false),
            on = imgui.ImBool(false),
        },
        fast_map = {
            active = imgui.ImBool(false),
        },
        hud_fix = {
            active = imgui.ImBool(false),
        }
    },
    navigation = {
        current = 0,
        show = false,
        list = {"Vehicles", "Actor", "Guns", "Visuals", "Other"}
    }
}

local settings_imgui_model = {
    report_handler = {
        active = imgui.ImBool(false),
        fast_ames = {
            active = imgui.ImBool(false),
            key = imgui.ImBuffer(32),
        },
        report_actions = {
            active = imgui.ImBool(false),
        }
    },
    cmd_helper = {
        active = imgui.ImBool(false),
        lines = imgui.ImInt(10),
        y = imgui.ImInt(10),
    },
}

local logs = {
    settings = {

    },
    messages = {

    }
}

local logs_imgui_model = {
    {
        ['Глобально'] = imgui.ImBool(false),
    },
    {
        ["Report"] = imgui.ImBool(false),
    },
    {
        ["Admin"] = imgui.ImBool(false),
    },
    {
        ["Helper"] = imgui.ImBool(false),
    },
    {
        ["ASK"] = imgui.ImBool(false),
    },
    { --Тут чилд уже не создаётся
        sl = 'imgui.SameLine()',
    },
    { --Тут чилд уже не создаётся
        ["AD"] = imgui.ImBool(false),
    },
    { --Создаётся Child так как элементов в этой таблице дахуя, ну и размер чилда подстраивается под количество элементов, тут элементы очень хаотично расбросаны
        ["Studio"] = imgui.ImBool(false),
        ['Количество'] = imgui.ImInt(0), --тут создаётся InputInt с названием Количество
        handler = { --Создавать обработчик не обязательно
            func = function(args)
                print(args.name, args.value.v) -- вот что возвращается обработчиком: name - название с которым выводится элемент на который нажали, value - его значение в userdata
            end,
            use_for = {'Studio'} -- обработчик юзается только для элемента с таким названием, в массиве который выше чем use_for
        }
    },
    { --Создаётся Child так как элементов в этой таблице дахуя, ну и размер чилда подстраивается под количество элементов, а тут они норм, но для каждого надо прописывать handler
        {
            ['PM'] = imgui.ImBool(false),
            handler = { 
                func = function(args) --Функция обработчик
                    print(args.name, args.value.v)
                end,
                use_for = {} --если массив пустой, значит обработчик юзается для всех полей
            }
        },
        {
            ['Количество'] = imgui.ImInt(0),
            handler = { 
                func = function(args) --Функция обработчик
                    print(args.name, args.value.v)
                end,
                use_for = {} --если массив пустой, значит обработчик юзается для всех полей
            }
        },
        {
            ['Тестовое'] = imgui.ImBuffer(12),
            handler = { 
                func = function(args) --Функция обработчик
                    print(args.name, args.value.v)
                end,
                use_for = {} --если массив пустой, значит обработчик юзается для всех полей
            }
        },
        {
            privet = 'О ку ку',--Рисуется текст О ку ку
        }   
    }
}



local fontsize = nil
function imgui.BeforeDrawFrame()
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arial.ttf', 8.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
end

function imgui.OnDrawFrame()
    if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(700, 450), imgui.Cond.FirstUseEver, imgui.ImVec2(0.6, 0.6))
        imgui.SetNextWindowSize(imgui.ImVec2(1000, 585), imgui.Cond.FirstUseEver)
        imgui.Begin('IAdminTools', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
            if true then --Тайтл-бар
                imgui.Text(' ') --Костыль
                imgui.SameLine()  
                for i, title in ipairs(navigation.list) do --Кнопки навигации
                    if HeaderButton(navigation.current == i, title) then
                        navigation.current = i
                        navigation.show = true
                    end
                    if i ~= #navigation.list then
                        imgui.SameLine(nil, 30)
                    end
                end
                imgui.SameLine()
                imgui.SetCursorPosX(imgui.GetWindowSize().x - 30)
                imgui.PushFont(fontsize)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.00, 0.82, 0.39, 0.30))
                if imgui.Button('x', imgui.ImVec2(15, 15)) then
                    window.v = false
                end
                imgui.PopStyleColor() 
                imgui.PopFont()
            end
            if true then --Предзагрузка данных
                if navigation.current == 1 and navigation.show == true then --Команды 
                    navigation.show = false
                end
                if navigation.current == 2 and navigation.show == true then --FastActions
                    navigation.show = false
                    if fast_actions.active == nil then
                        fast_actions.active = true
                    end
                    fast_actions_active_buffer.v = fast_actions.active
                end
                if navigation.current == 3 and navigation.show == true then -- DamageInformer
                    navigation.show = false
                    dmg_informer_imgui_model.pattern.v = u8(damage_informer.pattern)
                    dmg_informer_imgui_model.pattern_misses.v = u8(damage_informer.pattern_misses)
                    dmg_informer_imgui_model.draw.active.v = damage_informer.draw.active
                    dmg_informer_imgui_model.draw.spectate.v = damage_informer.draw.spectate
                    dmg_informer_imgui_model.draw.count.v = damage_informer.draw.count
                    dmg_informer_imgui_model.draw.font.name.v = damage_informer.draw.font.name
                    dmg_informer_imgui_model.draw.font.size.v = damage_informer.draw.font.size
                    dmg_informer_imgui_model.draw.font.style.v = damage_informer.draw.font.style
                end
                if navigation.current == 4 and navigation.show == true then -- Warnings
                    navigation.show = false
                    imgui.OpenPopup(u8'Warnings')
                end
                if navigation.current == 5 and navigation.show == true then --Notepad
                    navigation.show = false
                    imgui.OpenPopup(u8'Notepad')
                end
                if navigation.current == 6 and navigation.show == true then --Logs
                    navigation.show = false
                end
                if navigation.current == 7 and navigation.show == true then --Additionally
                    navigation.show = false
                end
                if navigation.current == 8 and navigation.show == true then --Settings 
                    settings_imgui_model.cmd_helper.active.v = settings.cmd_helper.active
                    settings_imgui_model.cmd_helper.lines.v = settings.cmd_helper.lines
                    settings_imgui_model.cmd_helper.y.v = settings.cmd_helper.y
                    settings_imgui_model.report_handler.active.v = settings.report_handler.active
                    settings_imgui_model.report_handler.fast_ames.active.v = settings.report_handler.fast_ames.active
                    settings_imgui_model.report_handler.fast_ames.key.v = settings.report_handler.fast_ames.key
                    settings_imgui_model.report_handler.report_actions.active.v = settings.report_handler.report_actions.active
                    navigation.show = false
                end
                if navigation.current == 9 and navigation.show == true then --Credits
                    navigation.show = false
                end
            end

            imgui.BeginChild('MainChild', imgui.ImVec2(980, 550), true) --Окна
                if navigation.current == 1 then --Команды
                    imgui.InputText(u8' << Поиск', find_commands_buffer)
                    for key, value in ipairs(admin_commands) do
                        collaps_status = imgui.CollapsingHeader(value.category, true)
                        if find_commands_buffer.v ~= '' then
                            collaps_status = true
                        end
                        if collaps_status then
                            for key2, value2 in ipairs(value.commands) do
                                if rusLower(value2.text):find(rusLower(find_commands_buffer.v), nil, true) or rusLower(value2.command):find(rusLower(find_commands_buffer.v), nil, true) then
                                    if imgui.Button(value2.command) then
                                        sampSetChatInputEnabled(true)
                                        sampSetChatInputText(value2.command)
                                        window.v = false
                                    end
                                    imgui.SameLine()
                                    imgui.Text(value2.text)
                                end
                            end
                        end
                    end
                end
                
                if navigation.current == 2 then --FastActions
                    if imgui.Button(u8'Добавить', imgui.ImVec2(135, 20)) then
                        imgui.OpenPopup(u8'Добавить')
                    end
                    imgui.SameLine();
                    if imgui.ToggleButton('##active_add', fast_actions_active_buffer) then
                        fast_actions.active = fast_actions_active_buffer.v
                        saveFastActions()
                    end
                    imgui.SameLine()
                    imgui.Text(u8' <- Активно')
                    if imgui.BeginPopupModal(u8'Добавить', nil, imgui.WindowFlags.AlwaysAutoResize) then
                        if imgui.CollapsingHeader(u8' FAQ ', true) then
                            imgui.Text(u8'Ниже записаны паттерны которые вы можете использовать в поле "Команды": ')
                            imgui.Text(u8'{ID} - ИД игрока в отношении которого вы хотите использовать команду.\n')
                            imgui.Text(u8'Коды клавиш тут: http://arininav.ru/js/keycodes.htm')
                        end
                        imgui.ToggleButton('##active_add', fast_actions_imgui_model.active); imgui.SameLine(); imgui.Text(u8' <- Активно')
                        imgui.RadioButton(u8" <- Везде", fast_actions_imgui_model.category, 0)
                        imgui.RadioButton(u8" <- В TV", fast_actions_imgui_model.category, 1)
                        imgui.RadioButton(u8" <- Вне TV", fast_actions_imgui_model.category, 2)
                        imgui.InputText(u8' <- Код клавиши (Пример: 0x01)', fast_actions_imgui_model.keycode)
                        imgui.InputInt(u8' <- Задержка между командами', fast_actions_imgui_model.commands_delay)
                        imgui.InputText(u8' <- Описание', fast_actions_imgui_model.description)
                        imgui.Text(u8'Команды')
                        imgui.InputTextMultiline("##commands_multline_add", fast_actions_imgui_model.commands, imgui.ImVec2(250, 100))
                        imgui.Separator()
                        if imgui.Button(u8'CLOSE') then
                            imgui.CloseCurrentPopup()
                        end
                        imgui.SameLine()
                        if imgui.Button(u8'SAVE') then
                            if  fast_actions_imgui_model.description.v ~= '' and  fast_actions_imgui_model.commands.v ~= '' then
                                local cmds = {}
                                for k in string.gmatch(fast_actions_imgui_model.commands.v, "[^\r\n]+") do
                                    table.insert(cmds, k)
                                end
                                if fast_actions.actions == nil then
                                    fast_actions.actions = {}
                                    
                                end
                                if fast_actions.active == nil then
                                    fast_actions.active = true
                                end
                                table.insert(
                                    fast_actions.actions, 
                                    {
                                        active = fast_actions_imgui_model.active.v,
                                        category = fast_actions_imgui_model.category.v,
                                        commands = cmds,
                                        commands_delay = fast_actions_imgui_model.commands_delay.v,
                                        keycode = fast_actions_imgui_model.keycode.v,
                                        description = fast_actions_imgui_model.description.v,
                                    }
                                )
                                saveFastActions()
                                imgui.CloseCurrentPopup()
                            else
                                sampAddChatMessage('Заполните поля: Описание, Команды', -1)
                            end
                        end
                        imgui.EndPopup()
                    end
                    imgui.Separator()
                    if fast_actions.actions ~= nil then
                        for key, action in ipairs(fast_actions.actions) do
                            if imgui.Button(u8'DEL##'..tostring(key)) then
                                table.remove(fast_actions.actions, key)
                                saveFastActions()
                            end            
                            imgui.SameLine()
                            if imgui.Button(action.description..'##'..tostring(key), imgui.ImVec2(205, 20)) then
                                fast_actions_imgui_model.active.v = action.active
                                fast_actions_imgui_model.category.v = action.category
                                fast_actions_imgui_model.keycode.v = action.keycode
                                fast_actions_imgui_model.commands_delay.v = action.commands_delay
                                fast_actions_imgui_model.description.v = action.description
                                local temp_commands = {}
                                for keySplit, valSplit in pairs(action.commands) do
                                    table.insert(temp_commands, valSplit)
                                end
                                fast_actions_imgui_model.commands.v = table.concat(temp_commands, "\n")
                                imgui.OpenPopup(u8'Изменить##'..tostring(key))
                            end
                            if imgui.BeginPopupModal(u8'Изменить##'..tostring(key), nil, imgui.WindowFlags.AlwaysAutoResize) then
                                if imgui.CollapsingHeader(u8' FAQ ', true) then
                                    imgui.Text(u8'Ниже записаны паттерны которые вы можете использовать в поле "Команды": ')
                                    imgui.Text(u8'{ID} - ИД игрока в отношении которого вы хотите использовать команду.\n')
                                    imgui.Text(u8'Коды клавиш тут: http://arininav.ru/js/keycodes.htm')
                                end
                                imgui.ToggleButton('##active_add', fast_actions_imgui_model.active); imgui.SameLine(); imgui.Text(u8' <- Активно')
                                imgui.RadioButton(u8" <- Везде", fast_actions_imgui_model.category, 0)
                                imgui.RadioButton(u8" <- В TV", fast_actions_imgui_model.category, 1)
                                imgui.RadioButton(u8" <- Вне TV", fast_actions_imgui_model.category, 2)
                                imgui.InputText(u8' <- Код клавиши (Пример: 0x01)', fast_actions_imgui_model.keycode)
                                imgui.InputInt(u8' <- Задержка между командами', fast_actions_imgui_model.commands_delay)
                                imgui.InputText(u8' <- Описание', fast_actions_imgui_model.description)
                                imgui.Text(u8'Команды')
                                imgui.InputTextMultiline("##commands_multline_add", fast_actions_imgui_model.commands, imgui.ImVec2(250, 100))
                                imgui.Separator()
                                if imgui.Button(u8'CLOSE') then
                                    imgui.CloseCurrentPopup()
                                end
                                imgui.SameLine()
                                if imgui.Button(u8'SAVE') then
                                    if  fast_actions_imgui_model.description.v ~= '' and  fast_actions_imgui_model.commands.v ~= '' then
                                        local cmds = {}
                                        for k in string.gmatch(fast_actions_imgui_model.commands.v, "[^\r\n]+") do
                                            table.insert(cmds, k)
                                        end
                                        action.active = fast_actions_imgui_model.active.v
                                        action.category = fast_actions_imgui_model.category.v
                                        action.commands = cmds
                                        action.commands_delay = fast_actions_imgui_model.commands_delay.v
                                        action.keycode = fast_actions_imgui_model.keycode.v
                                        action.description = fast_actions_imgui_model.description.v
                                        saveFastActions()
                                        imgui.CloseCurrentPopup()
                                    else
                                        sampAddChatMessage('Заполните поля: Описание, Команды', -1)
                                    end
                                end
                                imgui.EndPopup()
                            end
                        end
                    end
                end

                if navigation.current == 3 then --Damage Informer
                    if imgui.CollapsingHeader(u8' SETTINGS ', true) then
                        imgui.BeginChild('Settings', imgui.ImVec2(960, 370), true)
                            if imgui.CollapsingHeader(u8' FAQ ', true) then
                                imgui.BeginChild('faq', imgui.ImVec2(940, 120), true)
                                    imgui.Text(u8'Ниже записаны паттерны которые вы можете использовать в поля "Вид строки": ')
                                    imgui.Text(u8'{H} - Время. Час.')
                                    imgui.Text(u8'{M} - Время. Минута.')
                                    imgui.Text(u8'{S} - Время. Секунда.')
                                    imgui.Text(u8'{O-NAME} - Ник игрока который нанес урон.')
                                    imgui.Text(u8'{O-ID} - ID игрока который нанес урон.')
                                    imgui.Text(u8'{WEAPON} - Название оружия.')
                                    imgui.Text(u8'{WEAPON-ID} - ID Оружия.')
                                    imgui.Text(u8'{DISTANCE} - Дистанция.')
                                    imgui.Text(u8'{LS} - Время которое прошло от последнего выстрела этого игрока.')
                                    imgui.Text(u8'{O-SPEED} - Скорость игрока который нанес урон.')
                                    imgui.Text(u8'{T-SPEED} - Скорость игрока/автомобиля которому нанесли урон.')
                                    imgui.Text(u8'{T-NAME} - Ник/название игрока/автомобиля которому нанесли урон.')
                                    imgui.Text(u8'{T-ID} - ID игрока/автомобиля которому нанесли урон.')
                                    imgui.Text(u8'{B-NAME} - Название кости в которую пришёл урон.')
                                    imgui.Text(u8'{B-ID} - ID кости в которую пришёл урон.')
                                    imgui.Text(u8'{WARNINGS} - Варинги на стрельбу сквозь текстуры/машину.')
                                imgui.EndChild()
                            end
                            imgui.BeginChild('global', imgui.ImVec2(940, 90), true)
                                imgui.Text('   Global')
                                imgui.InputText(u8' << Вид строки', dmg_informer_imgui_model.pattern)
                                imgui.InputText(u8' << Вид строки (промахи)', dmg_informer_imgui_model.pattern_misses)
                            imgui.EndChild()
                            imgui.BeginChild('draw', imgui.ImVec2(940, 205), true)
                                imgui.Text('   Draw')
                                imgui.ToggleButton('Входной/Выходной', dmg_informer_imgui_model.draw.active); imgui.SameLine(); imgui.Text(u8(' << Активно'))
                                imgui.ToggleButton('Касательно объекта слежки', dmg_informer_imgui_model.draw.spectate); imgui.SameLine(); imgui.Text(u8(' << Касательно объекта слежки'))
                                imgui.InputInt(u8' << Количество строк', dmg_informer_imgui_model.draw.count)
                                if imgui.Button(u8'Изменить позицию') then
                                    window.v = false
                                    damage_informer_change_pos = not damage_informer_change_pos
                                    sampAddChatMessage('Зажмите Ctrl+Alt для изменения позиции', -1)
                                end
                                imgui.Text('   Font')
                                imgui.InputText(u8' << Вид строки (промахи)', dmg_informer_imgui_model.draw.font.name)
                                imgui.InputInt(u8' << Размер', dmg_informer_imgui_model.draw.font.size)
                                imgui.InputInt(u8' << Стиль', dmg_informer_imgui_model.draw.font.style)
                            imgui.EndChild()
                            imgui.Separator()
                            if imgui.Button(u8'SAVE') then
                                damage_informer.pattern = u8:decode(dmg_informer_imgui_model.pattern.v)
                                damage_informer.pattern_misses = u8:decode(dmg_informer_imgui_model.pattern_misses.v)
                                damage_informer.draw.active = dmg_informer_imgui_model.draw.active.v 
                                damage_informer.draw.spectate = dmg_informer_imgui_model.draw.spectate.v
                                damage_informer.draw.count = dmg_informer_imgui_model.draw.count.v
                                damage_informer.draw.font.name = dmg_informer_imgui_model.draw.font.name.v
                                damage_informer.draw.font.size = dmg_informer_imgui_model.draw.font.size.v
                                damage_informer.draw.font.style = dmg_informer_imgui_model.draw.font.style.v
                                saveDamageInformer()
                                updateFontDamageInformer()
                            end
                        imgui.EndChild()
                    end
                    if #hits > 0 then
                        imgui.BeginChild('filters', imgui.ImVec2(960, 70), true)
                            local players_list = imgui_getAllPlayers(hits)
                            imgui.PushItemWidth(145)
                            imgui.Combo(u8'                     ', dmg_informer_imgui_model.combo_player, players_list, #players_list)
                            imgui.SameLine();
                            imgui.ToggleButton('Входной/Выходной', dmg_informer_imgui_model.to); imgui.SameLine(); imgui.Text(u8(' << Выходной/Входной               '))
                            pages = imgui_Paginate(imgui_filterFromName(hits, players_list[dmg_informer_imgui_model.combo_player.v + 1], dmg_informer_imgui_model.to.v), dmg_informer_imgui_model.max_in_page.v, dmg_informer_imgui_model.min_in_page.v)
                            local pages_names = imgui_getPagesName(pages)
                            imgui.SameLine();
                            imgui.PushItemWidth(95)
                            imgui.Combo(u8' << Страничка', dmg_informer_imgui_model.combo_page, pages_names, #pages_names)
                            imgui.PushItemWidth(80)
                            imgui.InputInt(u8' << Максимально на странице                              ', dmg_informer_imgui_model.max_in_page)
                            if dmg_informer_imgui_model.max_in_page.v < (dmg_informer_imgui_model.min_in_page.v + 1) then
                                dmg_informer_imgui_model.max_in_page.v = dmg_informer_imgui_model.max_in_page.v + 1
                            end
                            imgui.SameLine();
                            imgui.PushItemWidth(80)
                            imgui.InputInt(u8' << Минимально на странице', dmg_informer_imgui_model.min_in_page)
                        imgui.EndChild()
                        imgui.BeginChild('log', imgui.ImVec2(960, 0), true)
                            if #pages > 0 then
                                if pages[dmg_informer_imgui_model.combo_page.v + 1] then
                                    for key, hit in ipairs(pages[dmg_informer_imgui_model.combo_page.v + 1]) do
                                        if hit.target_name then
                                            local text = string.gsub(generateShotInfoText(hit, damage_informer.pattern), '{[a-f0-9A-F]+}', '')
                                            imgui.Text(u8(text))
                                        else
                                            local text = string.gsub(generateShotInfoText(hit, damage_informer.pattern_misses), '{[a-f0-9A-F]+}', '')
                                            imgui.Text(u8(text))
                                        end
                                    end
                                end
                            end
                        imgui.EndChild() 
                    end
                end
                
                if navigation.current == 4 then -- Warnings
                    if #warnings > 0 then
                        imgui.BeginChild('filters', imgui.ImVec2(960, 35), true)
                            local players_list = imgui_getAllPlayers(warnings)
                            imgui.PushItemWidth(145)
                            imgui.Combo(u8'   ', warnings_imgui_model.combo_player, players_list, #players_list)
                            imgui.SameLine();
                            imgui.PushItemWidth(95)
                            pages = imgui_Paginate(imgui_filterFromName(warnings, players_list[warnings_imgui_model.combo_player.v + 1], warnings_imgui_model.to.v), warnings_imgui_model.max_in_page.v, warnings_imgui_model.min_in_page.v)
                            local pages_names = imgui_getPagesName(pages)
                            imgui.Combo(u8'    ', warnings_imgui_model.combo_page, pages_names, #pages_names)
                            imgui.SameLine();
                            imgui.PushItemWidth(80)
                            imgui.InputInt(u8' << Максимально на странице   ', warnings_imgui_model.max_in_page)
                            if warnings_imgui_model.max_in_page.v < (warnings_imgui_model.min_in_page.v + 1) then
                                warnings_imgui_model.max_in_page.v = warnings_imgui_model.max_in_page.v + 1
                            end
                            imgui.SameLine();
                            imgui.PushItemWidth(80)
                            imgui.InputInt(u8' << Минимально на странице', warnings_imgui_model.min_in_page)
                        imgui.EndChild()
                        imgui.BeginChild('log', imgui.ImVec2(960, 0), true)
                            if #pages > 0 then
                                if pages[warnings_imgui_model.combo_page.v + 1] then
                                    for key, warning in ipairs(pages[warnings_imgui_model.combo_page.v + 1]) do
                                        imgui.BeginChild('texts'..tostring(key), imgui.ImVec2(0, 35), true)
                                            for key2, text in ipairs(warning.texts) do
                                                imgui.TextColored(imgui.ImVec4(1.0, 0.2, 0.02, 1), u8(text))
                                            end
                                        imgui.EndChild()
                                    end
                                end
                            end
                        imgui.EndChild()
                    else
                        imgui.Text(u8'Варнингов не было')
                    end
                end
                
                if navigation.current == 5 then -- Notepad
                    imgui.BeginChild('files', imgui.ImVec2(190+40, 0), true)
                        for key, file in ipairs(notepad) do
                            if imgui.Button(file.name, imgui.ImVec2(175+40, 20)) then
                                notepad_imgui_model.name.v = file.name
                                notepad_imgui_model.text.v = file.text
                                notepad_imgui_model.show_id = key
                            end
                        end
                        if imgui.Button(u8'Создать файл', imgui.ImVec2(175+40, 20)) then
                            local name = u8'Новый файл ('..(#notepad + 1)..')'
                            local text = u8'Example\nText'
                            table.insert(notepad, {name = name, text = text})
                            notepad_imgui_model.name.v = notepad[#notepad].name
                            notepad_imgui_model.text.v = notepad[#notepad].text
                            notepad_imgui_model.show_id = #notepad
                            saveNotepad()
                        end
                    imgui.EndChild()
    
                    imgui.SameLine()
    
                    imgui.BeginChild('Current File', imgui.ImVec2(0, 0), true)
                        if notepad_imgui_model.show_id ~= 0 then
                            imgui.PushItemWidth(630-40)
                            imgui.InputText('##name', notepad_imgui_model.name)
                            imgui.SameLine()
                            if imgui.Button(u8'SAVE', imgui.ImVec2(55, 20)) then
                                notepad[notepad_imgui_model.show_id].name = notepad_imgui_model.name.v
                                notepad[notepad_imgui_model.show_id].text = notepad_imgui_model.text.v
                                saveNotepad()
                            end
                            imgui.SameLine()
                            if imgui.Button(u8'DEL', imgui.ImVec2(55, 20)) then
                                imgui.OpenPopup(u8'Удалить файл?')
                            end
                            if imgui.BeginPopupModal(u8'Удалить файл?', nil, imgui.WindowFlags.NoCollapse) then
                                imgui.SetWindowSize(imgui.ImVec2(120, 60))
                                if imgui.Button(u8'ДА', imgui.ImVec2(48, 20)) then
                                    table.remove(notepad, notepad_imgui_model.show_id)
                                    notepad_imgui_model.name.v = ''
                                    notepad_imgui_model.text.v = ''
                                    notepad_imgui_model.show_id = 0
                                    saveNotepad()
                                    imgui.CloseCurrentPopup()
                                end
                                imgui.SameLine()
                                if imgui.Button(u8'НЕТ', imgui.ImVec2(48, 20)) then
                                    imgui.CloseCurrentPopup()
                                end
                                imgui.EndPopup()
                            end
                            imgui.InputTextMultiline('##sodez', notepad_imgui_model.text, imgui.ImVec2(750-40, 495))
                        else
                            imgui.Text(u8'Выберите или создайте файл')
                        end
                    imgui.EndChild()
                end
                
                if navigation.current == 6 then -- Logs
                    imgui.Text(u8'Этот раздел находится в разработке')
                    -- if imgui.CollapsingHeader(u8' SETTINGS ', true) then
                    --     imgui.BeginChild('Settings', imgui.ImVec2(960, 370), true)
                    --         local generated = imgui_GenerateGUI({table = logs_imgui_model, in_key = '', use_in_key = true, use_childs = true}) -- Возвращается массив
                    --         for k, v in ipairs(generated) do
                    --             if v.gui() then --Это гуи элемент
                    --                 if v.handler ~= false then --иногда нету обработчика, и возвращается false
                    --                     v.handler() --А это обработчик, его нужно запускать
                    --                 end
                    --             end
                    --         end
                    --         imgui.Separator()
                    --         if imgui.Button(u8'SAVE') then
                    --             damage_informer.pattern = u8:decode(dmg_informer_imgui_model.pattern.v)
                    --             damage_informer.pattern_misses = u8:decode(dmg_informer_imgui_model.pattern_misses.v)
                    --             damage_informer.draw.active = dmg_informer_imgui_model.draw.active.v 
                    --             damage_informer.draw.spectate = dmg_informer_imgui_model.draw.spectate.v
                    --             damage_informer.draw.count = dmg_informer_imgui_model.draw.count.v
                    --             damage_informer.draw.font.name = dmg_informer_imgui_model.draw.font.name.v
                    --             damage_informer.draw.font.size = dmg_informer_imgui_model.draw.font.size.v
                    --             damage_informer.draw.font.style = dmg_informer_imgui_model.draw.font.style.v
                    --             saveDamageInformer()
                    --             updateFontDamageInformer()
                    --         end
                    --     imgui.EndChild()
                    -- end
                end

                if navigation.current == 7 then -- Additionally
                    if true then --Тайтл-бар
                        imgui.Text(' ') --Костыль
                        imgui.SameLine()  
                        for i, title in ipairs(additionally_imgui_model.navigation.list) do --Кнопки навигации
                            if HeaderButton(additionally_imgui_model.navigation.current == i, title..'##'..tostring(i)) then
                                additionally_imgui_model.navigation.current = i
                                additionally_imgui_model.navigation.show = true
                            end
                            if i ~= #additionally_imgui_model.navigation.list then
                                imgui.SameLine(nil, 30)
                            end
                        end
                        imgui.SameLine()
                        imgui.SetCursorPosX(imgui.GetWindowSize().x - 65)
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.00, 0.82, 0.39, 0.30))
                        if imgui.Button('SAVE', imgui.ImVec2(50, 20)) then
                            if additionally_imgui_model.navigation.current == 1 then
                                additionally.vehicle.anti_boom.active = additionally_imgui_model.vehicle.anti_boom.active.v
                                additionally.vehicle.flip_on_wheels.active = additionally_imgui_model.vehicle.flip_on_wheels.active.v
                                additionally.vehicle.god_mode.active = additionally_imgui_model.vehicle.god_mode.active.v
                                additionally.vehicle.engine.active = additionally_imgui_model.vehicle.engine.active.v
                                additionally.vehicle.anti_bike_fall.active = additionally_imgui_model.vehicle.anti_bike_fall.active.v
                                additionally.vehicle.speedhack.active = additionally_imgui_model.vehicle.speedhack.active.v
                                additionally.vehicle.speedhack.smooth = additionally_imgui_model.vehicle.speedhack.smooth.v
                                additionally.vehicle.speedhack.max_speed = additionally_imgui_model.vehicle.speedhack.max_speed.v
                            end
                            if additionally_imgui_model.navigation.current == 2 then
                                additionally.player.god_mode.active = additionally_imgui_model.player.god_mode.active.v
                            end
                            if additionally_imgui_model.navigation.current == 3 then
                                additionally.guns.aim.active = additionally_imgui_model.guns.aim.active.v
                            end
                            if additionally_imgui_model.navigation.current == 4 then
                                additionally.visual.aim_line.active = additionally_imgui_model.visual.aim_line.active.v
                                additionally.visual.tracers.active = additionally_imgui_model.visual.tracers.active.v
                                additionally.visual.wallhack.active = additionally_imgui_model.visual.wallhack.active.v
                                additionally.visual.wallhack.bones = additionally_imgui_model.visual.wallhack.bones.v
                                additionally.visual.wallhack.name_tag = additionally_imgui_model.visual.wallhack.name_tag.v
                                additionally.visual.info_bar.active = additionally_imgui_model.visual.info_bar.active.v
                                additionally.visual.info_bar.coords = additionally_imgui_model.visual.info_bar.coords.v 
                                additionally.visual.info_bar.fps = additionally_imgui_model.visual.info_bar.fps.v
                                additionally.visual.info_bar.ping = additionally_imgui_model.visual.info_bar.ping.v
                                additionally.visual.info_bar.id = additionally_imgui_model.visual.info_bar.id.v
                                additionally.visual.info_bar.time = additionally_imgui_model.visual.info_bar.time.v
                            end
                            if additionally_imgui_model.navigation.current == 5 then
                                additionally.other.airbrake.active = additionally_imgui_model.other.airbrake.active.v 
                                additionally.other.airbrake.speed = additionally_imgui_model.other.airbrake.speed.v
                                additionally.other.click_warp.active = additionally_imgui_model.other.click_warp.active.v
                                additionally.other.fast_map.active = additionally_imgui_model.other.fast_map.active.v
                                additionally.other.hud_fix.active = additionally_imgui_model.other.hud_fix.active.v 
                            end
                            saveAdditionally()
                        end
                        imgui.PopStyleColor() 
                    end
                    if true then --DataPreload
                        if additionally_imgui_model.navigation.current == 1 and additionally_imgui_model.navigation.show == true then -- Vehicles
                            additionally_imgui_model.navigation.show = false
                            additionally_imgui_model.vehicle.anti_boom.active.v = additionally.vehicle.anti_boom.active
                            additionally_imgui_model.vehicle.flip_on_wheels.active.v = additionally.vehicle.flip_on_wheels.active
                            additionally_imgui_model.vehicle.god_mode.active.v = additionally.vehicle.god_mode.active
                            additionally_imgui_model.vehicle.engine.active.v = additionally.vehicle.engine.active
                            additionally_imgui_model.vehicle.anti_bike_fall.active.v = additionally.vehicle.anti_bike_fall.active
                            additionally_imgui_model.vehicle.speedhack.active.v = additionally.vehicle.speedhack.active
                            additionally_imgui_model.vehicle.speedhack.smooth.v = additionally.vehicle.speedhack.smooth
                            additionally_imgui_model.vehicle.speedhack.max_speed.v = additionally.vehicle.speedhack.max_speed
                        end
                        if additionally_imgui_model.navigation.current == 2 and additionally_imgui_model.navigation.show == true then -- Actor
                            additionally_imgui_model.navigation.show = false
                            additionally_imgui_model.player.god_mode.active.v = additionally.player.god_mode.active
                        end
                        if additionally_imgui_model.navigation.current == 3 and additionally_imgui_model.navigation.show == true then -- Guns
                            additionally_imgui_model.navigation.show = false
                            additionally_imgui_model.guns.aim.active.v = additionally.guns.aim.active
                        end
                        if additionally_imgui_model.navigation.current == 4 and additionally_imgui_model.navigation.show == true then -- Visuals
                            additionally_imgui_model.navigation.show = false
                            additionally_imgui_model.visual.aim_line.active.v = additionally.visual.aim_line.active
                            additionally_imgui_model.visual.tracers.active.v = additionally.visual.tracers.active
                            additionally_imgui_model.visual.wallhack.active.v = additionally.visual.wallhack.active
                            additionally_imgui_model.visual.wallhack.bones.v = additionally.visual.wallhack.bones
                            additionally_imgui_model.visual.wallhack.name_tag.v = additionally.visual.wallhack.name_tag
                            additionally_imgui_model.visual.info_bar.active.v = additionally.visual.info_bar.active
                            additionally_imgui_model.visual.info_bar.coords.v = additionally.visual.info_bar.coords
                            additionally_imgui_model.visual.info_bar.fps.v = additionally.visual.info_bar.fps
                            additionally_imgui_model.visual.info_bar.ping.v = additionally.visual.info_bar.ping
                            additionally_imgui_model.visual.info_bar.id.v = additionally.visual.info_bar.id
                            additionally_imgui_model.visual.info_bar.time.v = additionally.visual.info_bar.time
                        end
                        if additionally_imgui_model.navigation.current == 5 and additionally_imgui_model.navigation.show == true then -- Other
                            additionally_imgui_model.navigation.show = false
                            additionally_imgui_model.other.airbrake.active.v = additionally.other.airbrake.active
                            additionally_imgui_model.other.airbrake.speed.v = additionally.other.airbrake.speed
                            additionally_imgui_model.other.click_warp.active.v = additionally.other.click_warp.active
                            additionally_imgui_model.other.fast_map.active.v = additionally.other.fast_map.active
                            additionally_imgui_model.other.hud_fix.active.v = additionally.other.hud_fix.active
                        end
                    end
                    imgui.BeginChild('AdditionalyMenus', imgui.ImVec2(0, 0), true)
                        if additionally_imgui_model.navigation.current == 1 then -- Vehicles
                            imgui.ToggleButton('##antiboom', additionally_imgui_model.vehicle.anti_boom.active); imgui.SameLine(); imgui.Text(u8' << Не взрывать ТС при перевороте')
                            imgui.ToggleButton('##flip_on_wheels', additionally_imgui_model.vehicle.flip_on_wheels.active); imgui.SameLine(); imgui.Text(u8' << Перевернуть на колеса (Delete)')
                            imgui.ToggleButton('##god_mode', additionally_imgui_model.vehicle.god_mode.active); imgui.SameLine(); imgui.Text(u8' << GodMode (Home)')
                            imgui.ToggleButton('##engine', additionally_imgui_model.vehicle.engine.active); imgui.SameLine(); imgui.Text(u8' << Двигатель всегда включен')
                            imgui.ToggleButton('##anti_bike_fall', additionally_imgui_model.vehicle.anti_bike_fall.active); imgui.SameLine(); imgui.Text(u8' << AntiBikeFall')
                            imgui.BeginChild('Speedhack', imgui.ImVec2(220, 120), true)
                                imgui.ToggleButton('##Sh', additionally_imgui_model.vehicle.speedhack.active); imgui.SameLine(); imgui.Text(u8' << SpeedHack (Alt)')
                                if additionally_imgui_model.vehicle.speedhack.active.v then
                                    imgui.PushItemWidth(100)
                                    imgui.InputFloat(u8'<< Ускорение', additionally_imgui_model.vehicle.speedhack.smooth)
                                    imgui.PushItemWidth(100)
                                    imgui.InputFloat(u8'<< Максимальная скорость', additionally_imgui_model.vehicle.speedhack.max_speed)
                                end
                            imgui.EndChild()
                        end
                        if additionally_imgui_model.navigation.current == 2 then -- Actor
                            imgui.ToggleButton('##god_mode', additionally_imgui_model.player.god_mode.active); imgui.SameLine(); imgui.Text(u8' << GodMode (Insert)')
                        end
                        if additionally_imgui_model.navigation.current == 3 then -- Guns
                            imgui.ToggleButton('##god_mode', additionally_imgui_model.guns.aim.active); imgui.SameLine(); imgui.Text(u8' << AimBot')
                        end
                        if additionally_imgui_model.navigation.current == 4 then -- Visuals
                            imgui.ToggleButton('##aim_line', additionally_imgui_model.visual.aim_line.active); imgui.SameLine(); imgui.Text(u8' << Показывать куда целится игрок за которым вы следите')
                            imgui.ToggleButton('##tracers', additionally_imgui_model.visual.tracers.active); imgui.SameLine(); imgui.Text(u8' << Трасера пуль')
                            imgui.BeginChild('WallHack', imgui.ImVec2(200, 120), true)
                                imgui.ToggleButton('##Whtoggle', additionally_imgui_model.visual.wallhack.active); imgui.SameLine(); imgui.Text(u8' << WallHack')
                                if additionally_imgui_model.visual.wallhack.active.v then
                                    imgui.ToggleButton('##nametag', additionally_imgui_model.visual.wallhack.name_tag); imgui.SameLine(); imgui.Text(u8' << NameTag')
                                    imgui.ToggleButton('##bones', additionally_imgui_model.visual.wallhack.bones); imgui.SameLine(); imgui.Text(u8' << Bones')
                                end
                            imgui.EndChild()
                            imgui.BeginChild('InfoBar', imgui.ImVec2(150, 190), true)
                                imgui.ToggleButton('##InfoBar', additionally_imgui_model.visual.info_bar.active); imgui.SameLine(); imgui.Text(u8' << InfoBar')
                                if additionally_imgui_model.visual.info_bar.active.v then
                                    imgui.ToggleButton('##coords', additionally_imgui_model.visual.info_bar.coords); imgui.SameLine(); imgui.Text(u8' << Координаты')
                                    imgui.ToggleButton('##fps', additionally_imgui_model.visual.info_bar.fps); imgui.SameLine(); imgui.Text(u8' << FPS')
                                    imgui.ToggleButton('##ping', additionally_imgui_model.visual.info_bar.ping); imgui.SameLine(); imgui.Text(u8' << Ping')
                                    imgui.ToggleButton('##id', additionally_imgui_model.visual.info_bar.id); imgui.SameLine(); imgui.Text(u8' << ID')
                                    imgui.ToggleButton('##time', additionally_imgui_model.visual.info_bar.time); imgui.SameLine(); imgui.Text(u8' << Time')
                                end
                            imgui.EndChild()
                        end
                        if additionally_imgui_model.navigation.current == 5 then -- Other
                            imgui.ToggleButton('##click_warp', additionally_imgui_model.other.click_warp.active); imgui.SameLine(); imgui.Text(u8' << КликВарп (Как в собейте)')
                            imgui.ToggleButton('##fast_map', additionally_imgui_model.other.fast_map.active); imgui.SameLine(); imgui.Text(u8' << FastMap (M)')
                            imgui.ToggleButton('##hud_fix', additionally_imgui_model.other.hud_fix.active); imgui.SameLine(); imgui.Text(u8' << Показывать худ в TV')
                            imgui.BeginChild('AirBrake', imgui.ImVec2(200, 120), true) 
                                imgui.ToggleButton('##activeair', additionally_imgui_model.other.airbrake.active); imgui.SameLine(); imgui.Text(u8' << AirBrake (RShift)')
                                if additionally_imgui_model.other.airbrake.active.v then
                                    imgui.PushItemWidth(100)
                                    imgui.InputFloat(u8'<< Скорость', additionally_imgui_model.other.airbrake.speed)
                                end
                            imgui.EndChild()
                        end
                    imgui.EndChild()
                end

                if navigation.current == 8 then -- Settings
                    imgui.BeginChild('report_handler', imgui.ImVec2(380, 140), true) 
                        if imgui.ToggleButton('##reporthandler', settings_imgui_model.report_handler.active) then
                            settings.report_handler.active = settings_imgui_model.report_handler.active.v
                            saveSettings()
                        end
                        imgui.SameLine(); imgui.Text(u8' << Обработка репортов')
                        if settings_imgui_model.report_handler.active.v then
                            if imgui.ToggleButton('##fastactions', settings_imgui_model.report_handler.report_actions.active) then
                                settings.report_handler.report_actions.active = settings_imgui_model.report_handler.report_actions.active.v
                                saveSettings()
                            end
                            imgui.SameLine(); imgui.Text(u8' << Быстрые действия по репорту')
                            imgui.BeginChild('fastames', imgui.ImVec2(360, 80), true) 
                                if imgui.ToggleButton('##fastamesbtn', settings_imgui_model.report_handler.fast_ames.active) then
                                    settings.report_handler.fast_ames.active = settings_imgui_model.report_handler.fast_ames.active.v
                                    saveSettings()
                                end
                                imgui.SameLine(); imgui.Text(u8' << Быстрый ответ на репорт')
                                imgui.PushItemWidth(60)
                                if settings_imgui_model.report_handler.fast_ames.active.v then
                                    if imgui.InputText(u8' << Клавиша (Пример: 0x01)', settings_imgui_model.report_handler.fast_ames.key) then
                                        settings.report_handler.fast_ames.key = settings_imgui_model.report_handler.fast_ames.key.v
                                        saveSettings()
                                    end
                                end
                            imgui.EndChild()
                        end
                    imgui.EndChild()
                    imgui.BeginChild('cmd_helper', imgui.ImVec2(380, 190), true) 
                        if imgui.ToggleButton('##cmd_helper', settings_imgui_model.cmd_helper.active) then
                            settings.cmd_helper.active = settings_imgui_model.cmd_helper.active.v
                            saveSettings()
                        end
                        imgui.SameLine(); imgui.Text(u8' << Помощник ввода команд')
                        if settings_imgui_model.cmd_helper.active.v then
                            imgui.PushItemWidth(80)
                            if imgui.InputInt(u8' << Количество строк', settings_imgui_model.cmd_helper.lines) then
                                settings.cmd_helper.lines = settings_imgui_model.cmd_helper.lines.v
                                saveSettings()
                            end
                            imgui.PushItemWidth(80)
                            if imgui.InputInt(u8' << Опустить на px', settings_imgui_model.cmd_helper.y) then
                                settings.cmd_helper.y = settings_imgui_model.cmd_helper.y.v
                                saveSettings()
                            end
                            imgui.Text(u8'TAB - чтобы вставить команду')
                            imgui.Text(u8'Стрелочки - выбирать команду из списка')
                            imgui.Text(u8' ')
                            imgui.Text(u8'>>Если у вас MImGui Chat<<')
                            imgui.Text(u8'Помощник команд работает только при неактивном вводе.')
                            imgui.Text(u8'Просто нажмите в любое место экрана.')
                        end
                    imgui.EndChild()
                end

                if navigation.current == 9 then -- Credits
                    imgui.TextColoredRGB('Author: {676776}INVILSO{ffffff}', 1)
                    imgui.TextColoredRGB('Thanks:', 1)
                    imgui.TextColoredRGB('{676776}papercut{ffffff} - проверка на администратора', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/45009/{ffffff} - некоторые функции для Damage Informer', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13380/post-292514{ffffff} - цветной текст для ImGui', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13380/post-344806{ffffff} - фукция для рисования фигур', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/27544/{ffffff} - переключатель взят отсюда', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13380/page-20{ffffff} - верхнее меню imgui', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13380/page-15{ffffff} - получение ближайшего игрока к центру экрана', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13892/post-456277{ffffff} - перевод текста в нижний регистр', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/66295/{ffffff} - некоторые функции читов', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/93687/{ffffff} - патч худа в TV', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13305/{ffffff} - Moonloader', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/19292/{ffffff} - ImGui', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/14624/{ffffff} - SAMP.Lua', 1)
                    imgui.TextColoredRGB('{676776}https://blast.hk/moonloader/luajit/ext_ffi.html{ffffff} - FFI', 1)
                    imgui.TextColoredRGB('{676776}https://blast.hk/wiki/lua:memory{ffffff} - Memory', 1)
                    imgui.TextColoredRGB('{676776}https://github.com/BlastHackNet/mod_s0beit_sa-1{ffffff} - некоторые gta структуры', 1)
                    imgui.TextColoredRGB('{676776}https://github.com/BlastHackNet/SAMP-API/tree/multiver/src/sampapi{ffffff} - некоторые samp структуры', 1)
                    imgui.TextColoredRGB('{676776}https://www.blast.hk/threads/13892/post-136481{ffffff} - получение координат костей', 1)
                end
            imgui.EndChild() 
        imgui.End()
    end
end

function imgui_GenerateGUI(params)
    local generated = {}
    local params_model = {
        table = 'table', -- Сюда таблицу совать надо
        use_in_key = 'boolean', -- Тут ты говоришь юзать ли key родительского элемента (над потыкать)
        in_key = 'string', -- Задаешь вручную key родительского элемента (над потыкать)
        use_childs = 'boolean', -- Юзать ли imgui.Child
    }
    
    getChildY = function(table)
        local size = 0
        for key, value in pairs(table) do
            if type(value) == 'userdata' then
                size = size + 30
            else
                if type(value) == 'string' then
                    if not value:find('imgui%..+%(') then
                        size = size + 15
                        --imgui.Text(u8(value))
                    end
                end
            end
            if type(value) == 'table' then
                if key ~= 'handler' then
                    size = size + getChildY(value)
                end
            end
        end
        return size
    end
    local child_size = getChildY(params.table)
    local iin = function(list, what_find, mode)
        if what_find and type(what_find) ~= 'table' then
            local set = {}
            for _, l in ipairs(list) do set[l] = true end
            return set[what_find] and true or false
        elseif type(what_find) == 'table' then
            if not mode or mode == false then
                local set = {}
                for _, l in ipairs(list) do set[l] = true end
                for _, l in ipairs(what_find) do if set[l] then return true end end
            elseif mode == true then
                local set = {}
                local res = nil
                for _, l in ipairs(list) do set[l] = true end
                for k,v in pairs(what_find) do if set[v] then res = true else res = false end end
                return res
            end
        end
    end
    local get_handler = function(table, text, value)
        if table.handler then
            if #table.handler.use_for > 0 then
                if iin(table.handler.use_for, text) then
                    table.handler.func({name = text, value = value})
                end
            else
                table.handler.func({name = text, value = value})
            end
        end
    end
    if params.use_childs then
        if child_size > 30 then
            table.insert(generated, {gui = function() imgui.BeginChild(tostring(params.table), imgui.ImVec2(0, child_size), true) end, handler = false})
            --imgui.BeginChild(tostring(params.table), imgui.ImVec2(0, child_size), true)
        end
    end
    for key, value in pairs(params.table) do
        if type(value) == 'userdata' then
            local text = key
            if params.use_in_key and params.in_key ~= '' and child_size < 25 then
                text = params.in_key
            end
            if type(value.v) == 'boolean' then
                table.insert(generated, {gui = function() return imgui.Checkbox(u8(text), value) end, handler = function() get_handler(params.table, text, value) end})
            elseif type(value.v) == 'string' then
                table.insert(generated, {gui = function() return imgui.InputText(u8(text), value) end, handler = function() get_handler(params.table, text, value) end})
            elseif type(value.v) == 'number' then
                if tostring(value.v):find('%.') then
                    table.insert(generated, {gui = function() return imgui.InputFloat(u8(text), value) end, handler = function() get_handler(params.table, text, value) end})
                else
                    table.insert(generated, {gui = function() return imgui.InputInt(u8(text), value) end, handler = function() get_handler(params.table, text, value) end})
                end
            end
        else
            if type(value) == 'string' then
                if value:find('imgui%..+%(') then
                    table.insert(generated, {gui = load('return '..value), handler = false})
                else
                    table.insert(generated, {gui = function() imgui.Text(u8(value)) end, handler = false})
                end
            end
        end
        if type(value) == 'table' then
            if key ~= 'handler' then
                local tables = imgui_GenerateGUI({table = value, in_key = key, use_in_key = params.use_in_key, use_childs = params.use_childs})
                for k, gen in ipairs(tables) do
                    table.insert(generated, gen)
                end
            end
        end
    end
    if params.use_childs then
        if child_size > 30 then
            table.insert(generated, {gui = function() imgui.EndChild() end, handler = false})
            --imgui.EndChild()
        end
    end
    return generated
end

function imgui_getAllPlayers(list)
    local players = {}
    table.insert(players, 'All')
    for key, object in ipairs(list) do
        table.insert(players, object.origin_name)
    end
    return deleteDuplicates(players)
end

function updateFontDamageInformer()
    font_dmginformer = renderCreateFont(damage_informer.draw.font.name, damage_informer.draw.font.size, damage_informer.draw.font.style)
end

function imgui_filterFromName(list, player, to)
    local hits = {}
    for key, object in ipairs(list) do
        if player ~= 'All' then
            if to then
                if object.target_name == player then
                    table.insert(hits, object)
                end
            else
                if object.origin_name == player then
                    table.insert(hits, object)
                end
            end
        else
            table.insert(hits, object)
        end
    end
    return hits
end

function imgui_Paginate(list, max_in_page, min_in_page)
    local cashe = {}
    local out_list = {}
    if #list > 0 then
        for i = #list, 1, -1 do
            local item  = list[i]
            if #cashe <= max_in_page then
                if item ~= nil then
                    table.insert(cashe, item)
                end
            else
                table.insert(out_list, cashe)
                cashe = {}
            end
        end
    end
    if min_in_page > #cashe and min_in_page ~= 0 then
        if #out_list ~= 0 then
            for key, item in ipairs(cashe) do
                if item ~= nil then
                    table.insert(out_list[#out_list], item)
                end
            end
        else
            table.insert(out_list, cashe)
        end
        cashe = {}
    end
    
    if #cashe > 0 then
        table.insert(out_list, cashe)
        cashe = {}
    end
    return out_list
end

function imgui_getPagesName(list)
    local out = {}
    for key, _ in ipairs(list) do
        table.insert(out, u8(tostring(key)..' страница'))
    end
    return out
end

function onReceiveRpc(id, bs)
    if id == 93 then
        local color = raknetBitStreamReadInt32(bs)
        local len = raknetBitStreamReadInt32(bs)
        local text = raknetBitStreamReadString(bs, len)
        if text:find(regex) then
            local nickname, id, text = text:match(regex)
            if id ~= nil then
                reportHandler(id, nickname, text)
            end
        end
    end
end

function main()
    while not isSampAvailable() do wait(2000) end
    repeat wait(0) until sampIsLocalPlayerSpawned()
    if not sampTextdrawIsExists(36) then
        sampAddChatMessage("Не пройдена проверка на админа. Скрипт завершает работу.", 0xAAAAAA)
        thisScript():unload()
        return
    end
    if not doesDirectoryExist(getWorkingDirectory()..'\\config\\IAdminTools') then createDirectory(getWorkingDirectory()..'\\config\\IAdminTools') end
    loadAdminCommands()
    loadFastActions()
    loadDamageInformer()
    loadNotepad()
    loadAdditionally()
    updateFontDamageInformer()
    loadSettings()
    if additionally.other.hud_fix.active then
        mem.write(sampGetBase() + 643864, 37008, 2, true)
    end
    sampRegisterChatCommand('iat', function() window.v = not window.v end)
    sampRegisterChatCommand('iatc', function() 
        thisScript():unload()
    end)
    
    threads_descriptors = {
        target_menu = lua_thread.create_suspended(targetMenu),
        report_menu = lua_thread.create_suspended(reportMenu),
        spectate_info = lua_thread.create_suspended(spectateInfoCheck),
        damage_informer_pos = lua_thread.create_suspended(changePosDamageInformer),
        addit = lua_thread.create_suspended(AdditionallyClassThread),
    }
    threads_descriptors.report_menu:run()
    threads_descriptors.target_menu:run()
    threads_descriptors.spectate_info:run()
    threads_descriptors.damage_informer_pos:run()
    threads_descriptors.addit:run()
    sampAddChatMessage("> IAdminTools loaded.", 0xAAAAAA)
    script_loaded = true
    while true do
        wait(0)
        imgui.Process = window.v
        if isKeyJustPressed(tonumber(settings.report_handler.fast_ames.key)) then
            if settings.report_handler.fast_ames.active and settings.report_handler.active then
                if id_global ~= nil then
                    sampSetChatInputEnabled(true)
                    sampSetChatInputText("/ames "..id_global.." ")
                else
                    sampAddChatMessage("> Не было репортов.", 0xAAAAAA)
                end
            end
        end
    end
end

function changePosDamageInformer()
    while true do
        wait(0)
        if damage_informer_change_pos then
            if isKeyDown(keys_cursor[1]) and isKeyDown(keys_cursor[2]) then
                cursor_status = true
                sampSetCursorMode(2)
            elseif cursor_status == true then
                cursor_status = false
                sampSetCursorMode(0)
            end
            if isKeyJustPressed(0x01) then
                local sx, sy = getCursorPos()
                damage_informer.draw.positions.x = sx
                damage_informer.draw.positions.y = sy
                damage_informer_change_pos = false
                window.v = true
                sampSetCursorMode(0)
                saveDamageInformer()
                sampAddChatMessage('Позиция изменена', -1)
            end
            if isKeyJustPressed(0x02) then
                damage_informer_change_pos = false
                window.v = true
                sampSetCursorMode(0)
            end
        end
    end
end

function loadAdminCommands()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\database.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\database.json', 'w+')
	    configFile:write(encodeJson(admin_commands))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\database.json', 'r')
	admin_commands = decodeJson(configFile:read('*a'))
    configFile:close()
end

function loadFastActions()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\fast_actions.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\fast_actions.json', 'w+')
	    configFile:write(encodeJson(fast_actions))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\fast_actions.json', 'r')
	fast_actions = decodeJson(configFile:read('*a'))
    configFile:close()
end

function saveFastActions()
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\fast_actions.json', 'w+')
	configFile:write(encodeJson(fast_actions))
	configFile:close()
end

function loadDamageInformer()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\damage_informer.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\damage_informer.json', 'w+')
	    configFile:write(encodeJson(damage_informer))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\damage_informer.json', 'r')
	damage_informer = decodeJson(configFile:read('*a'))
    configFile:close()
end

function saveDamageInformer()
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\damage_informer.json', 'w+')
	configFile:write(encodeJson(damage_informer))
	configFile:close()
end

function loadNotepad()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\notepad.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\notepad.json', 'w+')
	    configFile:write(encodeJson(notepad))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\notepad.json', 'r')
	notepad = decodeJson(configFile:read('*a'))
    configFile:close()
end

function saveNotepad()
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\notepad.json', 'w+')
	configFile:write(encodeJson(notepad))
	configFile:close()
end

function loadAdditionally()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\additionally.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\additionally.json', 'w+')
	    configFile:write(encodeJson(additionally))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\additionally.json', 'r')
	additionally = decodeJson(configFile:read('*a'))
    configFile:close()
end

function saveAdditionally()
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\additionally.json', 'w+')
	configFile:write(encodeJson(additionally))
	configFile:close()
end

function loadSettings()
	if not doesFileExist(getWorkingDirectory()..'\\config\\IAdminTools\\settings.json') then
	    local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\settings.json', 'w+')
	    configFile:write(encodeJson(settings))
	    configFile:close()
	    return
	end
  
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\settings.json', 'r')
	settings = decodeJson(configFile:read('*a'))
    configFile:close()
end

function saveSettings()
	local configFile = io.open(getWorkingDirectory()..'\\config\\IAdminTools\\settings.json', 'w+')
	configFile:write(encodeJson(settings))
	configFile:close()
end

function targetMenu()
    while true do
        wait(0)
        if isKeyDown(target_menu_key) then
            if fast_actions.active and fast_actions.actions ~= nil then
                local ped = getNearCharToCenter(110)
                local sx, sy = getScreenResolution()
                renderFigure2D(sx/2, sy/2, 110, 110, 1.9, 0xFFDC143C) -- Фигура
                renderFigure2D(sx/2, sy/2, 15, 15, 1.5, 0xFFDC143C) -- Фигура
                if spectate_status and spectate_id ~= nil then
                    local text = "CURRENT: "..sampGetPlayerNickname(spectate_id).." [ID "..spectate_id.."] [LVL: "..sampGetPlayerScore(spectate_id).."]"
                    local currentPlayerColor = sampGetPlayerColor(spectate_id)
                    renderFontDrawText(font, text, sx/2 - string.len(text) * 3.5, sy/2 + 135, currentPlayerColor)
                    if true then -- действия по current игроку
                        if not ped or isKeyDown(0x01) then
                            renderFontDrawText(font, 'Current: ', (sx/2 + 200) - string.len('Current: ') * 3.5, sy/2, currentPlayerColor)
                            local i = 25
                            for key, action in ipairs(fast_actions.actions) do
                                if action.active then
                                    if action.category == 0 or action.category == 1 then
                                        renderFontDrawText(font, u8:decode(action.description), (sx/2 + 200) - string.len(u8:decode(action.description)) * 3.5, sy/2 + i, currentPlayerColor)
                                        i = i + 25
                                        if isKeyJustPressed(tonumber(u8:decode(action.keycode))) then
                                            local sid = spectate_id
                                            lua_thread.create(function ()
                                                for key2, command in ipairs(action.commands) do
                                                    local command = string.gsub(u8:decode(command), "{ID}", tostring(sid))
                                                    sampSendChat(command)
                                                    wait(action.commands_delay)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if ped then
                    local id = select(2, sampGetPlayerIdByCharHandle(ped))
                    if sampIsPlayerConnected(id) and not sampIsPlayerNpc(id) then
                        local playerPosX, playerPosY, playerPosZ = getCharCoordinates(ped)
                        local convertPlayerX, convertPlayerY = convert3DCoordsToScreen(playerPosX, playerPosY, playerPosZ)
                        local playerColor = sampGetPlayerColor(id)
                        renderDrawLine(sx/2, sy/2, convertPlayerX, convertPlayerY, 0.9, playerColor)  -- От центра екрана к игроку.
                        renderDrawPolygon(convertPlayerX, convertPlayerY, 6, 6, 20, 0.0, playerColor) -- На игроку конец линии (рисуем круг)    
                        renderFontDrawText(font, "NEW: "..sampGetPlayerNickname(id).." [ID "..id.."] [LVL: "..sampGetPlayerScore(id).."]", sx/2 - string.len("NEW: "..sampGetPlayerNickname(id).." [ID "..id.."] [LVL: "..sampGetPlayerScore(id).."]") * 3.5, sy/2 + 115, playerColor)
                        if not isKeyDown(0x01) then
                            local i = 25
                            for key, action in ipairs(fast_actions.actions) do
                                if action.active then
                                    if action.category == 0 or action.category == 2 then
                                        renderFontDrawText(font, u8:decode(action.description), (sx/2 - 200) - string.len(u8:decode(action.description)) * 3.5, sy/2 + i, playerColor)
                                        i = i + 25
                                        if isKeyJustPressed(tonumber(u8:decode(action.keycode))) then
                                            lua_thread.create(function ()
                                                for key2, command in ipairs(action.commands) do
                                                    local command = string.gsub(u8:decode(command), "{ID}", tostring(id))
                                                    sampSendChat(command)
                                                    wait(action.commands_delay)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                            renderFontDrawText(font, 'NEW: ', (sx/2 - 200) - string.len('NEW: ') * 3.5, sy/2, playerColor)
                        end
                    end
                end
            end
        end
    end
end

function reportHandler(id, nickname, text)
    if not report_status then
        if settings.report_handler.active then
            id_global = id
            local report_id = tonumber(text:match('%d+'))
            if settings.report_handler.report_actions.active then
                current_report_actions = {}
                if (rusLower(text):find(rusLower('помоги')) or rusLower(text):find(rusLower('застрял')) or rusLower(text):find(rusLower('help'))) then
                    table.insert(current_report_actions, {actions = report_all_actions.help, id = id, report_id = report_id})
                elseif (rusLower(text):find(rusLower('aim')) or rusLower(text):find(rusLower('аим')) or rusLower(text):find(rusLower('soft')) or rusLower(text):find(rusLower('сприд')) or rusLower(text):find(rusLower('spread'))) then
                    table.insert(current_report_actions, {actions = report_all_actions.aim, id = id, report_id = report_id})
                elseif (rusLower(text):find(rusLower('wh')) or rusLower(text):find(rusLower('вх')) or rusLower(text):find(rusLower('волхак'))) then
                    table.insert(current_report_actions, {actions = report_all_actions.wh, id = id, report_id = report_id})
                elseif (rusLower(text):find(rusLower('сх')) or rusLower(text):find(rusLower('спид')) or rusLower(text):find(rusLower('читер'))) then
                    table.insert(current_report_actions, {actions = report_all_actions.speed, id = id, report_id = report_id})
                elseif (rusLower(text):find(rusLower('dm')) or rusLower(text):find(rusLower('дм')) or rusLower(text):find(rusLower('kill')) or rusLower(text):find(rusLower('nrpkill'))) then
                    table.insert(current_report_actions, {actions = report_all_actions.dm, id = id, report_id = report_id})
                else 
                    table.insert(current_report_actions, {actions = report_all_actions.other, id = id, report_id = report_id})
                end
            end
        end
    end
end

function spectateInfoCheck()
    while true do
        wait(0)
        for i = 2010, 2100 do
            if sampTextdrawIsExists(i) then
                if sampTextdrawGetString(i):find('ID_~w~(%d+)_~r~') then
                    spectate_id = tonumber(sampTextdrawGetString(i):match('ID_~w~(%d+)_~r~'))
                    spectate_status = true
                    break
                else
                    spectate_status = false
                    spectate_id = nil
                end
            end
        end
    end
end

local cursor_status = false
function reportMenu()
    while true do
        wait(0)
        if #current_report_actions >= 1 then
            local sx, sy = getScreenResolution()
            if isKeyDown(keys_cursor[1]) and isKeyDown(keys_cursor[2]) then
                cursor_status = true
                sampSetCursorMode(2)
            elseif cursor_status == true then
                cursor_status = false
                sampSetCursorMode(0)
            end
            if not report_status then
                if drawButton('Взяться за репорт от ['..tostring(current_report_actions[1].id..']'), sx-10, sy/2, font, 10, 20) then
                    lua_thread.create(function()
                        wait(200)
                        report_status = true
                    end)
                end
                if drawButton('Завершить работу с репортом от ['..tostring(current_report_actions[1].id..']'), sx-10, sy/2+40, font, 10, 20) then
                    report_status = false
                    current_report_actions = {}
                    cursor_status = false
                    sampSetCursorMode(0)
                end
            end
            if report_status then
                local iter = 1
                for key, actions in pairs(current_report_actions[1].actions) do
                    key = string.gsub(key, "{id}", tostring(current_report_actions[1].id))
                    key = string.gsub(key, "{report%-id}", tostring(current_report_actions[1].report_id))
                    if drawButton(key, sx-10, sy/2+30+45*iter, font, 10, 20) then
                        for key2, mess in ipairs(actions) do
                            mess = string.gsub(mess, "{id}", tostring(current_report_actions[1].id))
                            mess = string.gsub(mess, "{report%-id}", tostring(current_report_actions[1].report_id))
                            sampSendChat(mess)
                        end
                    end
                    iter = iter + 1
                end
                if drawButton('Завершить работу с репортом от '..tostring(current_report_actions[1].id), sx-10, sy/2+20, font, 10, 20) then
                    lua_thread.create(function()
                        wait(100)
                        report_status = false
                        current_report_actions = {}
                        cursor_status = false
                        sampSetCursorMode(0)
                    end)
                end
            end       
        end
    end
end

function drawButton(text, x, y, font, circle, borts) -- функция для рендера кнопки / Параметры: v - текст, x,y - коорды кнопки
    local sx, sy = getScreenResolution()
    local cx, cy = getCursorPos() -- получаем коорды мышки
    local box_color
    local text_len = ((string.len(text) * 3.5) * 2 + 10)
    box_sizes = findBoxSize(text, font, borts)

    x = x - box_sizes.x - 20
    if cx > x and cx < x+box_sizes.x and cy > y and cy < y+box_sizes.y then -- Проверяем находится курсор мышки в прямоугольной области 150 на 30 кнопки
        box_color = 0xAA9696FF
    else
        box_color = 0xAA9696AB
    end
    renderDrawCircleBox(box_sizes.x, box_sizes.y, x, y, circle, box_color)
    renderFontDrawText(font, text, x+10, y+10, 0xFFFFFFFF) -- рендер текста с небольшим смещением по 5 пикселей.
    
    
    
    local res = false -- статус нажатия кнопки
    if cx > x and cx < x+box_sizes.x and cy > y and cy < y+box_sizes.y and isKeyJustPressed(0x01) then -- Проверяем находится курсор мышки в прямоугольной области 150 на 30 кнопки
        res = true -- если мышка в нужной области и нажата ЛКМ, передаём true переменной
    end
    return res -- возвращаемый статус нажатия
end

function findBoxSize(text, font, borts)
    local text_len = {} -- массив длины текста в пикселях
    local str_count = 0 --количество строк
    for line in text:gmatch("[^\r\n]+") do
        text_len[#text_len + 1] = renderGetFontDrawTextLength(font, line) -- считаем длину текста
        str_count = str_count + 1
    end
    local big_len = 0
    for key2, val2 in ipairs(text_len) do
        if big_len < val2 then
            big_len = val2
        end
    end
    local y_size = borts + str_count * renderGetFontDrawHeight(font) + 3 * (str_count - 1) -- 20 – высота "бортиков" (до текста + после текста), 3 – доп. высота (отступ между строками)
    local x_size = big_len + 20
    return {x = x_size, y = y_size}
end

function renderDrawCircleBox(sizex, sizey, posx, posy, radius, color)
	sizex = sizex - 2 * radius
	sizey = sizey - 2 * radius
	posx = posx + radius
	posy = posy + radius
	renderDrawBox(posx - radius, posy, radius, sizey, color)
	renderDrawBox(posx + sizex, posy, radius, sizey, color)
	renderDrawBox(posx, posy - radius, sizex, sizey + 2 * radius, color)
	for i = posx + sizex, posx + sizex + radius - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx + sizex)) * (i - (posx + sizex)))
		renderDrawBox(i, posy - dist, 1, dist, color)
	end
	for i = posx - radius, posx - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx - 1)) * (i - (posx - 1)))
		renderDrawBox(i, posy - dist, 1, dist, color)
	end
	for i = posx + sizex, posx + sizex + radius - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx + sizex)) * (i - (posx + sizex)))
		renderDrawBox(i, posy + sizey, 1, dist, color)
	end
	for i = posx - radius, posx - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx - 1)) * (i - (posx - 1)))
		renderDrawBox(i, posy + sizey, 1, dist, color)
	end
end

function getNearCharToCenter(radius)
    local arr = {}
    local sx, sy = getScreenResolution()
    for _, player in ipairs(getAllChars()) do
        if select(1, sampGetPlayerIdByCharHandle(player)) and isCharOnScreen(player) and player ~= playerPed then
            if select(2, sampGetPlayerIdByCharHandle(player)) ~= tonumber(spectate_id) then
                local plX, plY, plZ = getCharCoordinates(player)
                local cX, cY = convert3DCoordsToScreen(plX, plY, plZ)
                local distBetween2d = getDistanceBetweenCoords2d(sx / 2, sy / 2, cX, cY)
                if distBetween2d <= tonumber(radius and radius or sx) then
                    table.insert(arr, {distBetween2d, player})
                end
            end
        end
    end
    if #arr > 0 then
        table.sort(arr, function(a, b) return (a[1] < b[1]) end)
        return arr[1][2]
    end
    return nil
end

function renderFigure2D(x, y, points, radius, size, color) 
	local step = math.pi * 2 / points 
	local render_start, render_end = {}, {} 
	for i = 0, math.pi * 2, step do 
		render_start[1] = radius * math.cos(i) + x 
		render_start[2] = radius * math.sin(i) + y 
		render_end[1] = radius * math.cos(i + step) + x 
		render_end[2] = radius * math.sin(i + step) + y 
		renderDrawLine(render_start[1], render_start[2], render_end[1], render_end[2], size, color) 
	end 
end


local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}
function rusLower(s)
    local strlen = s:len()
    if strlen == 0 then
        return s
    end
    s = s:lower()
    local output = ""
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end

function mysplit(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function apply_custom_style_darkgreen()
    
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
end
apply_custom_style_darkgreen()

HeaderButton = function(bool, str_id)
    local DL = imgui.GetWindowDrawList()
    local ToU32 = imgui.ColorConvertFloat4ToU32
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

    if not AI_HEADERBUT then AI_HEADERBUT = {} end
     if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

    local degrade = function(before, after, start_time, duration)
        local result = before
        local timer = os.clock() - start_time
        if timer >= 0.00 then
            local offs = {
                x = after.x - before.x,
                y = after.y - before.y,
                z = after.z - before.z,
                w = after.w - before.w
            }

            result.x = result.x + ( (offs.x / duration) * timer )
            result.y = result.y + ( (offs.y / duration) * timer )
            result.z = result.z + ( (offs.z / duration) * timer )
            result.w = result.w + ( (offs.w / duration) * timer )
        end
        return result
    end

    local pushFloatTo = function(p1, p2, clock, duration)
        local result = p1
        local timer = os.clock() - clock
        if timer >= 0.00 then
            local offs = p2 - p1
            result = result + ((offs / duration) * timer)
        end
        return result
    end
    local set_alpha = function(color, alpha)
        return imgui.ImVec4(color.x, color.y, color.z, alpha or 1.00)
    end
    imgui.BeginGroup()
        local pos = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
      
        imgui.TextColored(pool.color, label)
        local s = imgui.GetItemRectSize()
        local hovered = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()
      
        if pool.h.state ~= hovered and not bool then
            pool.h.state = hovered
            pool.h.clock = os.clock()
        end
      
        if clicked then
            pool.clock = os.clock()
            result = true
        end
        if os.clock() - pool.clock <= duration[1] then
            pool.color = degrade(
                imgui.ImVec4(pool.color),
                bool and cols.slct or (hovered and cols.hovr or cols.idle),
                pool.clock,
                duration[1]
            )
        else
            pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
        end

        if pool.h.clock ~= nil then
            if os.clock() - pool.h.clock <= duration[2] then
                pool.h.alpha = pushFloatTo(
                    pool.h.alpha,
                    pool.h.state and 1.00 or 0.00,
                    pool.h.clock,
                    duration[2]
                )
            else
                pool.h.alpha = pool.h.state and 1.00 or 0.00
                if not pool.h.state then
                    pool.h.clock = nil
                end
            end

            local max = s.x / 2
            local Y = p.y + s.y + 3
            local mid = p.x + max
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        end
    imgui.EndGroup()
    return result
end

function imgui.TextColoredRGB(text) 
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local getcolor = function(color)
        if color:sub(1, 6):upper() == "SSSSSS" then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = 1.0
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == "string" and tonumber(color, 16) or color
        if type(color) ~= "number" then return end
        local r, g, b, a = explode_argb(color)
        return ImVec4(r/255, g/255, b/255, 1.0)
    end

    local render_text = function(text_)
        for w in text_:gmatch("[^\r\n]+") do
            local text, colors_, m = {}, {}, 1
            w = w:gsub("{(......)}", "{%1FF}")
            while w:find("{........}") do
                local n, k = w:find("{........}")
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function explode_argb(argb)
	local a = bit.band(bit.rshift(argb, 24), 0xFF)
	local r = bit.band(bit.rshift(argb, 16), 0xFF)
	local g = bit.band(bit.rshift(argb, 8), 0xFF)
	local b = bit.band(argb, 0xFF)
	return a, r, g, b
end

function imgui.ToggleButton(str_id, bool)
	local rBool = false

	if LastActiveTime == nil then
		LastActiveTime = {}
	end
	if LastActive == nil then
		LastActive = {}
	end

	local function ImSaturate(f)
		return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
	end
	
	local p = imgui.GetCursorScreenPos()
	local draw_list = imgui.GetWindowDrawList()

	local height = imgui.GetTextLineHeightWithSpacing()
	local width = height * 1.55
	local radius = height * 0.50
	local ANIM_SPEED = 0.17

	if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
		bool.v = not bool.v
		rBool = true
		LastActiveTime[tostring(str_id)] = os.clock()
		LastActive[tostring(str_id)] = true
	end

	local t = bool.v and 1.0 or 0.0

	if LastActive[tostring(str_id)] then
		local time = os.clock() - LastActiveTime[tostring(str_id)]
		if time <= ANIM_SPEED then
			local t_anim = ImSaturate(time / ANIM_SPEED)
			t = bool.v and t_anim or 1.0 - t_anim
		else
			LastActive[tostring(str_id)] = false
		end
	end

	local col_bg
	if bool.v then
		col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
	else
		col_bg = imgui.ImColor(100, 100, 100, 180):GetU32()
	end

	draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y + (height / 6)), imgui.ImVec2(p.x + width - 1.0, p.y + (height - (height / 6))), col_bg, 5.0)
	draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 0.75, imgui.GetColorU32(bool.v and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.ImColor(150, 150, 150, 255):GetVec4()))

	return rBool
end

function generateShotInfoText(hit, text)
    local pattern = text
    local time = hit.timestamp
    local warnings = ''
    for key, value in ipairs(hit.warnings) do
        warnings = warnings..value
    end
    pattern = string.gsub(pattern, '{H}', time.hour)
    pattern = string.gsub(pattern, '{M}', time.min)
    pattern = string.gsub(pattern, '{S}', time.sec)
    pattern = string.gsub(pattern, '{O%-NAME}', hit.origin_name)
    pattern = string.gsub(pattern, '{O%-ID}', hit.origin_id)
    pattern = string.gsub(pattern, '{WEAPON}', hit.weapon_name)
    pattern = string.gsub(pattern, '{WEAPON%-ID}', hit.weapon)
    pattern = string.gsub(pattern, '{DISTANCE}', hit.distance)
    pattern = string.gsub(pattern, '{LS}', hit.time_sinse)
    if hit.target_name then
        pattern = string.gsub(pattern, '{T%-NAME}', hit.target_name)
        pattern = string.gsub(pattern, '{T%-ID}', hit.target_id)
        if hit.bodypart then
            pattern = string.gsub(pattern, '{B%-NAME}', hit.bodypart.name)
            pattern = string.gsub(pattern, '{B%-ID}', hit.bodypart.id)
        else
            pattern = string.gsub(pattern, '{B%-NAME}', 'UNK')
            pattern = string.gsub(pattern, '{B%-ID}', 'UNK')
        end
        pattern = string.gsub(pattern, '{WARNINGS}', warnings)
        pattern = string.gsub(pattern, '{T%-SPEED}', hit.speeds.target)
        pattern = string.gsub(pattern, '{O%-SPEED}', hit.speeds.origin)
    end
    return pattern
end

function sampev.onSendBulletSync(data)
	handleBulletSync(select(2, sampGetPlayerIdByCharHandle(1)), data)
end

function sampev.onBulletSync(id, data)
	handleBulletSync(id, data)
end

local HitInfo = {
    id = 0,
    data = nil,

    __init__ = function(self, id, data)
        self.id = id
        self.data = data
    end,
    getDistance = function(self)
        return math.floor(math.sqrt((self.data.origin.x - self.data.target.x) ^ 2 + (self.data.origin.y - self.data.target.y) ^ 2 + (self.data.origin.z - self.data.target.z) ^ 2))
    end,
    getHitName = function(self)
        local hit_name = nil
        if self.data.targetType == 1 then hit_name = sampGetPlayerNickname(self.data.targetId) end
	    if self.data.targetType == 2 then hit_name = getVehicleModel(self.data.targetId) end
        return hit_name
    end,
    getSpeeds = function(self)
        local speeds = nil
        if self.data.targetType == 1 then speeds = {origin = getSpeed(self.id), target = getSpeed(self.data.targetId)} end
	    if self.data.targetType == 2 then speeds = {origin = getSpeed(self.id), target = getVehSpeed(self.data.targetId)} end
        return speeds
    end,
    getWarnings = function(self)
        local warnings = {}
        if self.data.targetType == 1 and not isLineOfSightClear(self.data.origin.x, self.data.origin.y, self.data.origin.z, self.data.target.x, self.data.target.y, self.data.target.z, true, false, false, true, true) then
            table.insert(warnings, 'txt fail')
        end
        if self.data.targetType == 1 and not isLineOfSightClear(self.data.origin.x, self.data.origin.y, self.data.origin.z, self.data.target.x, self.data.target.y, self.data.target.z, false, true, false, false, false) then
            table.insert(warnings, 'car fail')
        end
        return warnings
    end,
    getIntoMe = function(self)
        local result = nil
        if self.data.targetType == 1 and self.data.targetId == select(2, sampGetPlayerIdByCharHandle(1)) then
            result = true
        end
        return result
    end,
    getTime = function(self)
        return os.clock()
    end,
    getBodyPart = function(self)
        local bodypart = nil
        local max_dist = 5.0
        if self.data.targetType == 1 then
            local bodyparts = {
                [3] = 'torso',
                [4] = 'groin',
                [5] = 'l hand',
                [6] = 'r hand',
                [7] = 'l leg',
                [8] = 'r leg',
                [9] = 'head',
            }
            for part_id, part_name in pairs(bodyparts) do
                local res, handle = sampGetCharHandleBySampPlayerId(self.data.targetId)
                if res then
                    local bx, by, bz = getBodyPartCoordinates(part_id, handle)
                    local dist = getDistanceBetweenCoords3d(self.data.target.x, self.data.target.y, self.data.target.z, bx, by, bz)
                    if dist < max_dist then
                        max_dist = dist
                        bodypart = {id = part_id, name = part_name}
                    end
                end
            end
        end
        return bodypart
    end,
    getSeatStatus = function(self)
        local res, handle = sampGetCharHandleBySampPlayerId(self.id)
        local status = false
        if res then
            local pedptr = getCharPointer(handle)
            if mem.getint16(pedptr + 0x46F, false) == 132 then
                status = true
            end
        end
        return status
    end,
    getTimeSinse = function(self)
        local time_since = 1000
        if #hits > 0 then
            for i = #hits, 1, -1 do -- цикл от 10 до 1 с шагом -1
                if hits[i].origin_id == self.id then
                    time_since = os.clock() - hits[i].time
                    if time_since > 1 then time_since = 1000 else time_since = math.floor(1000 * time_since) end
                    break
                end
            end
        end
        return time_since
    end,
    getWeaponName = function(self)
        local weapons = {
            [22] = 'glock',
            [23] = 's glock',
            [24] = 'deagle',
            [25] = 'shotgun',
            [26] = 'sawn',
            [27] = 'spac12',
            [28] = 'uzi',
            [29] = 'mp5',
            [30] = 'ak47',
            [31] = 'm4',
            [32] = 'tec9',
            [33] = 'rifle',
            [34] = 'sniper',
            [38] = 'minigun'
        }
        return weapons[self.data.weaponId] or 'UNK ' .. tostring(self.data.weaponId)
    end
}

function handleBulletSync(id, data)
    HitInfo:__init__(id, data)
    local hit = {
        origin_id = HitInfo.id,
        target_id = HitInfo.data.targetId,
        origin_name = sampGetPlayerNickname(HitInfo.id),
        target_name = HitInfo:getHitName(),
        speeds = HitInfo:getSpeeds(),
        distance = HitInfo:getDistance(),
        warnings = HitInfo:getWarnings(),
        weapon = HitInfo.data.weaponId,
        coords = {
            origin = {
                x = data.origin.x,
                y = data.origin.y,
                z = data.origin.z,
            },
            target = {
                x = data.target.x,
                y = data.target.y,
                z = data.target.z,
            }
        },
        lose = false,
        seat_status = HitInfo:getSeatStatus(),
        weapon_name = HitInfo:getWeaponName(),
        bodypart = HitInfo:getBodyPart(),
        time_sinse = HitInfo:getTimeSinse(),
        to_me = HitInfo:getIntoMe(),
        time = HitInfo:getTime(),
        timestamp = os.date("*t"),
        handled = false
    }
    if hit.target_name then
        hit.lose = false
    else
        hit.lose = true
    end
    table.insert(hits, hit)
    if hit.target_name then
        if damage_informer.draw.active then
            if damage_informer.draw.spectate then
                if spectate_status then
                    if tonumber(hit.origin_id) == tonumber(spectate_id) or tonumber(hit.target_id) == tonumber(spectate_id) then
                        showNotification(generateShotInfoText(hit, damage_informer.pattern))
                    end
                end
            else
                showNotification(generateShotInfoText(hit, damage_informer.pattern))
            end
        end
    end
    if hit.bodypart then
        handleLastHits(hit.origin_name, hit.origin_id)
    end
end

function handleLastHits(player, origin_id)
    local all_fires = 0
    local all_hits = 0
    local all_hits_geted = 0
    local all_distance = 0
    local all_speeds = 0
    local all_time_sinse = 0
    local bodyparts = {
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
    }
    local guns = {
        [22] = 0,
        [23] = 0,
        [24] = 0,
        [25] = 0,
        [26] = 0,
        [27] = 0,
        [28] = 0,
        [29] = 0,
        [30] = 0,
        [31] = 0,
        [32] = 0,
        [34] = 0,
        [38] = 0
    }
    local local_hits = {}
    local players_sended = {}

    if #hits > 0 then
        for i = #hits, 1, -1 do -- цикл от 10 до 1 с шагом -1
            local hit  = hits[i]
            if hit.origin_name == player then
                if not hit.handled then
                    if (hit.time + 6) < os.clock() then
                        break
                    end
                    if hit.target_name then
                        if hit.bodypart then
                            if bodyparts[hit.bodypart.id] then
                                bodyparts[hit.bodypart.id] = bodyparts[hit.bodypart.id] + 1
                            else
                                bodyparts[hit.bodypart.id] = 1
                            end
                            if guns[hit.weapon] then
                                guns[hit.weapon] = guns[hit.weapon] + 1
                            else
                                guns[hit.weapon] = 1
                            end
                            all_distance = all_distance + hit.distance
                            all_speeds = all_speeds + hit.speeds.target
                            all_time_sinse = all_time_sinse + hit.time_sinse
                            all_hits = all_hits + 1
                        end
                    end
                    all_fires = all_fires + 1
                    --hits[i].handled = true
                    table.insert(local_hits, hit)
                end
            end
            if hit.target_name == player then
                if (hit.time + 6) < os.clock() then
                    break
                end
                if hit.weapon == 24 then
                    all_hits_geted = all_hits_geted + 1
                end
                table.insert(players_sended, hit.origin_name)
            end
        end
    end
    local average_distance = all_distance / all_hits
    local average_hits = all_hits / all_fires
    local average_speed = all_speeds / all_hits 
    local average_time_sinse = all_time_sinse / all_hits
    local prefered_bodypart = getPrefered(bodyparts)
    local percent_bodypart =  prefered_bodypart.count / all_hits 
    local prefered_gun = getPrefered(guns)
    local text_warnings = {}
    local warned = false

    if average_hits > 0.65 then
        if prefered_gun.item == 31 or prefered_gun.item == 30 then
            if all_hits > 8 then
                if average_distance > 45 then
                    if average_hits > 0.8 then
                        if average_time_sinse < 190 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (зажим) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                            if percent_bodypart > 0.70 then
                                table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (в одну кость) (BAN) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            end
                        end
                        if average_speed > 19 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (цель бежит/едет) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                        end
                    end
                end
                if average_distance > 65 then
                    if average_hits > 0.7 then
                        if average_time_sinse < 190 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (очень большое расстояние) (BAN)> '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                        end
                    end
                end
                if average_distance > 26 then
                    if all_hits > 15 then
                        if average_hits > 0.87 then
                            if average_time_sinse < 190 then
                                table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (зажимом) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                                warned = true
                            end
                        end
                    end
                end
                if average_distance < 100 then
                    if average_speed > 21 then
                        if all_hits > 10 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с M4/AK-47['..prefered_gun.item..'] (цель быстро пробежала/проехала) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                        end
                    end
                end
            end
        end
        if prefered_gun.item == 24 then
            if all_hits > 4 then
                if average_hits > 0.83 then
                    if average_time_sinse < 820 then
                        if average_speed > 2 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с Deagle['..prefered_gun.item..'] (зажимом) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                        end
                        if average_distance > 22 then
                            table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с Deagle['..prefered_gun.item..'] (большое расстояние) (BAN) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                            warned = true
                        end
                        if all_hits_geted > 2 then
                            if #deleteDuplicates(players_sended) == 1 then
                                table.insert(text_warnings, player..'['..origin_id..'] >  возможно Antistun > avrlh '..average_time_sinse..'ms > Get&SendHits: '..all_hits_geted..' $ '..all_hits..' > Get&SendGun: 24 & 24 > AvrD: '..average_distance..' > AvrB: '..prefered_bodypart.item)
                                warned = true
                            end
                        end
                    end
                end
            end
        end
        if prefered_gun.item == 33 or prefered_gun.item == 34 then
            if all_hits > 3 then
                if average_speed > 10 then
                    if average_time_sinse < 1100 then
                        table.insert(text_warnings, player..'['..origin_id..'] >  много попаданий с Rifle/Sniper['..prefered_gun.item..'] (цель бежит/едет) > '..all_hits..'/'..all_fires..' ('..math.floor((average_hits*100))..'%) > AvrS: '..math.floor(average_speed)..' > avrlh '..math.floor(average_time_sinse)..'ms > AvrD: '..math.floor(average_distance)..' AvrB: '..prefered_bodypart.item..' ('..math.floor((percent_bodypart*100))..'%)')
                        warned = true
                    end
                end
            end
        end
    end

    if warned then
        local warning = {
            origin_name = player,
            origin_id = origin_id,
            all_hits = all_hits,
            all_fires = all_fires,
            average_distance = average_distance,
            average_hits = average_hits,
            average_speed = average_speed,
            average_time_sinse = average_time_sinse,
            prefered_bodypart = prefered_bodypart,
            percent_bodypart = percent_bodypart,
            prefered_gun = prefered_gun,
            texts = text_warnings,
            log = local_hits,
            time = os.clock(),
            timestamp = os.date('*t')
        }
        local show = false
        if #warnings > 0 then
            if (warnings[#warnings].time + 6) > os.clock() then
                if warnings[#warnings].origin_name ~= player then
                    show = true
                end
            else
                show = true
            end
        else
            show = true
        end
        if show then
            for key, text in ipairs(text_warnings) do
                sampAddChatMessage(text, 0xAA3211)
            end
        end
        
        table.insert(warnings, warning)
    end
end

function deleteDuplicates(table)
    local hash = {}
    local res = {}

    for _,v in ipairs(table) do
        if (not hash[v]) then
            res[#res+1] = v -- you could print here instead of saving to result table if you wanted
            hash[v] = true
        end
    end
    return res
end

function getPrefered(table)
    local prefered = 0
    local prefered_max = 0
    for key, val in pairs(table) do
        if prefered_max < val then
            prefered = key
        end
    end
    return {item = prefered, count = prefered_max}
end

function getSpeed(id)
	if id == select(2, sampGetPlayerIdByCharHandle(1)) then return math.floor(getCharSpeed(1) * 3) end
	local res, ped = sampGetCharHandleBySampPlayerId(id)
	if not res then return 0 else
	return math.floor(getCharSpeed(ped) * 3) end
end

function getVehSpeed(id)
	local res, car = sampGetCarHandleBySampVehicleId(id)
	if not res then return 0 else
	return math.floor(getCarSpeed(car) * 3) end
end

function getVehicleModel(id)
	local res, car = sampGetCarHandleBySampVehicleId(id)
	if res then return getNameOfVehicleModel(getCarModel(car)) else return 'UNK ' .. tostring(id) end
end

function showNotification(text)
	table.insert(notify_data, {text = text, timeopen = os.clock(), timeclose = os.clock() + 4})
end



function DrawRender()
	local y_pos = damage_informer.draw.positions.y -- начальная вертикальная координата.
    while #notify_data > damage_informer.draw.count do
        table.remove(notify_data, 1)
    end
	for key, val in ipairs(notify_data) do
        local render = true
        if val.timeclose < os.clock() then
            render = false
            table.remove(notify_data, key)
            break
        end
        if render then
		    renderFontDrawText(font_dmginformer, val.text, damage_informer.draw.positions.x, y_pos, 0xFFFFFFFF)
            y_pos = y_pos + renderGetFontDrawHeight(font_dmginformer) + 3
        end
    end
end

function getBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

function getSeatStatus(handle)
    local status = false
    local pedptr = getCharPointer(handle)
    if mem.getint16(pedptr + 0x46F, false) == 132 then
        status = true
    end
    return status
end

local AimPosition = {
    weapons_angles = {[23]={-0.0415, 0.105}, [24]={-0.0415, 0.105}, [25]={-0.0415, 0.105}, [27]={-0.0415, 0.105}, [29]={-0.0415, 0.105}, [30]={-0.028, 0.07}, [31]={-0.028, 0.07}, [34]={0, 0}},
    player_cam_data = {},
    players_sync_data = {},
    line_thick = 2,
    draw = function (self)
        for playernicknameInTable, playerInfoInTable in pairs(self.player_cam_data) do --берем данные из таблицы playersCamData
            if sampIsPlayerConnected(playerInfoInTable.playerId) then
                local result, cped = sampGetCharHandleBySampPlayerId(playerInfoInTable.playerId)
                if result then
                    if doesCharExist(cped) then
                        if self.players_sync_data[playernicknameInTable] ~= nil then --Проверяем есть ли игрок из таблицы playersCamData в таблице playersSyncData
                            currentPlayerWeaponIdSync = self.players_sync_data[playernicknameInTable]['weaponID'] --берем оружие которое в руках у игрока из таблицы playersSyncData
                            if self.weapons_angles[currentPlayerWeaponIdSync] ~= nil then --проверяем указаны ли углы смещения для данного оружия
                                if playerInfoInTable.camModeP ~= 4 then							
                                    local playerAngleXY = self.angleBetween({playerInfoInTable.camFx, playerInfoInTable.camFy},{0,-1})
                                    local playerAngleZ = 1.5708 - math.acos(playerInfoInTable.camFz)
                                    
                                    local newXdraw = playerInfoInTable.camPx - 300*math.sin(1.5708+playerAngleZ+self.weapons_angles[currentPlayerWeaponIdSync][2])*math.cos(playerAngleXY+self.weapons_angles[currentPlayerWeaponIdSync][1])
                                    local newYdraw = playerInfoInTable.camPy - 300*math.sin(1.5708+playerAngleZ+self.weapons_angles[currentPlayerWeaponIdSync][2])*math.sin(playerAngleXY+self.weapons_angles[currentPlayerWeaponIdSync][1])
                                    local newZdraw = playerInfoInTable.camPz - 300*math.cos(1.5708+playerAngleZ +self.weapons_angles[currentPlayerWeaponIdSync][2])
                                    
                                    if currentPlayerWeaponIdSync == 34 then
                                        predictLocWeaponOffset = 1.5
                                    else
                                        predictLocWeaponOffset = 3
                                    end
                                        local predictLocXdraw = playerInfoInTable.camPx - predictLocWeaponOffset*math.sin(1.5708+playerAngleZ+self.weapons_angles[currentPlayerWeaponIdSync][2])*math.cos(playerAngleXY+self.weapons_angles[currentPlayerWeaponIdSync][1])
                                        local predictLocYdraw = playerInfoInTable.camPy - predictLocWeaponOffset*math.sin(1.5708+playerAngleZ+self.weapons_angles[currentPlayerWeaponIdSync][2])*math.sin(playerAngleXY+self.weapons_angles[currentPlayerWeaponIdSync][1])
                                        local predictLocZdraw = playerInfoInTable.camPz - predictLocWeaponOffset*math.cos(1.5708+playerAngleZ +self.weapons_angles[currentPlayerWeaponIdSync][2])
                                        local resultpsos, colPoint = processLineOfSight(predictLocXdraw, predictLocYdraw, predictLocZdraw, newXdraw, newYdraw, newZdraw, true, true, true, true, true, true, true, true)
                                        
                                        local color = sampGetPlayerColor(playerInfoInTable.playerId)
                                    if resultpsos == true then
                                        local pred1x, pred1y = self.calcScreenCoors(predictLocXdraw, predictLocYdraw, predictLocZdraw)
                                        local pred2x, pred2y = self.calcScreenCoors(colPoint.pos[1], colPoint.pos[2], colPoint.pos[3])
                                        if pred1x ~= -1 and pred1y ~= -1 and pred2x ~= -1 and pred2y ~= -1 then
                                            --renderDrawLine(pred1x, pred1y+self.line_thick, pred2x, pred2y+self.line_thick, self.line_thick, 0xFFAA17C4)--0xFFAA17C4
                                            renderDrawPolygon(pred2x, pred2y, self.line_thick+2, self.line_thick+2, 12, 1.0, 0xFFAA17C4)
                                            --renderDrawLine(pred1x, pred1y+LineThick, pred2x, pred2y+LineThick, LineThick, color)--0xFFAA17C4
                                            --renderDrawPolygon(pred2x, pred2y, LineThick+2, LineThick+2, 12, 0.0, color)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        self.player_cam_data[playernicknameInTable] = nil
                        self.players_sync_data[playernicknameInTable] = nil
                    end
                else
                    self.player_cam_data[playernicknameInTable] = nil
                    self.players_sync_data[playernicknameInTable] = nil	
                end
            else
                self.player_cam_data[playernicknameInTable] = nil
                self.players_sync_data[playernicknameInTable] = nil
            end
        end
    end,
    angleBetween = function(vector1, vector2)

        ssin = vector1[1] * vector2[2] - vector2[1] * vector1[2]
        ccos = vector1[1] * vector2[1] + vector1[2] * vector2[2]
        -- result in degree return atan2(ccos, ssin) * (180 / 3.141592653589793)
        return math.atan2(ccos, ssin)
    end,
    calcScreenCoors = function (fX,fY,fZ)
        local dwM = 0xB6FA2C
        local m_11 = mem.getfloat(dwM + 0*4)
        local m_12 = mem.getfloat(dwM + 1*4)
        local m_13 = mem.getfloat(dwM + 2*4)
        local m_21 = mem.getfloat(dwM + 4*4)
        local m_22 = mem.getfloat(dwM + 5*4)
        local m_23 = mem.getfloat(dwM + 6*4)
        local m_31 = mem.getfloat(dwM + 8*4)
        local m_32 = mem.getfloat(dwM + 9*4)
        local m_33 = mem.getfloat(dwM + 10*4)
        local m_41 = mem.getfloat(dwM + 12*4)
        local m_42 = mem.getfloat(dwM + 13*4)
        local m_43 = mem.getfloat(dwM + 14*4)	
        local dwLenX = mem.read(0xC17044, 4)
        local dwLenY = mem.read(0xC17048, 4)
        frX = fZ * m_31 + fY * m_21 + fX * m_11 + m_41
        frY = fZ * m_32 + fY * m_22 + fX * m_12 + m_42
        frZ = fZ * m_33 + fY * m_23 + fX * m_13 + m_43
        fRecip = 1.0/frZ
        frX = frX * (fRecip * dwLenX)
        frY = frY * (fRecip * dwLenY)
        if(frX<=dwLenX and frY<=dwLenY and frZ>1)then
            return frX, frY, frZ
        else
            return -1, -1, -1
        end
    end,
}

function sampev.onPlayerSync(playerId, data)
	local currentPlayerWeaponIdSync = data.weapon
	local currentPlayerIdSync = playerId
	local playernickname = sampGetPlayerNickname(currentPlayerIdSync)
	local player_color = sampGetPlayerColor(currentPlayerIdSync)
	AimPosition.players_sync_data[playernickname] = {['playerId']=currentPlayerIdSync, ['weaponID']=currentPlayerWeaponIdSync}
end

function sampev.onAimSync(playerId, data)
	local camFx = data.camFront.x
	local camFy = data.camFront.y
	local camFz = data.camFront.z

	local camPx = data.camPos.x
	local camPy = data.camPos.y
	local camPz = data.camPos.z
	local camPlayerId = playerId
	local playernickname = sampGetPlayerNickname(camPlayerId)
	local camModeP = data.camMode --4 если не целится с оружия
	AimPosition.player_cam_data[playernickname] = {['camFx'] = camFx, ['camFy'] = camFy, ['camFz'] = camFz, ['camPx'] = camPx, ['camPy'] = camPy, ['camPz'] = camPz, ['camModeP']=camModeP, ['playerId']=camPlayerId}
end

teleportPlayer = function(x, y, z)
    if isCharInAnyCar(PLAYER_PED) then setCharCoordinates(PLAYER_PED, x, y, z) end
    setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
end
setCharCoordinatesDontResetAnim = function(char, x, y, z)
    local ptr = getCharPointer(char) 
    setEntityCoordinates(ptr, x, y, z)
end
setEntityCoordinates = function(entityPtr, x, y, z)
    if entityPtr ~= 0 then
        local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
        if matrixPtr ~= 0 then
        local posPtr = matrixPtr + 0x30
        writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
        writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
        writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
        end
    end
end
jumpIntoCar = function(car)
    local seat = getCarFreeSeat(car)
    if not seat then return false end
    if seat == 0 then warpCharIntoCar(PLAYER_PED, car)
    else warpCharIntoCarAsPassenger(PLAYER_PED, car, seat - 1)
    end restoreCameraJumpcut() return true
end
getCarFreeSeat = function(car)
    if doesCharExist(getDriverOfCar(car)) then
        local maxPassengers = getMaximumNumberOfPassengers(car)
        for i = 0, maxPassengers do
        if isCarPassengerSeatFree(car, i) then return i + 1 end
        end return nil
    else return 0 end
end
rotateCarAroundUpAxis = function(car, vec)
    local mat = Matrix3X3(getVehicleRotationMatrix(car))
    local rotAxis = Vector3D(mat.up:get())
    vec:normalize()
    rotAxis:normalize()
    local theta = math.acos(rotAxis:dotProduct(vec))
    if theta ~= 0 then
        rotAxis:crossProduct(vec)
        rotAxis:normalize()
        rotAxis:zeroNearZero()
        mat = mat:rotate(rotAxis, -theta)
    end
    setVehicleRotationMatrix(car, mat:get())
end
readFloatArray = function(ptr, idx)
    return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
end
writeFloatArray = function(ptr, idx, value)
    writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
end
getVehicleRotationMatrix = function(car)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
        local rx, ry, rz, fx, fy, fz, ux, uy, uz
        rx = readFloatArray(mat, 0)
        ry = readFloatArray(mat, 1)
        rz = readFloatArray(mat, 2)
        fx = readFloatArray(mat, 4)
        fy = readFloatArray(mat, 5)
        fz = readFloatArray(mat, 6)
        ux = readFloatArray(mat, 8)
        uy = readFloatArray(mat, 9)
        uz = readFloatArray(mat, 10)
        return rx, ry, rz, fx, fy, fz, ux, uy, uz
        end
    end
end
setVehicleRotationMatrix = function (car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
        writeFloatArray(mat, 0, rx)
        writeFloatArray(mat, 1, ry)
        writeFloatArray(mat, 2, rz)
        writeFloatArray(mat, 4, fx)
        writeFloatArray(mat, 5, fy)
        writeFloatArray(mat, 6, fz)
        writeFloatArray(mat, 8, ux)
        writeFloatArray(mat, 9, uy)
        writeFloatArray(mat, 10, uz)
        end
    end
end

local AdditionallyClass = {
    airBrakeCoords = {},
    name_tag_status = false,
    click_warp_status = false,
    clickfont = renderCreateFont("Tahoma", 10, 0),
    ifont = renderCreateFont("Verdana", 8, 2),
    whfont = renderCreateFont('Segoe UI', 7, 13),
    global = function(self)
        while true do
            wait(0)
            if additionally.player.god_mode.active then
                if isKeyJustPressed(0x2D) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    additionally.player.god_mode.on = not additionally.player.god_mode.on
                    saveAdditionally()
                end
                if additionally.player.god_mode.on then
                    setCharProofs(PLAYER_PED, true, true, true, true, true)
                end
            end
            if isPlayerPlaying(PLAYER_HANDLE) and not isPauseMenuActive() and not sampIsChatInputActive() and not sampIsDialogActive() then
                if additionally.other.fast_map.active then -- qmap FYP
                    local menuPtr = 0x00BA6748
                    if isKeyDown(0x4D) then
                        writeMemory(menuPtr + 0x33, 1, 1, false)
                        writeMemory(menuPtr + 0x15C, 1, 1, false)
                        writeMemory(menuPtr + 0x15D, 1, 5, false)
                        while isKeyDown(0x4D) do
                            wait(80)
                        end
                        writeMemory(menuPtr + 0x32, 1, 1, false)
                    end
                end
            end
            if isCharInAnyCar(PLAYER_PED) and not isPlayerDead(PLAYER_PED) then
                local veh = storeCarCharIsInNoSave(PLAYER_PED)
                if isKeyJustPressed(0x2E) and additionally.vehicle.flip_on_wheels.active and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    local oX, oY, oZ = getOffsetFromCarInWorldCoords(veh, 0.0,  0.0,  0.0)
                    setCarCoordinates(veh, oX, oY, oZ)
                end
                if additionally.vehicle.anti_boom.active then
                    if isCarUpsidedown(veh) then
                        setCarHealth(veh, 1000)
                    end
                end
                setCharCanBeKnockedOffBike(PLAYER_PED, additionally.vehicle.anti_bike_fall.active and true or false)
                if additionally.vehicle.god_mode.active then
                    if isKeyJustPressed(0x24) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                        additionally.vehicle.god_mode.on = not additionally.vehicle.god_mode.on
                        saveAdditionally()
                    end
                    if additionally.vehicle.god_mode.on then
                        setCarProofs(veh, true, true, true, true, true)
                    end
                end
                if additionally.vehicle.engine.active then
                    switchCarEngine(veh, true)
                end
                if additionally.vehicle.speedhack.active then
                    if isKeyDown(0xA4) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                        if getCarSpeed(veh) * 1.78 <= additionally.vehicle.speedhack.max_speed then
                            local cVecX, cVecY, cVecZ = getCarSpeedVector(veh)
                            local heading = getCarHeading(veh)
                            local turbo = self.fpsCorrection() / additionally.vehicle.speedhack.smooth
                            local xforce, yforce, zforce = turbo, turbo, turbo
                            local Sin, Cos = math.sin(-math.rad(heading)), math.cos(-math.rad(heading))
                            if cVecX > -0.01 and cVecX < 0.01 then xforce = 0.0 end
                            if cVecY > -0.01 and cVecY < 0.01 then yforce = 0.0 end
                            if cVecZ < 0 then zforce = -zforce end
                            if cVecZ > -2 and cVecZ < 15 then zforce = 0.0 end
                            if Sin > 0 and cVecX < 0 then xforce = -xforce end
                            if Sin < 0 and cVecX > 0 then xforce = -xforce end
                            if Cos > 0 and cVecY < 0 then yforce = -yforce end
                            if Cos < 0 and cVecY > 0 then yforce = -yforce end
                            applyForceToCar(veh, xforce * Sin, yforce * Cos, zforce / 2, 0.0, 0.0, 0.0)
                        end
                    end
                end
            end
            if additionally.guns.aim.active and isKeyDown(1) then
                local _, ped = storeClosestEntities(1)
                if ped ~= -1 then
                    local x, y, z = getCharCoordinates(ped)
                    self.targetAtCoords(x, y, z+0.5)
                end
            end
            if additionally.other.airbrake.active then
                if isKeyJustPressed(0xA1) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    additionally.other.airbrake.on = not additionally.other.airbrake.on
                    if additionally.other.airbrake.on then
                        local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                        self.airBrakeCoords = {posX, posY, posZ, 0.0, 0.0, getCharHeading(PLAYER_PED)}
                    end
                end
                if additionally.other.airbrake.on then
                    if isCharInAnyCar(PLAYER_PED) then 
                        heading = getCarHeading(storeCarCharIsInNoSave(PLAYER_PED))
                    else 
                        heading = getCharHeading(PLAYER_PED) 
                    end
                    local camCoordX, camCoordY, camCoordZ = getActiveCameraCoordinates()
                    local targetCamX, targetCamY, targetCamZ = getActiveCameraPointAt()
                    local angle = getHeadingFromVector2d(targetCamX - camCoordX, targetCamY - camCoordY)
                    local difference = isCharInAnyCar(PLAYER_PED) and 0.79 or 1.0
                    local checkOth = (not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive())
                    if #self.airBrakeCoords ~= 0 then
                        if isKeyDown(0x57) then
                            if checkOth then
                                self.airBrakeCoords[1] = self.airBrakeCoords[1] + additionally.other.airbrake.speed * math.sin(-math.rad(angle))
                                self.airBrakeCoords[2] = self.airBrakeCoords[2] + additionally.other.airbrake.speed * math.cos(-math.rad(angle))
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                                if not isCharInAnyCar(PLAYER_PED) then setCharHeading(PLAYER_PED, angle)
                                else setCarHeading(storeCarCharIsInNoSave(PLAYER_PED), angle) end
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        elseif isKeyDown(0x53) then
                            if checkOth then
                                self.airBrakeCoords[1] = self.airBrakeCoords[1] - additionally.other.airbrake.speed * math.sin(-math.rad(heading))
                                self.airBrakeCoords[2] = self.airBrakeCoords[2] - additionally.other.airbrake.speed * math.cos(-math.rad(heading))
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        end
                        if isKeyDown(0x41) then
                            if checkOth then
                                self.airBrakeCoords[1] = self.airBrakeCoords[1] - additionally.other.airbrake.speed * math.sin(-math.rad(heading - 90))
                                self.airBrakeCoords[2] = self.airBrakeCoords[2] - additionally.other.airbrake.speed * math.cos(-math.rad(heading - 90))
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        elseif isKeyDown(0x44) then
                            if checkOth then
                                self.airBrakeCoords[1] = self.airBrakeCoords[1] - additionally.other.airbrake.speed * math.sin(-math.rad(heading + 90))
                                self.airBrakeCoords[2] = self.airBrakeCoords[2] - additionally.other.airbrake.speed * math.cos(-math.rad(heading + 90))
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        end

                        if isKeyDown(0x26) then
                            if checkOth then
                                self.airBrakeCoords[3] = self.airBrakeCoords[3] + additionally.other.airbrake.speed  / 2.0
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        end

                        if isKeyDown(0x28) and self.airBrakeCoords[3] > -95.0 then
                            if checkOth then
                                self.airBrakeCoords[3] = self.airBrakeCoords[3] - additionally.other.airbrake.speed  / 2.0
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - difference)
                            else setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0) end
                        end

                        if not isKeyDown(0x57) and not isKeyDown(0x53) and not isKeyDown(0x41) and not isKeyDown(0x44) and not isKeyDown(0x26) and not isKeyDown(0x28) then
                            if self.airBrakeCoords[3] ~= nil then
                                setCharCoordinates(PLAYER_PED, self.airBrakeCoords[1], self.airBrakeCoords[2], self.airBrakeCoords[3] - 1.0)
                            end
                        end
                    end
                end
            end
            if additionally.other.click_warp.active then
                if isKeyJustPressed(0x04) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    self.click_warp_status = not self.click_warp_status
                    sampSetCursorMode(self.click_warp_status and 2 or 0)
                end
                if self.click_warp_status then
                    if sampGetCursorMode() == 0 then sampSetCursorMode(2) end
                    local sx, sy = getCursorPos()
                    local sw, sh = getScreenResolution()
                    if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                        local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                        local camX, camY, camZ = getActiveCameraCoordinates()
                        local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
                        if result and colpoint.entity ~= 0 then
                            local normal = colpoint.normal
                            local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
                            local zOffset = 300
                            if normal[3] >= 0.5 then zOffset = 1 end
                            local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3,
                                true, true, false, true, false, false, false)
                            if result then
                                pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)
                                local curX, curY, curZ = getCharCoordinates(PLAYER_PED)
                                local dist = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
                                local hoffs = renderGetFontDrawHeight(self.clickfont)
                                sy = sy - 2
                                sx = sx - 2
                                renderFontDrawText(self.clickfont, string.format('Дистанция: %0.2f', dist), sx - (renderGetFontDrawTextLength(self.clickfont, string.format('Дистанция: %0.2f', dist)) / 2) + 6, sy - hoffs, 0xFFFFFFFF)
                                local tpIntoCar = nil
                                if colpoint.entityType == 2 then
                                    local car = getVehiclePointerHandle(colpoint.entity)
                                    if doesVehicleExist(car) and (not isCharInAnyCar(PLAYER_PED) or storeCarCharIsInNoSave(PLAYER_PED) ~= car) then
                                        if isKeyJustPressed(0x01) and isKeyJustPressed(0x02) then tpIntoCar = car end
                                        renderFontDrawText(self.clickfont, '{0984d2}Зажмите ПКМ чтобы {FFFFFF}сесть в транспорт', sx - (renderGetFontDrawTextLength(self.clickfont, '{0984d2}Зажмите ПКМ чтобы {FFFFFF}сесть в транспорт') / 2) + 6, sy - hoffs * 2, -1)
                                    end
                                end
                                if isKeyJustPressed(0x01) then
                                    if tpIntoCar then
                                        if not jumpIntoCar(tpIntoCar) then
                                            teleportPlayer(pos.x, pos.y, pos.z)
                                        end
                                    else
                                        if isCharInAnyCar(PLAYER_PED) then
                                            local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
                                            local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
                                            rotateCarAroundUpAxis(storeCarCharIsInNoSave(PLAYER_PED), norm2)
                                            pos = pos - norm * 1.8
                                            pos.z = pos.z - 1.1
                                        end
                                        teleportPlayer(pos.x, pos.y, pos.z)
                                    end
                                    sampSetCursorMode(0)
                                    self.click_warp_status = false
                                end
                            end
                        end
                    end
                end
            end
            
        end
    end,
    visual = function(self)
        if additionally.visual.tracers.active then
            if #hits > 0 then
                for i = #hits, 1, -1 do -- цикл от 10 до 1 с шагом -1
                    local hit = hits[i]
                    if (hit.time + 6) < os.clock() then
                        break
                    end
                    if isPointOnScreen(hit.coords.origin.x, hit.coords.origin.y, hit.coords.origin.z) and isPointOnScreen(hit.coords.target.x, hit.coords.target.y, hit.coords.target.z) then
						local sx, sy = convert3DCoordsToScreen(hit.coords.origin.x, hit.coords.origin.y, hit.coords.origin.z)
						local fx, fy = convert3DCoordsToScreen(hit.coords.target.x, hit.coords.target.y, hit.coords.target.z)
						renderDrawLine(sx, sy, fx, fy, 1, hit.lose and 0xFFFFFFFF or 0xFFFFC700)
						renderDrawPolygon(fx, fy-1, 3, 3, 4.0, 10, hit.lose and 0xFFFFFFFF or 0xFFFFC700)
					end
                end
            end
        end
        if additionally.visual.wallhack.active then
            if additionally.visual.wallhack.bones then
                for i = 0, sampGetMaxPlayerId() do
                    if sampIsPlayerConnected(i) then
                        local result, cped = sampGetCharHandleBySampPlayerId(i)
                        if result then
                            local color = sampGetPlayerColor(i)
                            local aa, rr, gg, bb = explode_argb(color)
                            local color = self.joinARGB(255, rr, gg, bb)
                            if doesCharExist(cped) and isCharOnScreen(cped) then
                                local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
                                for v = 1, #t do
                                    pos1X, pos1Y, pos1Z = getBodyPartCoordinates(t[v], cped)
                                    pos2X, pos2Y, pos2Z = getBodyPartCoordinates(t[v] + 1, cped)
                                    pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                                    pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                                    renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
                                end
                                for v = 4, 5 do
                                    pos2X, pos2Y, pos2Z = getBodyPartCoordinates(v * 10 + 1, cped)
                                    pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                                    renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
                                end
                                local t = {53, 43, 24, 34, 6}
                                for v = 1, #t do
                                    posX, posY, posZ = getBodyPartCoordinates(t[v], cped)
                                    pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
                                end
                                local X1, Y1, Z1 = getCharCoordinates(cped)
                                local X2, Y2, Z2 = getCharCoordinates(playerPed)
                                local dist1 = 0
                                if spectate_status then
                                    dist1 = math.ceil(math.sqrt( ((X1-X2)^2) + ((Y1-Y2)^2) + ((Z1-Z2)^2))) - 19
                                else
                                    dist1 = math.ceil(math.sqrt( ((X1-X2)^2) + ((Y1-Y2)^2) + ((Z1-Z2)^2)))
                                end
                                local X, Y = convert3DCoordsToScreen(X1, Y1, Z1)
                                local X2, Y2 = convert3DCoordsToScreen(X2, Y2, Z2)
                                renderFontDrawText(self.whfont, dist1.." m", X, Y+10, color)
                                if not spectate_status then
                                    renderDrawLine(X, Y, X2, Y2, 1, color)
                                end
                            end
                        end
                    end
                end
            end
            if additionally.visual.wallhack.name_tag then
                self.nameTagOn()
            end
            if not additionally.visual.wallhack.name_tag then
                self.nameTagOff()
            end
		end
        if additionally.visual.info_bar.active then
            local posX, posY = getScreenResolution()
			local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
            local tCoords, tFps, ping, aid =  string.format('[X: {F9D82F}%.1f {888EA0}Y: {F9D82F}%.1f {888EA0}Z: {F9D82F}%.1f{888EA0}]' or '', playerX, playerY, playerZ), string.format('[FPS: {F9D82F}%d{888EA0}]', mem.getfloat(0xB7CB50, 4, false)), string.format('[Ping: {F9D82F}%d{888EA0}]', sampGetPlayerPing(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))), string.format('[ID: {F9D82F}%d{888EA0}]', select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
            local text_cheats = ''
            if additionally.other.airbrake.active then
                local cheat_text = 'AirBrake'
                if additionally.other.airbrake.on then
                    cheat_text = '{29C730}AirBrake'
                end
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            if additionally.visual.wallhack.active then
                local cheat_text = 'WallHack'
                if additionally.visual.wallhack.name_tag or additionally.visual.wallhack.bones then
                    cheat_text = '{29C730}WallHack'
                end
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            if additionally.player.god_mode.active then
                local cheat_text = 'GM'
                if additionally.player.god_mode.on then
                    cheat_text = '{29C730}GM'
                end
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            if additionally.vehicle.god_mode.active then
                local cheat_text = 'VehGM'
                if additionally.vehicle.god_mode.on then
                    cheat_text = '{29C730}VehGM'
                end
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            if additionally.vehicle.engine.active then
                local cheat_text = '{29C730}Engine'
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            if additionally.guns.aim.active then
                local cheat_text = '{29C730}AimBot'
                text_cheats = text_cheats..'['..cheat_text..'{888EA0}]'
            end
            local tOther = (additionally.visual.info_bar.coords and tCoords or '')..(additionally.visual.info_bar.time and '[{F9D82F}'..os.date('%X')..'{888EA0}]' or '')..(additionally.visual.info_bar.ping and ping or '')..(additionally.visual.info_bar.fps and tFps or '')..(additionally.visual.info_bar.id and aid or '')
            local lenght = renderGetFontDrawTextLength(self.ifont, tOther)
            renderDrawBoxWithBorder(-1, posY - 18, posX + 2, 20, 0x44888EA0, 1, 0xFFF9D82F)
			renderFontDrawText(self.ifont, text_cheats, posX - posX, posY - (18-1), 0xFF888EA0)
			renderFontDrawText(self.ifont, tOther, posX - lenght, posY - (18-1), 0xFF888EA0)
        end
    end,
    fpsCorrection = function(self)
        return representIntAsFloat(readMemory(0xB7CB5C, 4, false))
    end,
    targetAtCoords = function(x, y, z)
        local cx, cy, cz = getActiveCameraCoordinates()
    
        local vect = {
            fX = cx - x,
            fY = cy - y,
            fZ = cz - z
        }
    
        local screenAspectRatio = representIntAsFloat(readMemory(0xC3EFA4, 4, false))
        local crosshairOffset = {
            representIntAsFloat(readMemory(0xB6EC10, 4, false)),
            representIntAsFloat(readMemory(0xB6EC14, 4, false))
        }
    
        -- weird shit
        local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
        fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
        fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))
    
        local camMode = readMemory(0xB6F1A8, 1, false)
    
        if not (camMode == 53 or camMode == 55) then -- sniper rifle etc.
            fx = 3.14159265 / 2
            fz = 3.14159265 / 2
        end
    
        local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
        local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)
    
        setCameraPositionUnfixed(az - fz, fx - ax)
    end,
    joinARGB = function(a, r, g, b)
        local argb = b  -- b
        argb = bit.bor(argb, bit.lshift(g, 8))  -- g
        argb = bit.bor(argb, bit.lshift(r, 16)) -- r
        argb = bit.bor(argb, bit.lshift(a, 24)) -- a
        return argb
    end,
    nameTagOn = function(self)
        local pStSet = sampGetServerSettingsPtr()
        mem.setfloat(pStSet + 39, 320.0)
        mem.setint8(pStSet + 47, 0)
        mem.setint8(pStSet + 56, 1)
    end,
    nameTagOff = function(self)
        local pStSet = sampGetServerSettingsPtr()
        mem.setfloat(pStSet + 39, 25.0)--onShowPlayerNameTag / NTdist
        mem.setint8(pStSet + 47, 1)
        mem.setint8(pStSet + 56, 1)
    end,
}

function AdditionallyClassThread()
    AdditionallyClass:global()
end

local CommandHelper = {
    selected = 1,
    font = renderCreateFont("Arial", 8, 2),
    current_show = 0,
    old_show = 0,
    curr_text = '',
    old_text = '',
    old_prefix = '',
    inserted = '',
    draw = function(self)
        if #admin_commands > 0 then
            local prefix = sampGetChatInputText()
            if prefix ~= self.old_prefix then
                self.old_prefix = prefix
                self.selected = 1
            end
            self.current_show = 0
            self.curr_text = ''
            if prefix ~= '' then
                if prefix:find('/', 1, true) and prefix ~= '/' then
                    local input = sampGetInputInfoPtr()
                    local input = getStructElement(input, 0x8, 4)
                    local x = getStructElement(input, 0x8, 4)
                    local y = getStructElement(input, 0xC, 4) + settings.cmd_helper.y
                    local chat_y = y
                    if self.old_show ~= 0 then
                        local syzes = findBoxSize(self.old_text, self.font, 0)
                        renderDrawCircleBox(syzes.x, syzes.y+3, x, chat_y, 5, 0x0B0000000) --поле ввода
                    end
                    local to_draw = {}
                    for key, category in ipairs(admin_commands) do
                        for key, command in ipairs(category.commands) do
                            if command.command:find(prefix, 1, true) then
                                if self.current_show <= settings.cmd_helper.lines then
                                    table.insert(to_draw, command)
                                    self.current_show  = self.current_show + 1
                                end
                            end
                        end
                    end
                    for key, command in ipairs(to_draw) do
                        local str_array = {}
                        for str in string.gmatch(u8:decode(command.text), ".") do
                            table.insert(str_array, str)
                        end
                        local max_chars = 250
                        if #str_array < max_chars then
                            max_chars = #str_array
                        end
                        local pref = ''
                        if key == self.selected then
                            self.inserted = u8:decode(command.command)
                            pref = '{ff2211}> '
                        end
                        local str = string.format("%s{22ff11}%s{ffffff}%s", pref, u8:decode(command.command), table.concat(str_array, "", 1, max_chars))
                        renderFontDrawText(self.font, str, x+5, y, 0xFFFFFFFF)
                        self.curr_text = self.curr_text..str..'\n'
                        y = y + renderGetFontDrawHeight(self.font) + 3
                    end
                    self.old_show = self.current_show
                    self.old_text = self.curr_text
                end
            end
        end
    end,
    renderButton = function(params)
        params_model = {
            text = 'str',
            color = 'num',
            color_hovered = 'num',
            font = 'font',
            positions = {
                x = 'int',
                y = 'int'
            },
        }
        local cx, cy = getCursorPos() -- получаем коорды мышки
        local box_color
        local box_sizes = findBoxSize(params.text, params.font, 0)
    
        x = params.positions.x - box_sizes.x
        if cx > params.positions.x and cx < params.positions.x+box_sizes.x and cy > params.positions.y and cy < params.positions.y+box_sizes.y then -- Проверяем находится курсор мышки в прямоугольной области 150 на 30 кнопки
            box_color = params.color_hovered
        else
            box_color = params.color
        end
        renderDrawCircleBox(box_sizes.x, box_sizes.y, params.positions.x, params.positions.y, 5, box_color)
        renderFontDrawText(params.font, params.text, params.positions.x+5, params.positions.y+5, 0xFFFFFFFF) -- рендер текста с небольшим смещением по 5 пикселей.
        
        local res = false -- статус нажатия кнопки
        if cx > params.positions.x and cx < params.positions.x+box_sizes.x and cy > params.positions.y and cy < params.positions.y+box_sizes.y and isKeyJustPressed(0x01) then -- Проверяем находится курсор мышки в прямоугольной области 150 на 30 кнопки
            res = true -- если мышка в нужной области и нажата ЛКМ, передаём true переменной
        end
        return res -- возвращаемый статус нажатия
    end
}

function onD3DPresent()
	if isSampAvailable() then
		DrawRender()
        if additionally.visual.aim_line.active then
            AimPosition:draw()
        end
        if true then
            AdditionallyClass:visual()
        end
        if settings.cmd_helper.active then
            CommandHelper:draw()
        end
	end
end

addEventHandler(
    'onWindowMessage', 
    function(msg, wparam)
        if CommandHelper.curr_text ~= '' then    
            if msg == 257 then
                if wparam == 0x26 --[[up]] then 
                    if CommandHelper.selected > 1 then
                        CommandHelper.selected = CommandHelper.selected - 1
                    end
                    consumeWindowMessage(true, false)
                elseif wparam == 0x28 --[[down]] then
                    if CommandHelper.selected < CommandHelper.current_show then
                        CommandHelper.selected = CommandHelper.selected + 1
                    end
                elseif wparam == 0x09 --[[tab]] then
                    sampSetChatInputText(CommandHelper.inserted)
                end
            end
        end
    end
)