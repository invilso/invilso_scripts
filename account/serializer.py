from rest_framework import serializers


class ImageOwnerSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField(max_length=100)


class ProfileImageSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    file = serializers.ImageField()
    owner = ImageOwnerSerializer()
 
 
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




