from django.db import models
from django.contrib.auth.models import User

class File(models.Model):
    file = models.FileField(upload_to='files/%Y/%m/%d/', max_length=250)
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    def __str__(self) -> str:
        return self.file
# Create your models here.
