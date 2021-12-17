$(document).ready(function(){
    sessionStorage.removeItem('auth_token')
    sessionStorage.removeItem('username')
    setTimeout(function(){
        window.location.replace(window.location.protocol+'//'+window.location.host);
    }, 1900);
});

