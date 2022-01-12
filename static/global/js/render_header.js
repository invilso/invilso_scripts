$(document).ready(function(){
    // $("#categoryes-list").html = 
    $.ajax({
        type: "GET",
        url: window.location.protocol+'//'+window.location.host+'/categoryes/api/categoryes?format=json',
        cache: false,
        dataType : 'json',
        success: function(msg){
            let result = ''
            for (let category of msg) {
                result = result + `\n<li class="nav-item"><a class="nav-link" href="${window.location.protocol}//${window.location.host}/categoryes/${category.id}" cat-id="${category.id}">${category.name}</a></li>`
            }
            $("#categoryes-list").html(result)
            $('.nav-link').css('font-family', 'Rubik');
            $('.nav-link').css('font-size', '18px');
        },
        error: function(msg){
            alert('Невозможно получить список категорий')
        }
    });
    if (!sessionStorage.getItem('username')){
        $("#button-login").text('Войти')
        $("#button-login").attr('href', window.location.protocol+'//'+window.location.host+'/authentication/login')
        $('#button-login').css('font-family', 'Rubik'); 
    } else {
        let staff_button = ''
        $.ajax({
            type: "GET",
            url: window.location.protocol+'//'+window.location.host+'/account/api/users/'+sessionStorage.getItem('username')+'?format=json',
            cache: false,
            dataType : 'json',
            success: function(msg){
                if (msg.is_staff){
                    staff_button = `<a class="dropdown-item" href="">Создать пост</a>`
                }
                $('#buttons-login-menu').html(`<div class="btn-group" style="margin-top:-20px">
                    <button type="button" class="btn" style="font-family:Rubik">Меню</button>
                    <button type="button" class="btn dropdown-toggle dropdown-toggle-split" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <span class="sr-only">Меню</span>
                    </button>
                    <div class="dropdown-menu">
                        <a class="dropdown-item" href="${window.location.protocol}//${window.location.host}/account/view/${sessionStorage.getItem('username')}">Профиль</a>
                        <a class="dropdown-item" href="${URL_MESSAGES}">Сообщения</a>
                        ${staff_button}
                        <div class="dropdown-divider"></div>
                        <a class="dropdown-item" href="${URL_LOGOUT}">Выйти</a>
                    </div>
                </div>`)
                $('#div-menu').css('maggin-top', '-20px'); 
            },
            error: function(msg){
                alert('Невозможно получить информацию о вас')
            }
        });
        
    }
   
}); 