function validateEmail(email) {
    var re = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/;
    return re.test(String(email).toLowerCase());
}


$(document).ready(function(){
    $( "#register" ).click(function() {
        if (validateEmail($("#inputEmail").val()) || $("#inputEmail").val() == "") {
            $.ajax({
                type: "POST",
                url: '../api/auth/users/',
                cache: false,
                contentType: 'application/x-www-form-urlencoded',
                processData: false,
                data: "username="+$("#inputLogin").val()+"&password="+$("#inputPassword").val()+"&email="+$("#inputEmail").val(),
                dataType : 'json',
                success: function(msg){
                    window.location.replace("../authentication/login");
                },
                error: function(msg){
                    $("#error").attr('class', 'alert alert-danger')
                    $("#error").text("Такой пользователь уже существует.");
                }
            });
        } else {
            $("#error").attr('class', 'alert alert-danger')
            $("#error").text("E-mail введён некорректно.");
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