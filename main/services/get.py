from posts.models import Post
from django.contrib.auth.models import User

def getNewPosts():
    return Post.objects.order_by('-timestamp')[:5]

def getNewUsers():
    return User.objects.order_by('-date_joined')[:5]