from django.http import FileResponse
from django.views.generic.list import ListView
from files.services.get import getFile

# Create your views here.
class DownloadView(ListView):
    def get(self, request, **kwargs): 
        file = getFile(kwargs['pk'])
        return FileResponse(file)