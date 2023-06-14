from django.urls import path
from messanger.views import MessagesCreateAPI, DialogsGetAPI, DialogGetAPI, DialogsView, DialogView

app_name = "messanger"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/messages/create', MessagesCreateAPI.as_view()),
    path('messages/create', MessagesCreateAPI.as_view(), name='create'),
    path('api/dialogs/get', DialogsGetAPI.as_view()),
    path('api/dialog/get', DialogGetAPI.as_view()),
    path('', DialogsView.as_view(), name='view'),
    path('dialog/<int:pk>', DialogView.as_view()),
]