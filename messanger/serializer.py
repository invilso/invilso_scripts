from rest_framework import serializers

class ProfileImageSerializer(serializers.Serializer):
    file = serializers.ImageField()

class ProfileSerializer(serializers.Serializer):
    photo = ProfileImageSerializer()

class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField(max_length=100)
    profile = ProfileSerializer()

class MessageSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    text = serializers.CharField(max_length=2000)
    sender = UserSerializer()
    timestamp = serializers.DateTimeField()
    receiver = UserSerializer()





