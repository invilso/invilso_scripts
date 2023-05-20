from modeltranslation.translator import translator, TranslationOptions
from .models import Category, Subcategory

class CategoryTranslationOptions(TranslationOptions):
    fields = ('name',)

translator.register(Category, CategoryTranslationOptions)

class SubcategoryTranslationOptions(TranslationOptions):
    fields = ('name',)

translator.register(Subcategory, SubcategoryTranslationOptions)