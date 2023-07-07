from django.shortcuts import render, redirect
from django.views.generic.list import ListView
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.utils.translation import gettext as _

from invilso_scripts.utils import is_human
User = get_user_model()

def _login(request):
    username = request.POST['username']
    password = request.POST['password']
    user = authenticate(request, username=username, password=password)
    if user is not None:
        login(request, user)
        Token.objects.get_or_create(user=user)
        messages.success(request, _('You are successfully logged into your account.'))
        return redirect('main:main')  # Замените 'home' на нужный URL-шаблон
    else:
        messages.error(request, _('Invalid username or password.'))
        return redirect('main:main')
        
    

class LoginView(ListView):
    def post(self, request):
        if not is_human(request):
            messages.error(request, _('Failed to pass the anti-bot protection.'))
            return redirect('main:main')
        return _login(request)
    
    
class RegistrationView(ListView):
    def post(self, request):
        if not is_human(request):
            messages.error(request, _('Failed to pass the anti-bot protection.'))
            return redirect('main:main')
        try:
            user = User(
                email = request.POST['email'], # Назначаем Email
                username = request.POST['username'], # Назначаем Логин
            )
            # Проверяем на валидность пароль
            password = request.POST['password']
            # Сохраняем пароль
            user.set_password(password)
            # Сохраняем пользователя
            user.save()
            # Возвращаем нового пользователя 
            messages.success(request, _('You are successfully registered.'))
            return _login(request)
        except Exception as e:
            messages.error(request, _('Invalid username or password.'))
            return redirect('main:main')
            

class LogoutView(ListView):
    def get(self, request):
        logout(request)
        return redirect('main:main')
