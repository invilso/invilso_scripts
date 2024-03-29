# Generated by Django 4.2.1 on 2023-07-07 19:08

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('posts', '0004_post_text_en_post_text_ru_post_text_uk_post_title_en_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='View',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('ip', models.CharField(blank=True, max_length=17, null=True)),
                ('date', models.DateField(auto_now_add=True)),
                ('country', models.CharField(blank=True, max_length=35, null=True)),
                ('region_name', models.CharField(blank=True, max_length=45, null=True)),
                ('city', models.CharField(blank=True, max_length=35, null=True)),
                ('isp', models.CharField(blank=True, max_length=85, null=True)),
                ('mobile', models.BooleanField(blank=True, null=True)),
            ],
        ),
        migrations.AddField(
            model_name='post',
            name='views',
            field=models.ManyToManyField(to='posts.view'),
        ),
    ]
