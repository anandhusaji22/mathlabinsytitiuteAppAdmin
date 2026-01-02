from rest_framework import serializers
from .models import UserProfile, UserResponse, PurchasedDate
from user.views import RegularUserModel

class PurchasedDateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PurchasedDate
        fields = ['date_of_purchase','expiration_date', 'order_amount', 'order_payment_id', 'isPaid']


class UserProfileSerializer(serializers.ModelSerializer):
    purchased_courses = serializers.SerializerMethodField()
    purchased_exams = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['purchased_courses', 'purchased_exams']

    def get_purchased_courses(self, obj):
        purchased_dates = obj.purchased_dates.filter(course__isnull=False, isPaid=True)
        serialized_purchased_courses = []
        for purchased_date in purchased_dates:
            serialized_purchased_courses.append({
                'course_id': purchased_date.course.course_unique_id,
                'date_of_purchase': purchased_date.date_of_purchase,
                'expiration_date': purchased_date.expiration_date,
                'order_id': purchased_date.order_payment_id,
                'amount paid': purchased_date.order_amount,
                'isPaid': purchased_date.isPaid
            })
        return serialized_purchased_courses

    def get_purchased_exams(self, obj):
        purchased_dates = obj.purchased_dates.filter(exam__isnull=False, isPaid=True)
        serialized_purchased_exams = []
        for purchased_date in purchased_dates:
            serialized_purchased_exams.append({
                'exam_id': purchased_date.exam.exam_unique_id,
                'date_of_purchase': purchased_date.date_of_purchase,
                'expiration_date': purchased_date.expiration_date,
                'order_id': purchased_date.order_payment_id,
                'amount paid': purchased_date.order_amount,
                'isPaid': purchased_date.isPaid
            })
        return serialized_purchased_exams


class UserResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserResponse
        fields = ['exam_id','exam_name','response','qualify_score','time_taken','marks_scored', 'total_scored']

    
class GetAllUserResponseSerializer(serializers.ModelSerializer):
    #code to include username and name.
    username = serializers.CharField(source='user.username', read_only=True)
    name = serializers.CharField(source = 'user.name', read_only = True)
    class Meta:
        model = UserResponse
        fields = ['name','username','exam_id','exam_name','response','qualify_score','time_taken','marks_scored', 'total_scored']


class DurationSerializer(serializers.Serializer):
    duration = serializers.IntegerField(min_value = 1, help_text="Enter duration in Months")


class CustomGetUserListSerializer(serializers.ModelSerializer):
    count_of_courses_purchased = serializers.SerializerMethodField()
    count_of_exams_purchased = serializers.SerializerMethodField()
    
    class Meta:
        model = RegularUserModel
        fields = [ 'name', 'username', 'phone_number','count_of_exams_purchased', 'count_of_courses_purchased','is_active']
    
    def get_count_of_courses_purchased(self, obj):
        user_profile = getattr(obj, 'user_profile', None)
        if user_profile:
            return obj.user_profile.purchased_courses.count()
        return 0

    def get_count_of_exams_purchased(self, obj):
        user_profile = getattr(obj, 'user_profile', None)
        if user_profile:
            return obj.user_profile.purchased_exams.count()
        return 0