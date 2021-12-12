from messanger.models import Dialog
from account.models import Profile
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from django.contrib.postgres.aggregates import ArrayAgg

def getDialogs(input: dict, request) -> dict:
    if input['user'] and input['token'] != None:
        user = User.objects.get(username=input['user'])
        if input['token'] == Token.objects.get(user=user).key:
            results = []
            dialogs = Dialog.objects.filter(members=user).prefetch_related('members').only('id', 'name', 'is_active', 'is_private', 'members__username', 'members__profile__photo__file')
            for element in dialogs:
                results.append(
                    dict(
                        id=element.id, 
                        name=element.name, 
                        is_active=element.is_active, 
                        is_private=element.is_private, 
                        members=[{'username': b.username,'photo': str(b.profile.photo.file) if b.profile.photo else None} for b in element.members.all()]
                    )
                )
            return {'status': 'success', 'desc':'Dialogues received successfully', 'data': results}
        else:
            return {'status': 'error', 'desc':'Authentification error'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}

def getDialog(input: dict, request) -> dict:
    if input['dialog'] and input['token'] and input['user'] != None:
        user = User.objects.get(username=input['user'])
        if input['token'] == Token.objects.get(user=user).key:
            results = []
            dialog = Dialog.objects.filter(id=input['dialog']).prefetch_related('messages', 'members').only('id', 'name', 'is_active', 'is_private', 'messages', 'members__username', 'members__profile__photo__file')
            results = dict(
                id=dialog[0].id, 
                name=dialog[0].name, 
                is_active=dialog[0].is_active, 
                is_private=dialog[0].is_private,
                messages = [{'id':b.id, 'text': b.text, 'timestamp': b.timestamp, 'sender': {'username':b.sender.username, 'photo':str(b.sender.profile.photo.file) if b.sender.profile.photo else None}} for b in dialog[0].messages.all()],
                members=[{'username': b.username,'photo': str(b.profile.photo.file) if b.profile.photo else None} for b in dialog[0].members.all()]
            )
            return {'status': 'success', 'desc':'Dialogues received successfully', 'data': results}
        else:
            return {'status': 'error', 'desc':'Authentification error'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}