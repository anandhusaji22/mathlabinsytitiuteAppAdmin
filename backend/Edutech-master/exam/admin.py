from django.contrib import admin
from .models import Exam, MultipleChoice, Numericals, QuestionType
from .models import  MultiSelect, Options
# Register your models here.
admin.site.register(Exam)
admin.site.register(MultipleChoice)
admin.site.register(MultiSelect)
admin.site.register(Options)
admin.site.register(Numericals)
admin.site.register(QuestionType)