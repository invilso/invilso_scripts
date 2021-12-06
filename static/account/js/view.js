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
                result = result + `\n<li class="nav-item"><a class="nav-link" href="#" catId="${category.id}">${category.name}</a></li>`
            }
            $("#categoryes-list").html(result)
            $('.nav-link').css('font-family', 'Rubik');
        },
        error: function(msg){
            alert('Невозможно получить список категорий')
        }
    });
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
    $('#summernote').summernote({
        height: 200,
        toolbar: [
          ['style', ['bold', 'italic', 'clear']],
          ['font', ['fontname', 'strikethrough', 'color']],
          ['para', ['ul', 'ol', 'paragraph']],
          ['insert', ['picture', 'link', 'video', 'hr']],
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
        placeholder: 'Писать тут',
        fontNames: ['Arial', 'Arial Black', 'Times New Roman'],
        disableDragAndDrop: true
    });
    $('#summernote').summernote('reset')
    $('#summernote').summernote('fontName', 'Arial');
    $("#send").on("click", function (){
        let code = $('#summernote').summernote('code')
        if (code != '<p><br></p>' && code != '<p><span style="font-family: Arial;">﻿</span><br></p>'){
            let txt = {
                "text": code,
                "sender": sessionStorage.getItem('username'),
                "receiver": username
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
                    if (msg.status == 'ok'){
                        $('#summernote').summernote('reset')
                        alert('Отправлено.')
                    } else {
                        alert('Сообщение не отправлено, попробуйте ещё раз.')
                    }
                },
                error: function(msg){
                    alert('Сообщение не отправлено, попробуйте ещё раз.')
                }
            });
        } else {
            alert('Введите сообщение.')
        }
    });
    $('#detail-btn').css('font-family', 'Rubik');
    $('#ctbnt').css('font-family', 'Rubik');
    $('#ctbnt2').css('font-family', 'Rubik');
    $('#send').css('font-family', 'Rubik');
});

