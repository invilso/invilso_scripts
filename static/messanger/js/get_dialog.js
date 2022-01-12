let current_dialog = null

function updateSummernoteStatus() {
    $('#summernote').summernote('reset')
    $('#summernote').summernote('fontName', 'Arial');
    $('#summernote').summernote('fontSize', 14);
    $('#summernote').summernote('foreColor', 'black');
    $('#summernote').summernote('lineHeight', 0.5);
}

function sendMessage(message, dialog) {
    let code = message
    if (code != '<p><br></p>' && code != '<p><span style="font-family: Arial; font-size: 12px;"><font color="#000000">﻿</font></span><br></p>'){
        let txt = {
            "text": code,
            "sender": sessionStorage.getItem('username'),
            "token": sessionStorage.getItem('auth_token'),
            "receiver": dialog
        }
        txt = JSON.stringify(txt);
        $.ajax({
            type: "POST",
            url: window.location.protocol+'//'+window.location.host+'/messanger/api/messages/create',
            cache: false,
            contentType: 'application/json',
            processData: false,
            data: txt,
            dataType : 'json',
            success: function(msg){
                if (msg.status == 'success'){
                    $('#summernote').summernote('reset')
                    getDialog(current_dialog)
                    updateSummernoteStatus()
                } else {
                    alert(`Сообщение не отправлено, попробуйте ещё раз. (${msg.desc})`)
                }
            },
            error: function(msg){
                alert(`Сообщение не отправлено, попробуйте ещё раз. (${msg.desc})`)
            }
        });
    } else {
        alert('Введите сообщение.')
    }
}

function getDialog(d_id) {
    let txt = {
        "dialog": d_id,
        "user": sessionStorage.getItem('username'),
        "token": sessionStorage.getItem('auth_token'),
    }
    current_dialog = txt.dialog
    txt = JSON.stringify(txt);
    $.ajax({
        type: "POST",
        url: window.location.protocol+'//'+window.location.host+'/messanger/api/dialog/get',
        cache: false,
        contentType: 'application/json',
        processData: false,
        data: txt,
        dataType : 'json',
        success: function(msg){
            if (msg.status == 'success'){
                let dialog_info = createDialogNameAndPhoto(msg.data)
                $('#name-dialog').text(dialog_info.name)
                // $('#reload-icon').css()
                let result = ''
                for (let message of msg.data.messages) {
                    if (message.sender.username != sessionStorage.getItem('username')){
                        result = result + `
                        <li class="chat-left" msg-id="${message.id}">
                            <div class="chat-avatar">
                                <img src="${getDialogPhoto(message.sender.photo)}" alt="${message.sender.username}">
                                <div class="chat-name">${message.sender.username}</div>
                            </div>
                            <div class="chat-text">${message.text}</div>
                            <div class="chat-hour">${getLocalizeDateTime(message.timestamp)}</div>
                        </li>`
                    } else {
                        result = result + `
                        <li class="chat-right" msg-id="${message.id}">
                            <div class="chat-hour">${getLocalizeDateTime(message.timestamp)}</div>
                            <div class="chat-text">${message.text}</div>
                            <div class="chat-avatar">
                                <img src="${getDialogPhoto(message.sender.photo)}" alt="${message.sender.username}">
                                <div class="chat-name">${message.sender.username}</div>
                            </div>
                        </li>`
                    }
                }
                $("#messages-list").html(result)
                $('#summer').css({'visibility': "visible"})
                let div = $("#chat-box");
                div.scrollTop(div.prop('scrollHeight'));
                div.css({'visibility': "visible"})
            } else {
                alert(`Сервер отправил отрицательный ответ, попробуйте ещё раз. (${msg.desc})`)
                console.log(msg)
            }
        },
        error: function(msg){
            alert(`Сервер оветил ошибкой, или не отвечает, попробуйте ещё раз. (${msg})`)
        }
    });
}

function initSummernote() {
    $('#summernote').summernote({
        height: 130,
        toolbar: [
          ['style', ['bold', 'italic']],
          ['font', ['fontname', 'strikethrough', 'color']],
          ['para', ['ul', 'ol', 'paragraph', 'height']],
          ['insert', ['picture', 'link', 'video']],
          ['misc', ['fullscreen', 'codeview']],
        ],
        popover: {
            image: [
              ['image', ['resizeFull', 'resizeHalf', 'resizeQuarter', 'resizeNone']],
              ['float', ['floatLeft', 'floatRight', 'floatNone']],
              ['remove', ['removeMedia']]
            ],
            link: [
              ['link', ['linkDialogShow', 'unlink']]
            ],
            table: [
              ['add', ['addRowDown', 'addRowUp', 'addColLeft', 'addColRight']],
              ['delete', ['deleteRow', 'deleteCol', 'deleteTable']],
            ],
            air: [
              ['color', ['color']],
              ['font', ['bold', 'underline', 'clear']],
              ['para', ['ul', 'paragraph']],
              ['table', ['table']],
              ['insert', ['link', 'picture']]
            ]
        },
        lang: 'ru-RU',
        lineHeights: ['0.5', '1.0'],
        placeholder: 'Писать тут',
        fontNames: ['Arial', 'Arial Black', 'Times New Roman'],
        disableDragAndDrop: true
    });
    updateSummernoteStatus()
}

$(document).ready(function(){
    $("#dialogs-list").on("click", '#dialog-button', function (){
        getDialog(Number($(this).attr('dialog-id')))
    });
    $('#messages-list').scrollspy({target: ".navbar", offset: 50});
    initSummernote()
    $('#summer').css({'visibility': "hidden"})
    $('#btn-send').css({'font-family': "Rubik"})
    $('#btn-send').on("click", function (){
        sendMessage($('#summernote').summernote('code'), current_dialog)
    });
    $('#reload-icon').on("click", function (){
        getDialog(current_dialog)
        alert('Обновлено')
    });
});
