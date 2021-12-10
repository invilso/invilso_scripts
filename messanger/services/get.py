from messanger.models import Message
from account.models import Profile
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

def getDialogs(input: dict) -> list or dict:
    if input['user'] and input['token'] != None:
        user = User.objects.get(username=input['user'])
        if input['token'] == Token.objects.get(user=user).key:
            receiver = User.objects.get(username=input['receiver'])
            msg = Message(text=input['text'], receiver=receiver, sender=user)
            msg.save()
            return {'status': 'success', 'desc':'Ok'}
        else:
            return {'status': 'error', 'desc':'Authentification error'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}

def getDialog(input: dict) -> dict:
    pass