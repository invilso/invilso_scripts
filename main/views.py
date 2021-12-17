from django.shortcuts import render
from django.views.generic.list import ListView
from main.services.get import getNewPosts, getNewUsers

# Create your views here.
class PostsView(ListView):
    def get(self, request):
        return render(request, 'main/main.html', {'posts': getNewPosts(), 'users': getNewUsers()})