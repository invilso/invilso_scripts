from django.urls import path
from comments.views import CommentCreateAPI

app_name = "comments"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/comments/create', CommentCreateAPI.as_view(), name='create'),
]