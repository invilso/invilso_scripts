# myapp/context_processors.py

from categoryes.models import Category

def categories(request):
    # Получаем все категории
    categories = Category.objects.all()
    
    # Возвращаем словарь с добавленными категориями
    return {'categories': categories}
