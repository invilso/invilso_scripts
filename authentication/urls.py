from django.urls import path
from authentication.views import LoginView, RegistrationView
# from .views import PaginatorView, StatsView

app_name = "authentification"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('login', LoginView.as_view(), name='login'),
    path('registration', RegistrationView.as_view(), name='registration'),
]