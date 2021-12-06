from django.urls import path
from messanger.views import MessagesView, MessangeView, MessagesCreateView

app_name = "messanger"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/messages', MessagesView.as_view()),
    path('api/messages/create', MessagesCreateView.as_view()),
    path('api/message/<int:pk>', MessangeView.as_view()),
    # path('list', SubcategoryesView.as_view()),
    # path('dialog/<int:pk', SubcategoryView.as_view()),
]