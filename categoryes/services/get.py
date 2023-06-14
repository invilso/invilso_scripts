from categoryes.models import Category
from posts.models import Post
from categoryes.models import Category
from django.db.models import Q

def getCategoryPosts(key, search) -> Post: 
    return getSearchPosts(search).filter(category_id=key)

def getAllPosts():
    return Post.objects.filter(moderated=True).order_by('-timestamp')

def getSearchPosts(search):
    return getAllPosts().filter(Q(title__icontains=search) | Q(text__icontains=search) | Q(owner__username=search))

def getCategory(key):
    return Category.objects.get(id=key)
