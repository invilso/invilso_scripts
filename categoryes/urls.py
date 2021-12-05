from django.urls import path
from categoryes.views import CategoryesView, CategoryView, SubcategoryesView, SubcategoryView

app_name = "categoryes"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/categoryes', CategoryesView.as_view()),
    path('api/category/int:pk>', CategoryView.as_view()),
    path('api/subcategoryes', SubcategoryesView.as_view()),
    path('api/subcategory/int:pk>', SubcategoryView.as_view()),
]