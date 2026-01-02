from django.contrib import admin
from .models import RegularUserModel, FieldOfStudy, Subjects, Modules, NotesNested, videosNested,Access_type, SliderImage, PopularCourses
from .models import Otp, AbstractOtp

# Register your models here.

admin.site.register(RegularUserModel)
admin.site.register(FieldOfStudy)
admin.site.register(Subjects)
admin.site.register(Modules)
admin.site.register(NotesNested)
admin.site.register(videosNested)
admin.site.register(Access_type)
admin.site.register(SliderImage)
admin.site.register(PopularCourses)
admin.site.register(Otp)
admin.site.register(AbstractOtp)
