from django.db import models
from photos.models import Photo
from categoryes.models import Category, Subcategory
from files.models import File
from django.contrib.auth.models import User

# Create your models here.
class Post(models.Model):
    title = models.CharField(max_length=250)
    text = models.TextField(max_length=20000)
    timestamp = models.DateTimeField(auto_now_add=True)
    photo = models.ForeignKey(Photo, on_delete=models.SET_NULL, null=True, blank = True)
    price = models.IntegerField()
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    subcategoryes = models.ManyToManyField(Subcategory)
    file = models.ForeignKey(File, on_delete=models.SET_NULL, null=True, blank = True)
    def __str__(self) -> str:
        return self.title