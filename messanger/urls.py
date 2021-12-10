from django.urls import path
from messanger.views import MessagesCreateAPI, DialogsGetAPI, DialogsView, DialogView

app_name = "messanger"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/messages/create', MessagesCreateAPI.as_view()),
    path('api/messages/get', DialogsGetAPI.as_view()),
    path('', DialogsView.as_view()),
    path('dialog/<int:pk>', DialogView.as_view()),
]