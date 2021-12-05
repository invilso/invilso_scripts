from django.db import models
from django.contrib.auth.models import User

class Message(models.Model):
    text = models.TextField(max_length=2000)
    timestamp = models.DateTimeField(auto_now_add=True)
    receiver = models.ForeignKey(User, blank=True, null=True, on_delete=models.CASCADE, related_name='receiver')
    sender = models.ForeignKey(User, blank=True, null=True,  on_delete=models.SET_NULL)
# Create your models here.
