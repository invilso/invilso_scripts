from django.db import models
from django.contrib.auth.models import User

class Comment(models.Model):
    text = models.TextField(max_length=2000)
    parent=models.ForeignKey('self', related_name="children", null=True, blank=True, on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)
    rating = models.IntegerField()
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    def __str__(self) -> str:
        return self.owner.username+" || "+self.text
# Create your models here.
