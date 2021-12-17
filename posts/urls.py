from django.urls import path
from posts.views import PostView

app_name = "posts"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    # path('api/post/create', MessagesCreateAPI.as_view()),
    # path('api/post/get', DialogGetAPI.as_view()),
    path('<int:pk>', PostView.as_view(), name='view'),
]