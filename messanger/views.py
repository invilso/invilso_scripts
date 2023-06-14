from django.shortcuts import redirect, render
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
        logger.debug('Создано сообщение')
        return JsonResponse(response)
    
class MessagesCreate(ListView):
    def post(self, request):
        createMessage(request.POST)
        logger.debug('Создано сообщение')
        return redirect(request.META.get('HTTP_REFERER'))

@method_decorator(csrf_exempt, name='dispatch')
class DialogsGetAPI(ListView):
    def post(self, request): 
        response = getDialogs(json.loads(request.body.decode('utf-8')), request)
        logger.debug('Получен список диалогов')
        return JsonResponse(response)

@method_decorator(csrf_exempt, name='dispatch')
class DialogGetAPI(ListView):
    def post(self, request): 
        response = getDialog(json.loads(request.body.decode('utf-8')), request)
        logger.debug('Получены сообщения')
        return JsonResponse(response)


class DialogsView(ListView):
    def get(self, request): 
        logger.debug('Открыта главная сообщений')
        return render(request, 'messanger/main.html')

class DialogView(ListView):
    def get(self, request): 
        
        return render(request, 'messanger/dialog.html')
    

