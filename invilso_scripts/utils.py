import requests
from django.conf import settings

def get_user_ip(request):
    forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    return forwarded_for.split(',')[-1].strip() if forwarded_for else request.META.get('REMOTE_ADDR')

def is_human(request):
    token = request.POST.get('cf-turnstile-response')
    ip = get_user_ip(request)
    
    # Валидация токена, вызов API "/siteverify"
    data = {
        'secret': settings.CLOUDFLARE_SECRET_KEY,  # Замените на ваш секретный ключ Cloudflare
        'response': token,
        'remoteip': ip,
    }
    response = requests.post('https://challenges.cloudflare.com/turnstile/v0/siteverify', data=data)
    outcome = response.json()
    return outcome['success']