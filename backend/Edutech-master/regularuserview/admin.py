from django.contrib import admin

from .models import UserProfile, UserResponse, PurchasedDate

admin.site.register(UserProfile)
admin.site.register(UserResponse)
admin.site.register(PurchasedDate)