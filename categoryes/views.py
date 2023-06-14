from categoryes.serializer import CategorySerializer, SubcategorySerializer
from categoryes.models import Category, Subcategory
from rest_framework import permissions
from django.views.generic.list import ListView
from django.shortcuts import render
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from categoryes.services.get import getCategoryPosts, getCategory, getSearchPosts
from django.utils.datastructures import MultiValueDictKeyError
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger


class CategoryesAPIView(ListCreateAPIView):
    queryset = Category.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = CategorySerializer


class CategoryAPIView(RetrieveUpdateDestroyAPIView):
    queryset = Category.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = CategorySerializer

class SubcategoryesAPIView(ListCreateAPIView):
    queryset = Subcategory.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = SubcategorySerializer


class SubcategoryAPIView(RetrieveUpdateDestroyAPIView):
    queryset = Subcategory.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = SubcategorySerializer

class CategoryView(ListView):
    def get(self, request, **kwargs): 
        try:
            posts = getCategoryPosts(kwargs['pk'], request.GET['search'])
        except MultiValueDictKeyError:
            posts = getCategoryPosts(kwargs['pk'], '')
        category = getCategory(kwargs['pk'])
        
        paginator = Paginator(posts, 5) ##posts in page
        page_number = request.GET.get('page')
        page_obj = paginator.get_page(page_number)
        return render(request, 'categoryes/main.html', {"posts": page_obj, 'category': category})