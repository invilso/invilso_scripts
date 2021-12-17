from django.urls import path
from categoryes.views import CategoryesAPIView, CategoryAPIView,  SubcategoryesAPIView, SubcategoryAPIView, CategoryView

app_name = "categoryes"
# app_name will help us do a reverse look-up latter.

urlpatterns = [
    path('api/categoryes', CategoryesAPIView.as_view()),
    path('api/category/<int:pk>', CategoryAPIView.as_view()),
    path('api/subcategoryes', SubcategoryesAPIView.as_view()),
    path('api/subcategory/<int:pk>', SubcategoryAPIView.as_view()),
    path('<int:pk>', CategoryView.as_view()),
]