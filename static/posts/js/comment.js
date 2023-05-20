function updateSummernoteStatus() {
    $('#summernote').summernote('reset')
    $('#summernote').summernote('fontName', 'Arial');
    $('#summernote').summernote('fontSize', 18);
    $('#summernote').summernote('foreColor', 'black');
    $('#summernote').summernote('color', 'black');
    $('#summernote').summernote('lineHeight', 1);
}

function sendComment(message, post) {
    let code = message
    if (code != '<p><br></p>' && code != '<p><span style="font-family: Arial; font-size: 12px;"><font color="#000000">﻿</font></span><br></p>'){
        let txt = {
            "text": code,
            "sender": sessionStorage.getItem('username'),
            "token": sessionStorage.getItem('auth_token'),
            "rating": Number(2),
            "receiver": Number(post)
        }
        txt = JSON.stringify(txt);
        $.ajax({
            type: "POST",
            url: window.location.protocol+'//'+window.location.host+'/comments/api/comments/create',
            cache: false,
            contentType: 'application/json',
            processData: false,
            data: txt,
            dataType : 'json',
            success: function(msg){
                if (msg.status == 'success'){
                    $('#summernote').summernote('reset')
                    location.reload();
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

function initSummernote() {
    $('#summernote').summernote({
        height: 130,
        toolbar: [
            ['style', ['bold', 'italic']],
            ['font', ['fontname', 'strikethrough', 'color']],
            ['para', ['paragraph']],
            ['insert', ['link']],
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
        lineHeights: ['1.0'],
        placeholder: WRITE_HERE,
        fontNames: ['Arial', 'Arial Black', 'Times New Roman'],
        disableDragAndDrop: true
    });
    updateSummernoteStatus()
}

$(document).ready(function(){
    $('#summer').css({'visibility': "hidden"})
    initSummernote()
    if (sessionStorage.getItem('username')) {
        $('#summer').css({'visibility': "visible"})
    }
    $('#send').css({'font-family': "Rubik"})
    $('#send').on("click", function (){
        sendComment($('#summernote').summernote('code'), POST_ID)
    });
});
