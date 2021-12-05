from django.urls import path
from main.views import PostsView

app_name = "main"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('', PostsView.as_view(), name = 'main'),
]