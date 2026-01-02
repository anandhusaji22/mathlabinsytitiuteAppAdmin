from rest_framework import serializers
from .models import RegularUserModel
from django.contrib.auth import get_user_model
from .models import (FieldOfStudy,Subjects, Modules, 
                    Access_type, NotesNested, videosNested, 
                    SliderImage, PopularCourses)
from regularuserview.serializer import (UserProfileSerializer, UserResponseSerializer)


RegularUserModel = get_user_model()
# PopularCourses
#validate data of regular user Registration.
class RegularUserSerializer(serializers.ModelSerializer):
    password = serializers.RegexField(
        regex=r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        max_length=128,
        min_length=8,
        write_only=True,
        error_messages={
            'invalid': 'Password must contain at least 8 characters, including uppercase, lowercase, and numeric characters.'
        }
    )

    count_of_courses_purchased = serializers.SerializerMethodField()
    count_of_exams_purchased = serializers.SerializerMethodField()
    confirm_password = serializers.CharField(write_only=True)
    purchase_list = UserProfileSerializer(source='user_profile', read_only=True)  # Update the source here
    exam_response = UserResponseSerializer(read_only=True)

    class Meta:
        model = RegularUserModel
        fields = ['id', 'name', 'username', 'phone_number', 'password', 'confirm_password', 'date_joined', 'last_login', 'is_active', 'verified','count_of_courses_purchased','count_of_exams_purchased','purchase_list', 'exam_response']
        default_related_name = 'regular_users'

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

    def to_representation(self, instance):
        # Include the logged-in user's exam responses in the representation
        representation = super().to_representation(instance)
        user_responses = instance.userresponse.all()
        exam_response_serializer = UserResponseSerializer(user_responses, many=True)
        representation['exam_response'] = exam_response_serializer.data
        return representation

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Password mismatch')
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = RegularUserModel.objects.create_user(
            name=validated_data['name'],
            username=validated_data['username'],
            phone_number=validated_data['phone_number'],
            password=validated_data['password']
        )
        return user


#validate data of regular user login.
class RegularUserLoginSerializer(serializers.Serializer):
    username = serializers.EmailField()
    password = serializers.CharField(max_length=128)

#validate data for admin creation.
class AdminRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.RegexField(
        regex=r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        max_length=128,
        min_length=8,
        write_only=True,
        error_messages={
            'invalid': 'Password must contain at least 8 characters, including uppercase, lowercase, and numeric characters.'
        }
    )
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = RegularUserModel
        fields = ['name', 'username', 'phone_number','password', 'confirm_password']
        default_related_name = 'admin_users'

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Password mismatch')
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = RegularUserModel.objects.create_superuser(
            username=validated_data['username'],
            password=validated_data['password'],
            name=validated_data['name'],
            phone_number=validated_data['phone_number'],
        )
        return user

#validate data for admin login.
class AdminLoginSerializer(serializers.Serializer):
    username = serializers.EmailField()
    password = serializers.CharField(max_length=128)

# #validate teacher data
# class TeachersSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Teachers
#         fields = ['id', 'teachers','slug_teachers','is_active', 'created_date', 'updated_date']


#validates Notes nested inside Modules.
class NotesNestedSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotesNested
        fields = ['notes_id','module','access_type','title','description','pdf','created_date','updated_date','slug_notes','is_active']

#validates Videos nested inside Modules.
class VideoNestedSerializer(serializers.ModelSerializer):
    class Meta:
        model = videosNested
        fields = ['video_unique_id','module','access_type','video_id','title','description','created_date','updated_date','slug_videos','is_active']

#validate modules data
class ModuleSerializer(serializers.ModelSerializer):
    contents_count = serializers.SerializerMethodField()
    notes = serializers.StringRelatedField(many=True)
    videos = serializers.StringRelatedField(many=True)
    exams = serializers.StringRelatedField(many=True)
    class Meta:
        model = Modules
        fields = ['modules_id', 'subjects','module_name', 'contents_count', 'notes', 'videos', 'exams','slug_modules','is_active', 'created_date', 'updated_date']
    
    def get_contents_count(self, obj):
        return (obj.notes.count()+obj.videos.count()+obj.exams.count())

#validates subjects data
class SubjectSerializer(serializers.ModelSerializer):
    modules_count = serializers.SerializerMethodField()
    modules = serializers.StringRelatedField(many=True)
    class Meta:
        model = Subjects
        fields = ['subject_id','field_of_study','subjects','subject_image', 'modules_count','modules','slug_subjects','direct_slug','is_active', 'created_date', 'updated_date']
    
    def get_modules_count(self, obj):
        return obj.modules.count()

#validates Field of study data
class FieldOfStudySerializer(serializers.ModelSerializer):
    subjects_count = serializers.SerializerMethodField()
    subjects = serializers.StringRelatedField(many=True)
    class Meta:
        model = FieldOfStudy
        fields = ['course_unique_id','field_of_study', 'course_image','cover_image','price', 'Course_description', 'Course_duration','user_benefit','only_paid','subjects_count','subjects','slug_studyfield','is_active', 'created_date', 'updated_date']

    def get_subjects_count(self, obj):
        return obj.subjects.count()


#validates the access types(paid or free)
class Access_type_serializer(serializers.ModelSerializer):
    class Meta:
        model = Access_type
        fields = "__all__"

#validates the uploading images
class SliderImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SliderImage
        fields = ['images_id','images']

# validates the PopularCourses
class PopularCourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = PopularCourses
        fields = ['popular_course_id','course']

# validates the password entered for changing password.
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        fields = ['old_password','new_password', 'confirm_password']

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError('Password mismatch')
        return data

#valildates the email entered for sending otp.
class ResetPasswordEmailSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    class Meta:
        fields = ['email']

# validates the password entered for changing password.
class ResetPasswordSerializer(serializers.Serializer):
    password = serializers.RegexField(
        regex=r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
        max_length=128,
        min_length=8,
        write_only=True,
        error_messages={
            'invalid': 'Password must contain at least 8 characters, including uppercase, lowercase, and numeric characters.'
        }
    )
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        fields = ['password','confirm_password']

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('password mismatch')
        return data
        
#validates if the otp entered is correct.
class CheckOTPSerializer(serializers.Serializer):
    otp = serializers.CharField(min_length = 6, max_length = 6)

class RemainingDatesSerializer(serializers.Serializer):
    name = serializers.CharField(max_length = 300)
    username = serializers.CharField(max_length = 300)
    user_id = serializers.CharField(max_length = 300)
    phone_number = serializers.CharField(max_length = 300)
    course_name = serializers.CharField(max_length = 300, required = False)
    exam_name = serializers.CharField(max_length = 300, required = False)
    no_of_days_to_expire = serializers.IntegerField()
    expired = serializers.BooleanField()
    
    