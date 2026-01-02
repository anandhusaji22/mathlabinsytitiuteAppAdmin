from django.db import models
from user.models import RegularUserModel, FieldOfStudy
from exam.models import Exam
from django.utils import timezone

class UserProfile(models.Model):
    user = models.OneToOneField(RegularUserModel, on_delete=models.CASCADE, related_name='user_profile', null=True, blank=True)
    purchased_courses = models.ManyToManyField(FieldOfStudy, blank=True, related_name='purchased_profiles')
    purchased_exams = models.ManyToManyField(Exam, blank=True, related_name='purchased_profiles')

    def __str__(self) -> str:
        return f"{self.user}"


class PurchasedDate(models.Model):
    user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='purchased_dates')
    course = models.ForeignKey(FieldOfStudy, on_delete=models.CASCADE, related_name='purchased_dates', null=True, blank=True)
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='purchased_dates', null=True, blank=True)
    date_of_purchase = models.DateTimeField(default=timezone.now)
    expiration_date = models.DateTimeField()
    order_amount = models.DecimalField(max_digits=6, decimal_places=2, default=100)
    order_payment_id = models.CharField(max_length=100, default='0000')
    isPaid = models.BooleanField(default=False, blank=True, null=True)

    def __str__(self) -> str:
        return f"PurchasedDate for {self.user_profile} - payment id {self.order_payment_id}"


# class PurchasedCourse(models.Model):
#     user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
#     course = models.ManyToManyField(FieldOfStudy, blank=True)
#     date_of_purchase = models.DateTimeField(default=timezone.now)

class UserResponse(models.Model):
    user = models.ForeignKey(RegularUserModel, on_delete=models.CASCADE, related_name='userresponse')
    exam_id = models.CharField(max_length=50)
    exam_name = models.TextField(default='test-1')
    response = models.JSONField(default=dict)
    qualify_score = models.PositiveIntegerField(default=0)
    time_taken = models.CharField(max_length=30, default="00:00:00")
    marks_scored = models.CharField(max_length=50, default='00')
    total_scored = models.CharField(max_length=500, default='00')

    #  {
    # "1": "A",
    # "2": "C",
    # "3": "B"
    # }
    def __str__(self) -> str:
        return f"{self.user.username}-{self.exam_id}"
