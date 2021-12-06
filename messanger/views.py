from messanger.serializer import MessageSerializer
from messanger.models import Message
from django.contrib.auth.models import User
from rest_framework import permissions
from django.views.generic.list import ListView
from django.http import JsonResponse
import json
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

    
class MessagesView(ListCreateAPIView):
    queryset = Message.objects.all()
    # permission_classes = [permissions.IsAuthenticated]
    serializer_class = MessageSerializer

@method_decorator(csrf_exempt, name='dispatch')
class MessagesCreateView(ListView):
    def post(self, request, *args, **kwargs):
        input = json.loads(request.body.decode('utf-8'))
        print(input['text'], input['receiver'], input['sender'])
        if input['text'] and input['receiver'] and input['sender'] != None:
            receiver = User.objects.get(username=input['receiver'])
            sender = User.objects.get(username=input['sender'])
            msg = Message(text=input['text'], receiver=receiver, sender=sender)
            msg.save()
            print('ОО КРУТЬ')
            return JsonResponse({'status': 'ok'})
        else:
            print('Пиздец')
            return JsonResponse({'status': 'error'})
        


class MessangeView(RetrieveUpdateDestroyAPIView):
    queryset = Message.objects.all()
    # permission_classes = [permissions.IsAuthenticated]
    serializer_class = MessageSerializer
