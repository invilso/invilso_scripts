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
            $('.nav-link').css('font-size', '18px');
        },
        error: function(msg){
            alert('Невозможно получить список категорий')
        }
    });
    if (!sessionStorage.getItem('username')){
        $("#button-login").text('Войти')
        $("#button-login").attr('href', window.location.protocol+'//'+window.location.host+'/authentication/login')
    } else {
        $("#button-login").text('Профиль')
        $("#button-login").attr('href', window.location.protocol+'//'+window.location.host+'/account/view/'+sessionStorage.getItem('username'))
    }
    $('#button-login').css('font-family', 'Rubik');
});