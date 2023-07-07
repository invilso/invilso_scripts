from django.shortcuts import get_object_or_404
from posts.models import Post
def getPost(id):
    return get_object_or_404(Post, id = id)