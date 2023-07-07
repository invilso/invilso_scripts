from datetime import date, timedelta
from django.shortcuts import redirect, render

# Create your views here.
from django.shortcuts import render
from django.views.generic.list import ListView
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
import requests
from invilso_scripts.utils import get_user_ip
from posts.models import Post, View
from posts.services.get import getPost
from django.db.models import Count
import plotly.graph_objects as go
import json
import logging
logger = logging.getLogger(__name__)


@method_decorator(csrf_exempt, name='dispatch')
class PostCreateAPI(ListView): #todo
    def post(self, request):
        return JsonResponse({})


class PostCreate(ListView): #todo
    def get(self, request): 
        return render(request, 'posts/create.html')


class PostView(ListView):
    def get(self, request, **kwargs): 
        post = getPost(kwargs['pk'])
        
        if 'viewed_posts' not in request.session:
            request.session['viewed_posts'] = []
        
        # Проверяем, просматривалась ли вакансия ранее
        if kwargs['pk'] not in request.session['viewed_posts']:
            user_ip = get_user_ip(request)
            if user_ip != '127.0.0.1':
                resp = requests.get(f'http://ip-api.com/json/{user_ip}?fields=status,message,country,regionName,city,isp,mobile,query').text
                data: dict = json.loads(resp)
            else:
                data: dict = {}
            view = View(
                ip=user_ip,
                country = data.get('country'),
                region_name = data.get('regionName'),
                city = data.get('city'),
                isp = data.get('isp'),
                mobile = data.get('mobile'),
                )
            view.save()
            post.views.add(view)
            post.save()
            
            # Добавляем идентификатор вакансии в список просмотренных в сессии
            request.session['viewed_posts'].append(kwargs['pk'])
        
        return render(request, 'posts/main.html', {"post": post})
    
class Graph(ListView):
    def get(self, request, **kwargs): 
        if not request.user.is_staff:
            return redirect('main:main')
        end_date = date.today()  # Текущая дата
        start_date = end_date - timedelta(days=30)  # Дата 30 дней назад
        
        # Агрегация просмотров по дате
        post = getPost(kwargs['pk'])
        views_by_date = post.views.all().filter(date__range=(start_date, end_date)).values('date').annotate(view_count=Count('id')).order_by('date')

        # Извлечение данных просмотров
        date_list = [view['date'] for view in views_by_date]
        view_count_list = [view['view_count'] for view in views_by_date]

        # Создание графика
        fig = go.Figure(data=go.Scatter(x=date_list, y=view_count_list, mode='lines+markers'))

        fig.update_layout(
            title='График просмотров по дате (за последние 30 дней)',
            xaxis_title='Дата',
            yaxis_title='Просмотры',
        )

        plot_div = fig.to_html(full_html=False, default_height=500)
        return render(request, 'posts/graph.html', {'plot_div': plot_div, 'post': post})