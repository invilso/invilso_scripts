from django.urls import path
from account.views import UserView, UsersView, ProfileView
# from .views import PaginatorView, StatsView

app_name = "account"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/users', UsersView.as_view()),
    path('api/users/<str:username>', UserView.as_view()),
    path('view/<str:username>', ProfileView.as_view()),
    path('edit/<str:username>', UserView.as_view()),
]