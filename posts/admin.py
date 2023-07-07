from django.contrib import admin
from .models import Post, View
from django.db import models
from modeltranslation.admin import TranslationAdmin
from ckeditor.widgets import CKEditorWidget

class PostAdmin(TranslationAdmin):
    formfield_overrides = {
        models.TextField: {'widget': CKEditorWidget}
    }
admin.site.register(Post, PostAdmin)

class ViewAdmin(admin.ModelAdmin):
    list_display = ('id', 'ip', 'date', 'country', 'region_name', 'city', 'isp', 'mobile')
    list_filter = ('date', 'country', 'region_name', 'city', 'isp', 'mobile')
    search_fields = ('ip', 'country', 'region_name', 'city', 'isp')
admin.site.register(View, ViewAdmin)
