from django.db import models
from photos.models import Photo
from categoryes.models import Category, Subcategory
from files.models import File
from comments.models import Comment
from django.contrib.auth.models import User

class View(models.Model):
    ip = models.CharField(null=True, blank=True, max_length=17)
    date = models.DateField(auto_now_add=True)
    country = models.CharField(null=True, blank=True, max_length=35)
    region_name = models.CharField(null=True, blank=True, max_length=45)
    city = models.CharField(null=True, blank=True, max_length=35)
    isp = models.CharField(null=True, blank=True, max_length=85)
    mobile = models.BooleanField(blank=True, null=True)

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
    comments = models.ManyToManyField(Comment)
    file = models.ManyToManyField(File)
    moderated = models.BooleanField(default=False)
    views = models.ManyToManyField(View)
    def __str__(self) -> str:
        return f'{self.pk} | {self.title} | {self.owner}'