from django.urls import path
from rest_framework.urlpatterns import format_suffix_patterns
from . import views

""" def information_list(request, *args, **kwargs):
    # Add a print statement to see the request object
    print(f"Request received: {request}")
    
    # Call the original view function
    return views.InformationList.as_view()(request, *args, **kwargs) """

urlpatterns = [
    path('users/', views.UserList.as_view()),
    path('users/<int:pk>/', views.UserDetail.as_view()),
    path('create-user/', views.CreateUserView.as_view()),
    path('update-user/<str:username>/', views.UpdateUserView.as_view()),
    path('delete-user/<str:username>/', views.DeleteUserView.as_view()),
    path("information/", views.InformationList.as_view()),
    path("information/<int:pk>", views.InformationDetail.as_view()),
    path("information/randomPassword/", views.RandomPasswordView.as_view()),
]

urlpatterns = format_suffix_patterns(urlpatterns)