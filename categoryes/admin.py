from django.contrib import admin
from .models import Category, Subcategory
from modeltranslation.admin import TranslationAdmin

class CategoryAdmin(TranslationAdmin):
    pass

admin.site.register(Category, CategoryAdmin)

class SubcategoryAdmin(TranslationAdmin):
    pass

admin.site.register(Subcategory, SubcategoryAdmin)
