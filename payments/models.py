from django.db import models

class Order(models.Model):
    amount = models.IntegerField()
    
