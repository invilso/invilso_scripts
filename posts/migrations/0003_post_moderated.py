# Generated by Django 3.2.7 on 2021-12-15 18:29

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0002_auto_20211212_1405'),
    ]

    operations = [
        migrations.AddField(
            model_name='post',
            name='moderated',
            field=models.BooleanField(default=False),
        ),
    ]
