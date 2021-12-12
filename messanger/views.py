from django.shortcuts import render
from django.views.generic.list import ListView
from django.http import JsonResponse
from messanger.services.create import createMessage
from messanger.services.get import getDialogs, getDialog
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
import json
import logging
logger = logging.getLogger(__name__)


@method_decorator(csrf_exempt, name='dispatch')
class MessagesCreateAPI(ListView):
    def post(self, request):
        response = createMessage(json.loads(request.body.decode('utf-8')))
        return JsonResponse(response)

@method_decorator(csrf_exempt, name='dispatch')
class DialogsGetAPI(ListView):
    def post(self, request): 
        response = getDialogs(json.loads(request.body.decode('utf-8')), request)
        return JsonResponse(response)

@method_decorator(csrf_exempt, name='dispatch')
class DialogGetAPI(ListView):
    def post(self, request): 
        response = getDialog(json.loads(request.body.decode('utf-8')), request)
        return JsonResponse(response)


class DialogsView(ListView):
    def get(self, request): 
        logger.warning('mq')
        return render(request, 'messanger/main.html')

class DialogView(ListView):
    def get(self, request): 
        return render(request, 'messanger/dialog.html')
    

