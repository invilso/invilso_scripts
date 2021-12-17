from posts.models import Post
def getPost(id):
    return Post.objects.get(id = id)