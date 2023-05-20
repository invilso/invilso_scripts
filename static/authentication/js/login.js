$(document).ready(function(){
    $( "#login" ).click(function() {
        $.ajax({
            type: "POST",
            url: window.location.protocol+'//'+window.location.host+'/api/login/token/login',
            cache: false,
            contentType: 'application/x-www-form-urlencoded',
            processData: false,
            data: "username="+$("#inputEmail").val()+"&password="+$("#inputPassword").val(),
            dataType : 'json',
            success: function(msg){
                sessionStorage.setItem('auth_token', msg.auth_token)
                sessionStorage.setItem('username', $("#inputEmail").val())
                window.location.replace(window.location.protocol+'//'+window.location.host);
            },
            error: function(msg){
                $("#error").attr('class', 'alert alert-danger')
                $("#error").text(INPUT_DATA_AUTH);
            }
        });
    });
    $("#checkbox1").click(function() {
        if ($(this).is(':checked')){
            $('#inputPassword').attr('type', 'text');
        } else {
            $('#inputPassword').attr('type', 'password');
        }
    });
});