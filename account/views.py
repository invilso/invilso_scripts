from django.shortcuts import render
from django.views.generic.list import ListView
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

class ProfileView(ListView):
    def get(self, request, username):
        try:
            acc = User.objects.get(username=username)
            return render(request, 'account/view.html', {'account':acc})
        except:
            acc = User.objects.get(username='invilso')
            return render(request, 'account/view.html', {'account':acc})