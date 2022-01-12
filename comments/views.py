from django.shortcuts import render
from django.views.generic.list import ListView
from django.http import JsonResponse
from comments.services.create import createComment
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
import json

@method_decorator(csrf_exempt, name='dispatch')
class CommentCreateAPI(ListView):
    def post(self, request):
        response = createComment(json.loads(request.body.decode('utf-8')))
        return JsonResponse(response)