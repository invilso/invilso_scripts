from categoryes.serializer import CategorySerializer, SubcategorySerializer
from categoryes.models import Category, Subcategory
from rest_framework import permissions
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView


class CategoryesView(ListCreateAPIView):
    queryset = Category.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = CategorySerializer


class CategoryView(RetrieveUpdateDestroyAPIView):
    queryset = Category.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = CategorySerializer

class SubcategoryesView(ListCreateAPIView):
    queryset = Subcategory.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = SubcategorySerializer


class SubcategoryView(RetrieveUpdateDestroyAPIView):
    queryset = Subcategory.objects.all()
    permission_classes = [permissions.DjangoModelPermissionsOrAnonReadOnly]
    serializer_class = SubcategorySerializer