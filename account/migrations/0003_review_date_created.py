# Generated by Django 4.2.1 on 2023-07-07 10:11

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('account', '0002_review_reviewreply_profile_reviews'),
    ]

    operations = [
        migrations.AddField(
            model_name='review',
            name='date_created',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
    ]