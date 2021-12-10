from django.db import models
from django.contrib.auth.models import User
from django.db.models.fields.related import ManyToManyField

class Message(models.Model):
    text = models.TextField(max_length=2000)
    timestamp = models.DateTimeField(auto_now_add=True)
    replied = models.ForeignKey('Message', blank=True, null=True, on_delete=models.SET_NULL)
    sender = models.ForeignKey(User, blank=True, null=True, on_delete=models.SET_NULL)
    def __str__(self) -> str:
        return self.text

class Dialog(models.Model):
    name = models.CharField(max_length=150, null=True, blank=True)
    members = ManyToManyField(User, related_name='members')
    messages = ManyToManyField(Message)
    is_active = models.BooleanField(default=True)
    is_private = models.BooleanField()
    def __str__(self) -> str:
        if self.name:
            return self.name
        else:
            return str(self.id)