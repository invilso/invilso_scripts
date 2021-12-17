from django.shortcuts import render

# Create your views here.
from django.shortcuts import render
from django.views.generic.list import ListView
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from posts.services.get import getPost
import json
import logging
logger = logging.getLogger(__name__)


@method_decorator(csrf_exempt, name='dispatch')
class PostCreateAPI(ListView): #todo
    def post(self, request):
        return JsonResponse(response)

class PostView(ListView):
    def get(self, request, **kwargs): 
        post = getPost(kwargs['pk'])
        return render(request, 'posts/main.html', {"post": post})
    

