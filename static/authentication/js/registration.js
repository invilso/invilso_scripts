function validateEmail(email) {
    var re = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/;
    return re.test(String(email).toLowerCase());
}


$(document).ready(function(){
    $( "#register" ).click(function() {
        if (validateEmail($("#inputEmail").val()) || $("#inputEmail").val() == "") {
            $.ajax({
                type: "POST",
                url: window.location.protocol+'//'+window.location.host+'/api/auth/users/',
                cache: false,
                contentType: 'application/x-www-form-urlencoded',
                processData: false,
                data: "username="+$("#inputLogin").val()+"&password="+$("#inputPassword").val()+"&email="+$("#inputEmail").val(),
                dataType : 'json',
                success: function(msg){
                    window.location.replace(window.location.protocol+'//'+window.location.host+"/authentication/login");
                },
                error: function(msg){
                    $("#error").attr('class', 'alert alert-danger')
                    $("#error").text(USER_IS_EXSIST);
                }
            });
        } else {
            $("#error").attr('class', 'alert alert-danger')
            $("#error").text(BAD_EMAIL);
        }
        
    });
    $("#checkbox1").click(function() {
        if ($(this).is(':checked')){
            $('#inputPassword').attr('type', 'text');
        } else {
            $('#inputPassword').attr('type', 'password');
        }
    });
});