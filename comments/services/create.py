from typing import Union, List
from comments.models import Comment
from posts.models import Post
from django.db.models import QuerySet
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token


def createComment(input: dict) -> dict:
    """ Creation of a comment in a post. Depending on the context of the request. """
    if input['text'] and input['receiver'] and input['sender'] and input['token'] != None and input['rating']:
        rating = int(input['rating'])
        if rating > 0 and rating < 6:
            sender = User.objects.get(username=input['sender'])     
            if input['token'] == Token.objects.get(user=sender).key:
                try:
                    if input['replied'] != None:
                        try:
                            replied_msg = Comment.objects.get(id=int(input['replied']))
                        except ValueError:
                            return {'status': 'error', 'desc':'Value error. In replied, you need to write the comment ID.'}
                    msg = Comment(text=input['text'], parent=replied_msg, owner=sender, rating = rating)
                except KeyError:
                    msg = Comment(text=input['text'], owner=sender, rating = rating)
                msg.save()       
                receiver = int(input['receiver'])
                if type(receiver) == int:
                    post = Post.objects.get(id=receiver)
                    if post:
                        createInExistingPost(post, msg)
                        return {'status': 'success', 'desc':'Comment create.'}  
                    else:
                        return {'status': 'error', 'desc':'Please input correct receiver'}  
                else:
                    return {'status': 'error', 'desc': 'Pleace input correct receiver.'}
            else:
                return {'status': 'error', 'desc':'Authentification error'}
        else:
            return {'status': 'error', 'desc':'Please input corrent rating'}
    else:
        return {'status': 'error', 'desc':'Empty fields'}

def createInExistingPost(post: Union[QuerySet, List[Post]], message: Union[QuerySet, List[Comment]]) -> None:
    """ Creates a message in an existing conversation. """
    post.comments.add(message)
    post.is_active = True
    post.save()
        