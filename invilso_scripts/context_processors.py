# myapp/context_processors.py

from django.conf import settings
from categoryes.models import Category

def categories(request):
    categories = Category.objects.all()
    return {'categories': categories}

def cf_site_key(request):
    return {'cf_site_key': settings.CLOUDFLARE_SITE_KEY}
