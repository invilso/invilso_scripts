from rest_framework import serializers


class ProfileImageSerializer(serializers.Serializer):
    file = serializers.ImageField()
 
 
class ProfileSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    description = serializers.CharField()
    location = serializers.CharField()
    birth_date = serializers.DateField()
    photo = ProfileImageSerializer()


class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField(max_length=100)
    is_staff = serializers.BooleanField()
    is_active = serializers.BooleanField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    date_joined = serializers.DateTimeField()
    profile = ProfileSerializer()




