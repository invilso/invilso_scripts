from typing import Dict

from django.http import response


from messanger.models import Message, Dialog
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

def createMessage(input: dict) -> dict:
    if input['text'] and input['receiver'] and input['sender'] and input['token'] != None:
        sender = User.objects.get(username=input['sender'])
        if input['token'] == Token.objects.get(user=sender).key:
            receiver = User.objects.get(username=input['receiver'])
            msg = Message(text=input['text'], receiver=receiver, sender=sender)
            msg.save()
            return {'status': 'success', 'desc':'Ok'}
        else:
            return {'status': 'error', 'desc':'Authentification error'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}

def findPrivateDialog() -> dict:
    pass