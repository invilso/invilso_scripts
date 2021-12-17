from categoryes.models import Category
from posts.models import Post
from categoryes.models import Category
from django.db.models import Q

def getPosts(key, search):
    return Post.objects.filter(category_id=key).filter(Q(title__icontains=search) | Q(text__icontains=search) | Q(owner__username=search)).order_by('-timestamp')

def getCategory(key):
    return Category.objects.get(id=key)
