function createDialogNameAndPhoto(dialog) {
    let result = {
        'photo': null,
        'name': ''
    }
    if (dialog.name) {
        result.name = dialog.name
        result.photo = null
        return result
    } else {
        if (dialog.is_private){
            for (let member of dialog.members) {
                if (member.username != sessionStorage.getItem('username')){
                    result.name = member.username
                    result.photo = member.photo
                    return result
                }
            }
        } else {
            let i = 0
            for (let member of dialog.members) {
                result.photo = null
                if (i > 1){
                    result.name = result.name + " " + member.username + " ..."
                    return result
                } else {
                    result.name = result.name + " " + member.username
                }
                i = i + 1
            }
            return result
        }
    }
}

function getDialogPhoto(photo) {
    if (photo == null){
        return 'https://brilliant24.ru/files/cat/template_01.png'
    } else {
        return window.location.protocol+'//'+window.location.host+'/'+photo
    }
}

function getLocalizeDateTime(dateString) {
    return dateString.replace(/.+T/, ' ').replace(/\..+/, '')
}


$(document).ready(function(){
    let txt = {
        "user": sessionStorage.getItem('username'),
        "token": sessionStorage.getItem('auth_token'),
    }
    txt = JSON.stringify(txt);
    $.ajax({
        type: "POST",
        url: window.location.protocol+'//'+window.location.host+'/messanger/api/dialogs/get',
        cache: false,
        contentType: 'application/json',
        processData: false,
        data: txt,
        dataType : 'json',
        success: function(msg){
            if (msg.status == 'success'){
                let result = ''
                msg.data.reverse()
                for (let dialog of msg.data) {
                    let dialog_info = createDialogNameAndPhoto(dialog)
                    result = result + `
                    <li class="person" id="dialog-button" dialog-id="${dialog.id}">
                        <div class="user">
                            <img src="${getDialogPhoto(dialog_info.photo)}" alt="${dialog_info.name}">
                        </div>
                        <p class="name-time">
                            <span class="name">${dialog_info.name}</span>
                        </p>
                    </li>`
                }
                $("#dialogs-list").html(result)
            } else {
                alert(`Сообщение не отправлено, попробуйте ещё раз. (${msg.desc})`)
                console.log(msg)
            }
        },
        error: function(msg){
            alert(`Сообщение не отправлено, попробуйте ещё раз. (${msg.desc})`)
            console.log(msg)
        }
    })
});