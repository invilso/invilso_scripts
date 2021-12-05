from django.shortcuts import render
from django.views.generic.list import ListView

# Create your views here.
class PostsView(ListView):
    def get(self, request):
        return render(request, 'authentication/login.html')