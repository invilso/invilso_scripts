from django.contrib import admin
from .models import Post
from django.db import models
from modeltranslation.admin import TranslationAdmin
from ckeditor.widgets import CKEditorWidget

class PostAdmin(TranslationAdmin):
    formfield_overrides = {
        models.TextField: {'widget': CKEditorWidget}
    }

admin.site.register(Post, PostAdmin)
