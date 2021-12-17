from django.conf.urls import url

from payments.views import PayView, PayCallbackView

app_name = 'payments'

urlpatterns = [
    url(r'^pay/$', PayView.as_view(), name='pay_view'),
    url(r'^pay-callback/$', PayCallbackView.as_view(), name='pay_callback'),
]