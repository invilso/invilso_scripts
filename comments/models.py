from django.db import models
from django.contrib.auth.models import User
from posts.models import Post

class Comment(models.Model):
    text = models.TextField(max_length=2000)
    timestamp = models.DateTimeField(auto_now_add=True)
    rating = models.IntegerField()
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    def __str__(self) -> str:
        return self.text
# Create your models here.
