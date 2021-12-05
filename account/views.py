from django.shortcuts import render
from account.serializer import UserSerializer
from django.contrib.auth.models import User
from rest_framework import permissions
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView


class UsersView(ListCreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    serializer_class = UserSerializer


class UserView(RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'username'
    serializer_class = UserSerializer