from rest_framework import generics
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from rest_framework import permissions
from infoApp.permissions import IsOwnerOrReadOnly
from rest_framework.authentication import TokenAuthentication
from django.middleware.csrf import get_token
from rest_framework.generics import ListCreateAPIView
from rest_framework.mixins import RetrieveModelMixin

from infoApp.models import Information
from infoApp.serializers import InformationSerializer, UserSerializer
from infoApp.infoApp import generateRandomPassword

class UserList(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class UserDetail(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class CreateUserView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UpdateUserView(generics.UpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    lookup_field = 'username'

class DeleteUserView(generics.DestroyAPIView):
    queryset = User.objects.all()
    lookup_field = 'username'        

class InformationList(ListCreateAPIView, RetrieveModelMixin):
    serializer_class = InformationSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    authentication_classes = [TokenAuthentication]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return Information.objects.filter(owner=self.request.user)
        else:
            return Information.objects.none()

    def perform_create(self, serializer):
        # client_password = self.request.META.get('HTTP_ENCRYPTION_PASSWORD')
        print(f"Request data: {self.request.data}")

        # Set the owner to the authenticated user
        serializer.save(owner=self.request.user)

    def create(self, request, *args, **kwargs):
        # csrf_token = get_token(request)
        # print("csrf token: " + csrf_token)
        print("Request body:", request.body)
        print("Request headers:", request.headers)

        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            response = Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

            # Add a print statement to print out the response object
            print(f"Response: {response}")

            return response
        else:
            # Add a print statement to see the validation errors
            print(f"Validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)   

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def list(self, request):
        # Add debug statements to print the request.session object
        #print(request.session)

        # Get the CSRF token from the request
        csrf_token = get_token(request)

        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)

        # For each instance in the serializer, set the client_password
        for instance in serializer.instance:
            instance.client_password = request.META.get('HTTP_ENCRYPTION_PASSWORD')

        response = Response(serializer.data)
        response['X-CSRF-TOKEN'] = csrf_token

        return response


class InformationDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Information.objects.all()
    serializer_class = InformationSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class RandomPasswordView(generics.GenericAPIView):
    authentication_classes = [TokenAuthentication]

    def get(self, request):
        rndmPss = generateRandomPassword()
        # send the password to the user's client
        return Response(rndmPss, status=status.HTTP_200_OK)    