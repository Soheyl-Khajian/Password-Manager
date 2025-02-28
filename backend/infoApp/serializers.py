from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Information

class InformationSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.username')

    class Meta:
        model = Information
        fields = ('id', 'userName', 'password', 'website', 'owner')

    def create(self, validated_data):
        client_password = self.context['request'].META.get('HTTP_ENCRYPTION_PASSWORD')
        instance = Information(**validated_data)
        instance.save(client_password=client_password)
        return instance   
    
    def update(self, instance, validated_data):
        client_password = self.context['request'].META.get('HTTP_ENCRYPTION_PASSWORD')
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save(client_password=client_password)
        return instance

    def to_representation(self, instance):
        client_password = self.context['request'].META.get('HTTP_ENCRYPTION_PASSWORD')
        info = Information.get_information(id=instance.id, client_password=client_password)
        if info is not None:
            return super().to_representation(info)
        else:
            # handle the case where the instance does not exist
            raise serializers.ValidationError(f"Information with id {instance.id} does not exist.")   
        
class UserSerializer(serializers.ModelSerializer):
    information = serializers.PrimaryKeyRelatedField(many=True, queryset=Information.objects.all())

    class Meta:
        model = User
        fields = ['id', 'username','password', 'email', 'information']

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user    