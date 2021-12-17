from django.urls import path
from files.views import DownloadView

app_name = "files"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('download/<int:pk>', DownloadView.as_view(), name = 'download'),
]