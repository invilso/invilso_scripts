# Generated by Django 3.2.7 on 2021-12-03 21:06

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0002_alter_post_text'),
        ('comments', '0002_alter_comment_text'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='comment',
            name='post',
        ),
        migrations.AddField(
            model_name='comment',
            name='post',
            field=models.ManyToManyField(to='posts.Post'),
        ),
    ]