from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('debug', views.debug, name='debug'),
    path('readfile', views.readfile, name='readfile'),
    path('viewLog', views.viewLog, name='viewLog')
]