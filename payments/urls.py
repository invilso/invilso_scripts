# from django.conf.urls import url
from django.urls import re_path

from payments.views import PayView, PayCallbackView

app_name = 'payments'

urlpatterns = [
    re_path(r'^pay/$', PayView.as_view(), name='pay_view'),
    re_path(r'^pay-callback/$', PayCallbackView.as_view(), name='pay_callback'),
]