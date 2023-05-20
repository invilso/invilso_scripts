function updateSummernoteStatus() {
    $('#summernote').summernote('reset')
    $('#summernote').summernote('fontName', 'Arial');
    $('#summernote').summernote('fontSize', 16);
    $('#summernote').summernote('foreColor', 'black');
    $('#summernote').summernote('lineHeight', 1.0);
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

function initSummernote() {
    $('#summernote').summernote({
        height: 130,
        toolbar: [
            ['style', ['bold', 'italic']],
            ['font', ['fontname', 'strikethrough', 'color', 'fontsize']],
            ['para', ['paragraph']],
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
        lineHeights: ['1.0'],
        placeholder: WRITE_HERE,
        fontNames: ['Arial', 'Arial Black', 'Times New Roman'],
        disableDragAndDrop: true
    });
    updateSummernoteStatus()
}



$(document).ready(function(){
    // $("#categoryes-list").html = 
    if (sessionStorage.getItem('username')){
        if (sessionStorage.getItem('username') != username){
            $("#ctbnt2").css("display", "none");
        } else {
            $("#ctbnt").css("display", "none");
        }
    } else {
        $("#ctbnt").css("display", "none");
        $("#ctbnt2").css("display", "none");
    }
    $("#contact").css("display", "none");
    $("#ctbnt").on("click", function (){
        console.log('b')
        $("#detail").css("display", "none");
        $("#contact").css("display", "block");
    } );
    $("#detail-btn").on("click", function (){
        console.log('a')
        $("#contact").css("display", "none");
        $("#detail").css("display", "block");
    });
    initSummernote()
    $("#send").on("click", function (){
        let code = $('#summernote').summernote('code')
        sendMessage(code, username)
    });
    $('#detail-btn').css('font-family', 'Rubik');
    $('#ctbnt').css('font-family', 'Rubik');
    $('#ctbnt2').css('font-family', 'Rubik');
    $('#send').css('font-family', 'Rubik');
});