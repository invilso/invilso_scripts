from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    name = models.CharField(max_length=150)
    owner = models.ForeignKey(User, blank=True, null=True, on_delete=models.SET_NULL)
# Create your models here.
