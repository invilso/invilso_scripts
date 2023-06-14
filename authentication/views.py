from django.shortcuts import render, redirect
from django.views.generic.list import ListView
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
User = get_user_model()

def login2(request):
    username = request.POST['username']
    password = request.POST['password']
    user = authenticate(request, username=username, password=password)
    if user is not None:
        login(request, user)
        Token.objects.get_or_create(user=user)
        return redirect('main:main')  # Замените 'home' на нужный URL-шаблон
    else:
        messages.error(request, 'Invalid username or password.')
        return redirect('main:main')
        
    

class LoginView(ListView):
    def post(self, request):
        return login2(request)
    
    
class RegistrationView(ListView):
    def post(self, request):
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
            return login2(request)
        except Exception as e:
            print(2, e)
            messages.error(request, 'Invalid username or password.')
            return redirect('main:main')
            

class LogoutView(ListView):
    def get(self, request):
        logout(request)
        return redirect('main:main')
