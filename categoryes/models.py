from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    name = models.CharField(max_length=150)
    owner = models.ForeignKey(User, blank=True, null=True, on_delete=models.SET_NULL)
    def __str__(self) -> str:
        return self.name

class Subcategory(models.Model):
    name = models.CharField(max_length=150)
    parent = models.ManyToManyField(Category)
    owner = models.ForeignKey(User, blank=True, null=True, on_delete=models.SET_NULL)
    def __str__(self) -> str:
        return self.name
# Create your models here.
