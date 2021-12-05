from django.shortcuts import render
from django.views.generic.list import ListView

class LoginView(ListView):
    def get(self, request):
        return render(request, 'authentication/login.html')

class RegistrationView(ListView):
    def get(self, request):
        return render(request, 'authentication/registration.html')
# Create your views here.
