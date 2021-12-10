from typing import Union, List
from messanger.models import Message, Dialog
from django.db.models import QuerySet
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token


def createMessage(input: dict) -> dict:
    """ Creation of a message in a private dialogue, or in general. Depending on the context of the request. """

    if input['text'] and input['receiver'] and input['sender'] and input['token'] != None:
        sender = User.objects.get(username=input['sender'])     
        if input['token'] == Token.objects.get(user=sender).key:
            try:
                if input['replied'] != None:
                    try:
                        replied_msg = Message.objects.get(id=int(input['replied']))   
                    except ValueError:
                        return {'status': 'error', 'desc':'Value error. In replied, you need to write the message ID.'}
                msg = Message(text=input['text'], replied=replied_msg, sender=sender)
            except KeyError:
                msg = Message(text=input['text'], sender=sender)
            msg.save()    
            if type(input['receiver']) == str:
                receiver = User.objects.get(username=input['receiver'])
                dialog = findPrivateDialog(sender=sender, receiver=receiver)
                if dialog:
                    createInExistingDialog(dialog, msg)
                    return {'status': 'success', 'desc':'Message create. Old dialog'}   
                else:
                    new_dialog = Dialog(is_private=True, is_active=True)
                    new_dialog.save()
                    new_dialog.members.add(sender, receiver)
                    new_dialog.messages.add(msg)
                    return {'status': 'success', 'desc':'Message create. New dialog'}    
            elif type(input['receiver']) == int:
                dialog = Dialog.objects.get(id=input['receiver'])
                createInExistingDialog(dialog, msg)
                return {'status': 'success', 'desc':'Message create. Old dialog'} 
            else:
                return {'status': 'error', 'desc': 'Pleace input correct receiver.'}
        else:
            return {'status': 'error', 'desc':'Authentification error'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}

def createInExistingDialog(dialog: Union[QuerySet, List[Dialog]], message: Union[QuerySet, List[Message]]) -> None:
    """ Creates a message in an existing conversation. """
    dialog.messages.add(message)
    dialog.is_active = True
    dialog.save()


def findPrivateDialog(sender: Union[QuerySet, List[User]], receiver: Union[QuerySet, List[User]]) -> Union[QuerySet, List[Dialog]]:
    """ Searches for a shared, private dialogue between two users. """

    dialogs = Dialog.objects.filter(members=sender)
    for dialog in dialogs:
        if dialog.is_private:
            if receiver in dialog.members.all():
                return dialog
        