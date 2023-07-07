from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from photos.models import Photo
from django.db.models.signals import post_save
from django.dispatch import receiver

def validate_rating(value):
    if value < 1 or value > 5:
        raise ValidationError("The value should be between 1 and 5.")

class Review(models.Model):
    name = models.CharField(max_length=60)
    task_description = models.CharField(max_length=60)
    review = models.TextField(blank=True)
    quality_of_service = models.PositiveIntegerField(default=3, validators=[validate_rating])
    adherence_to_deadlines = models.PositiveIntegerField(default=3, validators=[validate_rating])
    communication_responsiveness = models.PositiveIntegerField(default=3, validators=[validate_rating])
    price_value_ratio = models.PositiveIntegerField(default=3, validators=[validate_rating])
    overall_satisfaction = models.PositiveIntegerField(default=3, validators=[validate_rating])
    rating = models.IntegerField()
    active = models.BooleanField(default=True)
    date_created = models.DateTimeField(auto_now_add=True)
    
    def __str__(self) -> str:
        return f'{self.name} - {self.task_description}'
    
    def get_average_rating(self):
        # calculate the average of all rating fields
        fields = [self.quality_of_service, self.adherence_to_deadlines, self.communication_responsiveness, self.price_value_ratio, self.overall_satisfaction]
        average = sum(fields) / len(fields)
        # return the percentage as a string with a star symbol
        return average
    
class ReviewReply(models.Model):
    review = models.OneToOneField(Review, on_delete=models.CASCADE)
    text = models.TextField()

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    description = models.TextField(max_length=500, blank=True)
    location = models.CharField(max_length=30, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    photo = models.ForeignKey(Photo, on_delete=models.SET_NULL, null=True, blank=True)
    reviews = models.ManyToManyField(Review, blank=True)
    def __str__(self) -> str:
        return self.user.username
    
    


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()
# Create your models here.
