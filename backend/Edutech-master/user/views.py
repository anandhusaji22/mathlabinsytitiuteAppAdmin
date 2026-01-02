from django.contrib.sessions.models import Session
from django.utils import timezone
from django.contrib.auth import update_session_auth_hash
from django.contrib.auth import authenticate, login, logout
#import within app
from .models import (Access_type,FieldOfStudy, Subjects, Modules,
                     videosNested, NotesNested, RegularUserModel,
                     SliderImage, PopularCourses, Otp, AbstractOtp)
from .serializers import (RegularUserSerializer,RegularUserLoginSerializer,AdminLoginSerializer, 
                        AdminRegistrationSerializer,Access_type_serializer,FieldOfStudySerializer,
                        ModuleSerializer,SubjectSerializer,VideoNestedSerializer, 
                        NotesNestedSerializer, ChangePasswordSerializer,ResetPasswordSerializer,
                        CheckOTPSerializer, ResetPasswordEmailSerializer, SliderImageSerializer,
                        PopularCourseSerializer, RemainingDatesSerializer)
#import from other apps.
from exam.serializer import ExamSerializer
from exam.models import Exam
from regularuserview.models import UserProfile, PurchasedDate
from regularuserview.serializer import DurationSerializer
from rest_framework import viewsets
from rest_framework.authtoken.models import Token
from rest_framework.generics import (CreateAPIView, ListCreateAPIView, RetrieveUpdateDestroyAPIView,
                                     ListAPIView,RetrieveUpdateDestroyAPIView, GenericAPIView)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAdminUser
from rest_framework import status
import pandas as pd
import logging
from .utils import notification
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

logger = logging.getLogger(__name__)
#custom created functions
from .utils import (otpgenerator, checkOTP, Utils,
                    send_otp, verify_otp)


#user registration view
class RegularUserRegisterationView(viewsets.ModelViewSet):
    queryset = RegularUserModel.objects.all()
    serializer_class = RegularUserSerializer

    def create(self, request):
        serializer = self.serializer_class(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        try:
            phone_number = serializer.validated_data.get('phone_number')
            otp_session_id, otp = send_otp(phone=phone_number)
            user = serializer.save()
            user.otp_session_id = otp_session_id
            user.verified = False
            user.save()
            print(otp_session_id, otp)
            response = {
                'data': serializer.data,
                'message': 'User created successfully',
                'status': status.HTTP_201_CREATED
            }
            return Response(response, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PhoneVerificationForExistingUsers(APIView):
    def post(self, request):
        try:
            phone = request.data.get('phone')
            if phone:
                user = RegularUserModel.objects.filter(phone_number__iexact=phone)
                if user.exists():
                    user = user.first()
                    otp_session_id, otp = send_otp(phone=phone)
                    user.otp_session_id = otp_session_id
                    user.verified = False
                    user.save()
                    response = {
                    'message': 'OTP Sent successfully',
                    }
                    return Response(response, status=status.HTTP_200_OK)
                else:
                    return Response({'message': 'User does not exist. Please Register'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({'message': 'Phone is missing'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(e)
            return Response({
                'status': False,
                'message': str(e),
                'details': 'Login Failed'
            })


# verify otp
class VerifyPhoneOTPView(APIView):
    def post(self, request, format=None):
        try:
            phone = request.data.get('phone')
            otp = request.data.get('otp')
            print(phone, otp)
            if phone and otp:
                user = RegularUserModel.objects.filter(phone_number__iexact=phone)
                if user.exists():
                    user = user.first()
                    token, created = Token.objects.get_or_create(user=user)
                    otp_session_id = user.otp_session_id
                    result = verify_otp(otp_session_id=otp_session_id, otp=otp)
                    if result == "OTP Matched":
                        user.verified = True
                        user.save()
                        return Response({
                            'status': True,
                            'details': 'Login Successfully',
                            'token': token.key,
                            'response': {
                                'id': user.pk,
                                'name': user.name,
                                'email': user.username,
                                'phone': user.phone_number,
                            }})
                    else:
                        return Response({'message': 'OTP does not match'}, status=status.HTTP_400_BAD_REQUEST)
                else:
                    return Response({'message': 'User does not exist'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({'message': 'Phone or OTP is missing'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(e)
            return Response({
                'status': False,
                'message': str(e),
                'details': 'Login Failed'
            })
        

#view to handle excel file for user registration.
class UserRegistrationThroughExcel(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        file = request.FILES['file']
        df = pd.read_excel(file)

        success_users = []
        errors = []

        for index, row in df.iterrows():
            serializer = RegularUserSerializer(data=row.to_dict())
            if serializer.is_valid():
                serializer.save()
                success_users.append(serializer.data)
            else:
                errors.append({
                    'row_number': index + 2,  # Excel rows are 1-indexed, Python is 0-indexed
                    'errors': serializer.errors
                })

        if errors:
            return Response({'errors': errors}, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({'success_users': success_users}, status=status.HTTP_201_CREATED)


#Regular User login view.
class RegularUserLoginView(APIView):
    serializer_class = RegularUserLoginSerializer

    def post(self, request):
        serializer = RegularUserLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        unverified_user = serializer.data['username']
        try:
            unverified_user = RegularUserModel.objects.get(username = unverified_user)
        except RegularUserModel.DoesNotExist:
            return Response('User Not Found')
        if unverified_user.verified == True:
            user = authenticate(request, username=serializer.data['username'], password=serializer.data['password'])
            if user is not None and not user.is_anonymous:
                # Invalidate all sessions except for the current one
                active_sessions = Session.objects.filter(expire_date__gte=timezone.now())
                for session in active_sessions:
                    session_data = session.get_decoded()
                    if str(user.pk) == session_data.get('_auth_user_id'):
                        Token.objects.filter(user=user).delete()
                        session.delete()
                        return Response('Multiple Login Detected')
                
                login(request, user)
                token, created = Token.objects.get_or_create(user=user)
                response = {'message': 'Login Successful', 'token': token.key}
                return Response(response)
        else:
            response = {'message': 'Verify Phone Number For Login', 'phone_number': unverified_user.phone_number}
            return Response(response)
        return Response('The username or password is incorrect')


#Regular user logout view.
class RegularUserLogoutView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        # Delete the token associated with the user
        Token.objects.filter(user=request.user).delete()
        logout(request)
        response = {'message': 'You have been successfully logged out.'}
        return Response(response)


#Admin Registration view.
class AdminRegistrationView(CreateAPIView):
    serializer_class = AdminRegistrationSerializer


#Admin Login View.
#Authentication using django default authentication system.
class AdminLoginView(APIView):
    serializer_class = AdminLoginSerializer
    def post(self, request):
        serializer = AdminLoginSerializer(data = request.data)
        serializer.is_valid(raise_exception = True)
        user = authenticate(request, username = serializer.data['username'], password = serializer.data['password'])
        if user is not None and user.is_superuser:
            login(request, user)
            token, created = Token.objects.get_or_create(user=user)
            response = {'message': 'Login Successful','token': token.key}
            return Response(response)
        return Response('The username or password is incorrect')


#Admin Logout View.
#endpoint can only be accessed if the user has authentication permission.
class AdminLogoutView(APIView):
    
    permission_classes = [IsAuthenticated]
    def post(self, request):
        if request.user.is_superuser:
            Token.objects.filter(user=request.user).delete()
            logout(request)
            response = {'message': 'You have been successfully logged out.'}
            return Response(response)
        else:
            return Response("invalid access")


#create access type- (paid, free) view.
class AccessTypeListCreateView(ListCreateAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    queryset = Access_type.objects.all()
    serializer_class = Access_type_serializer


#AccessTypeDetailView
class AccessTypeRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    queryset = Access_type.objects.all()
    serializer_class = Access_type_serializer


#Course Overview view.
class FieldOfStudyListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = FieldOfStudy.objects.prefetch_related('subjects')
    serializer_class = FieldOfStudySerializer


#Course Detailview.
class FieldOfStudyRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = FieldOfStudy.objects.all()
    serializer_class = FieldOfStudySerializer
    lookup_field = "course_unique_id"


#Subjects overview view.
class SubjectsListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = SubjectSerializer
    lookup_field = "course_unique_id"

    def get_queryset(self):
        course_unique_id = self.kwargs['course_unique_id']  #extract all 'course_unique_id'
        field_of_study = FieldOfStudy.objects.get(course_unique_id=course_unique_id) #extract FieldOfStudy objects based on that 'course_unique_id'
        return field_of_study.subjects.all() #extract all subjects associated with that 'study_slugfield'


#Subjects Detailview View.
class SubjectsRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Subjects.objects.all()
    serializer_class = SubjectSerializer
    lookup_field = "subject_id"


#Modules OverView View.
class ModulesListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = ModuleSerializer
    lookup_field = "subject_id"

    def get_queryset(self):
        subject_id = self.kwargs["subject_id"]  #extract all 'slug_subjects'
        subjects = Subjects.objects.get(subject_id = subject_id)  #extract all subjects based on that 'slug_subjects'
        return subjects.modules.all()  #extract all modules based on that 'study_subjects'


#Modules Detailview view.
class ModulesRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Modules.objects.all()
    serializer_class = ModuleSerializer
    lookup_field = "modules_id"


#list and write exams
class ExamsNestedView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permisson_classes = [IsAdminUser]
    serializer_class = ExamSerializer
    lookup_field = "modules_id"

    def get_queryset(self):
        modules_id = self.kwargs["modules_id"] #extract 'slug_modules'
        modules = Modules.objects.get(modules_id = modules_id)   #extract modules based on that 'slug_modules'
        return modules.exams.all()  #extract all exams based on that 'slug_modules'


#Exams inside Modules Detailview
class ExamsNestedRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Exam.objects.all()
    serializer_class = ExamSerializer
    lookup_field = "exam_unique_id"


#list and write videos
class videosNestedView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permisson_classes = [IsAdminUser]
    serializer_class = VideoNestedSerializer
    lookup_field = "modules_id"

    def get_queryset(self):
        modules_id = self.kwargs["modules_id"] #extract 'slug_modules'
        modules = Modules.objects.get(modules_id = modules_id)  #extract modules based on that 'slug_modules'
        return modules.videos.all()   #extract all videos based on that 'slug_modules'


#Videos inside Modules Detailview
class VideosNestedRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = videosNested.objects.all()
    serializer_class = VideoNestedSerializer
    lookup_field = "video_unique_id"


#list and write notes
class NotesNestedView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permisson_classes = [IsAdminUser]
    serializer_class = NotesNestedSerializer
    lookup_field = "modules_id"

    def get_queryset(self):
        modules_id = self.kwargs["modules_id"]  #extract 'slug_modules'
        modules = Modules.objects.get(modules_id = modules_id)  #extract modules based on that 'slug_modules'
        return modules.notes.all()  #extract all notes based on that 'slug_modules'


#Videos inside Modules Detailview
class NotesNestedRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = NotesNested.objects.all()
    serializer_class = NotesNestedSerializer
    lookup_field = "notes_id"


class SliderImageAdd(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = SliderImageSerializer
    queryset = SliderImage.objects.all()
    
    
class SliderImageRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = SliderImageSerializer
    queryset = SliderImage.objects.all()
    lookup_field = "images_id"


class PopularCoursesAdd(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = PopularCourses.objects.all()
    serializer_class = PopularCourseSerializer


class PopularCourseRetrieveUpdateDestroyview(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = PopularCourseSerializer
    queryset = PopularCourses.objects.all()
    lookup_field = "popular_course_id"
    

#view to assign a exam to a user.
class AssignExam(APIView):
    permission_classes = [IsAdminUser]
    def post(self, request):
        #get exam id and username of the user.
        username = request.data.get('username')
        exam = request.data.get('exam_unique_id')
        
        #get associated user and exam
        try:
            exam = Exam.objects.get(exam_unique_id = exam)
            user = RegularUserModel.objects.get(username = username)
        except RegularUserModel.DoesNotExist:
            return Response("User not found", status=status.HTTP_404_NOT_FOUND)
        except Exam.DoesNotExist:
            return Response("Exam not found", status=status.HTTP_404_NOT_FOUND)
                
        duration = int(request.data.get('duration')) #duration in days
        
        date_of_purchase = timezone.now()
        expiration_date = date_of_purchase + timezone.timedelta(days=duration)

        user_profile, created = UserProfile.objects.get_or_create(user = user)

        if exam not in user_profile.purchased_exams.all():
            user_profile.purchased_exams.add(exam)

        # Now, update or create the PurchasedDate record
        purchased_date, created = PurchasedDate.objects.get_or_create(
            user_profile=user_profile,
            exam=exam,
            isPaid = True,
            defaults={'date_of_purchase': timezone.now(),
                      'expiration_date': expiration_date}

        )

        # If the PurchasedDate record already exists, update the expiration date
        if not created:
            purchased_date.expiration_date = expiration_date
            purchased_date.save()

        return Response("Exam purchased successfully", status=status.HTTP_200_OK)


#view to assign a course to a user.
class AssignCourses(APIView):
    permission_classes = [IsAdminUser]
    def post(self, request):
        #get coures_id and username of the user.
        username = request.data.get('username')
        course_id = request.data.get('course_unique_id')
        
        #get associated user and course.
        try:
            course = FieldOfStudy.objects.get(course_unique_id = course_id)
            
            user = RegularUserModel.objects.get(username = username)
        
        except RegularUserModel.DoesNotExist:
            return Response("User not found", status=status.HTTP_404_NOT_FOUND)
        except FieldOfStudy.DoesNotExist:
            return Response("Course not found", status=status.HTTP_404_NOT_FOUND)
                
        duration = int(request.data.get('duration')) #duration in days
        
        date_of_purchase = timezone.now()
        expiration_date = date_of_purchase + timezone.timedelta(days=duration)

        user_profile, created = UserProfile.objects.get_or_create(user = user)

        if course not in user_profile.purchased_courses.all():
            user_profile.purchased_courses.add(course)

        # Now, update or create the PurchasedDate record
        purchased_date, created = PurchasedDate.objects.get_or_create(
            user_profile=user_profile,
            course=course,
            isPaid = True,
            defaults={'date_of_purchase': timezone.now(),
                      'expiration_date': expiration_date}
        )

        # If the PurchasedDate record already exists, update the expiration date
        if not created:
            purchased_date.expiration_date = expiration_date
            purchased_date.save()

        return Response("Course purchased successfully", status=status.HTTP_200_OK)


#view to view all users by admin 
class ViewAllUsers(ListAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    serializer_class = RegularUserSerializer
    queryset = RegularUserModel.objects.all()


#view to view individual user detail by admin
class ViewUserDetial(RetrieveUpdateDestroyAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    serializer_class = RegularUserSerializer
    queryset = RegularUserModel
    lookup_field = 'username'


# view to change password by user
class ChangePasswordView(APIView):
    authentication_classes = [IsAuthenticated]
    serializer_class = ChangePasswordSerializer
    def post(self, request):
        serializer = ChangePasswordSerializer(data = request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if user.check_password(serializer.data['old_password']):
            user.set_password(serializer.data['new_password'])
            user.save()
            update_session_auth_hash(request, user)
            return Response({'message': 'Password changed successfully.'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Incorrect old password.'}, status=status.HTTP_400_BAD_REQUEST)    


#view to Request OTP.
from django.db import transaction

class PasswordResetRequest(GenericAPIView):
    serializer_class = ResetPasswordEmailSerializer

    def post(self, request):
        serializer = ResetPasswordEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = request.data['email']
        user = RegularUserModel.objects.filter(username=email).first()

        if user:
            with transaction.atomic():
                otp_record, created = Otp.objects.get_or_create(user=user)
                abstract_otp_record, created = AbstractOtp.objects.get_or_create(user = user)
                if not created:
                    # An OTP record already exists, delete it and create a new one
                    otp_record.delete()
                    otp_record = Otp.objects.create(user=user)

                otp = otpgenerator()
                abstract_otp = otpgenerator()
                # print(abstract_otp)
                abstract_otp_record.abstract_otp = abstract_otp
                abstract_otp_record.save()
                otp_record.otp = otp
                otp_record.otp_validated = False
                otp_record.save()

                email_subject = 'Reset your password'
                email_body = f"Hello,\n\nThis is your one-time password for resetting your account's password:\n\n**{otp}**\n\nUse this OTP within the next 30 minutes to complete the password reset process."

                # email_body = 'Hello,\n This is the one-time-password for password reset of your account\n' + otp
                data = {'email_body': email_body, 'to_email': user.username, 'email_subject': email_subject}
                try:
                    Utils.send_email(data)
                    response = {'success': True,
                                'message': "OTP SENT SUCCESSFULLY",
                                'validation_id':abstract_otp}
                    return Response(response, status=status.HTTP_200_OK)
                except Exception as e:
                    logger.error(str(e))
                    return Response({'error': 'An error occurred while sending the email.'},
                                    status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        else:
            return Response({'success': False, 'message': "User Not Found"}, status=status.HTTP_404_NOT_FOUND)


#view to validate OTP
class CheckOTP(APIView):
    serializer_class = CheckOTPSerializer

    def post(self, request):
        serializer = CheckOTPSerializer(data = request.data)
        serializer.is_valid(raise_exception = True)

        otp = self.request.query_params.get('otp')
        abstract_otp = self.request.query_params.get('validation_id')
        try:
            abstract_otp = AbstractOtp.objects.get(abstract_otp = abstract_otp)
            user = abstract_otp.user
        except AbstractOtp.DoesNotExist:
            return Response({"OTP validation Failed"}, status=status.HTTP_401_UNAUTHORIZED )
        
        saved_otp = Otp.objects.get(user = user)
        
        if checkOTP(otp=otp, saved_otp_instance=saved_otp):
            saved_otp.otp_validated = True
            saved_otp.save()
            return Response({'success':True, 'message':"OTP VERIFICATION SUCCESSFULL"}, status=status.HTTP_200_OK)

        else:
            return Response({'success':False, 'message':"INVALID OTP"}, status=status.HTTP_400_BAD_REQUEST)
        

#View to reset password through OTP
class ResetPasswordView(APIView):
    serializer_class = ResetPasswordSerializer

    def post(self, request):
        serializer = ResetPasswordSerializer(data = request.data)
        serializer.is_valid(raise_exception = True)

        otp = self.request.query_params.get('otp')
        abstract_otp = self.request.query_params.get('validation_id')

        try:
            abstract_otp = AbstractOtp.objects.get(abstract_otp = abstract_otp)
            user = abstract_otp.user
        except AbstractOtp.DoesNotExist:
            return Response({"Unauthorised User. Can't Reset Password"}, status=status.HTTP_401_UNAUTHORIZED)

        try:
            otp = Otp.objects.get(user = user)
        except Otp.DoesNotExist:
            return Response({"Unauthorised User. Can't Reset Password"}, status=status.HTTP_401_UNAUTHORIZED)
        
        if otp.otp_validated == True:
            pass
        else:
            response = {
                "message": "OTP Not Validated"
            }
            return Response(response, status=status.HTTP_401_UNAUTHORIZED)
        
        user = RegularUserModel.objects.filter(username=user).first()
        otp_instance = Otp.objects.get(user = user)

        if otp_instance.otp_validated == True:
            password  = request.data['password']
            user.set_password(password)
            user.save()
            update_session_auth_hash(request, user)
            otp_instance.delete()
            
            return Response({'success':True, 'message':"Password Changed Succesfully"}, status=status.HTTP_200_OK)

        else:
            return Response({'success':False, 'message':"verify OTP First"}, status=status.HTTP_400_BAD_REQUEST)


#it is to nofity active users with courses.
@method_decorator(csrf_exempt, name='dispatch')
class SendNotification1(APIView):
    # permission_classes = [IsAdminUser]
    def post(self, request):
        now = timezone.now()
        course_id = request.data.get('course_id', '')
        title = request.data.get('title')
        active_purchases = PurchasedDate.objects.filter(course_id=course_id, expiration_date__gt=now)
        active_user_profiles = UserProfile.objects.filter(purchased_dates__in=active_purchases).distinct()
        active_users = RegularUserModel.objects.filter(user_profile__in=active_user_profiles).distinct()

        users = list(active_users)  # Convert QuerySet to list
        print(users)

        if users:  # Check if there are any users
            response = notification(title=title, users=users)
            if response.get('success'):
                return JsonResponse(response)
            else:
                return JsonResponse({"error": "Failed to send notification", "details": response}, status=500)
        else:
            return JsonResponse({"error": "No active users found for the specified course"}, status=404)
        

from datetime import timedelta
#it is to nofity active users with courses going to expire.
@method_decorator(csrf_exempt, name='dispatch')
class SendNotification2(APIView):
    # permission_classes = [IsAdminUser]
    def post(self, request):
        now = timezone.now()
        course_id = request.data.get('course_id', '')
        title = request.data.get('title')
        days = int(request.data.get('days', '7'))

        expiration_threshold = now + timedelta(days=days)
        print(expiration_threshold)
        active_purchases = PurchasedDate.objects.filter(course_id=course_id, expiration_date__gt=now)
        active_user_profiles = UserProfile.objects.filter(purchased_dates__in=active_purchases, 
                                                           purchased_dates__expiration_date__lte=expiration_threshold).distinct()
        active_users = RegularUserModel.objects.filter(user_profile__in=active_user_profiles).distinct()

        users = list(active_users)  # Convert QuerySet to list
        print(users)

        if users:  # Check if there are any users
            response = notification(title=title, users=users)
            if response.get('success'):
                return JsonResponse(response)
            else:
                return JsonResponse({"error": "Failed to send notification", "details": response}, status=500)
        else:
            return JsonResponse({"error": "No active users found for the specified course"}, status=404)
        
        
#it is to notify the user whose course have expired
@method_decorator(csrf_exempt, name='dispatch')
class SendNotification3(APIView):
    # permission_classes = [IsAdminUser]
    def post(self, request):
        now = timezone.now()
        course_id = request.data.get('course_id', '')
        title = request.data.get('title')
        active_purchases = PurchasedDate.objects.filter(course_id=course_id, expiration_date__lt=now)
        active_user_profiles = UserProfile.objects.filter(purchased_dates__in=active_purchases).distinct()
        active_users = RegularUserModel.objects.filter(user_profile__in=active_user_profiles).distinct()

        users = list(active_users)  # Convert QuerySet to list
        print(users)

        if users:  # Check if there are any users
            response = notification(title=title, users=users)
            if response.get('success'):
                return JsonResponse(response)
            else:
                return JsonResponse({"error": "Failed to send notification", "details": response}, status=500)
        else:
            return JsonResponse({"error": "No active users found for the specified course"}, status=404)
        

class RemainingDates(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        course_filter = request.GET.get('course', 'false').lower() == 'true'
        exam_filter = request.GET.get('exam', 'false').lower() == 'true'
        daystoexpire_filter = request.GET.get('daystoexpire', None)
        show_expired = request.GET.get('show_expired', 'false').lower() == 'true'
        course_name = request.GET.get('course_name', None)
        exam_name = request.GET.get('exam_name', None)

        now = timezone.now()

        users = RegularUserModel.objects.filter(is_superuser=False, is_active=True)
        user_profiles = UserProfile.objects.filter(user__in=users)
        purchased_dates = PurchasedDate.objects.filter(user_profile__in=user_profiles)

        if course_filter and not exam_filter:
            purchased_dates = purchased_dates.filter(course__isnull=False)
        elif exam_filter and not course_filter:
            purchased_dates = purchased_dates.filter(exam__isnull=False)
        elif not course_filter and not exam_filter:
            return Response({"error": "At least one of 'course' or 'exam' must be true."}, status=400)

        result = []
        for purchase in purchased_dates:
            remaining_days = (purchase.expiration_date - now).days
            expired = remaining_days < 0
            entry = {
                'name' : purchase.user_profile.user.name,
                'user_id' : purchase.user_profile.user.id,
                'username': purchase.user_profile.user.username,
                'phone_number': purchase.user_profile.user.phone_number,
                'no_of_days_to_expire': max(0, remaining_days),
                'expired': expired
            }
            if purchase.course:
                entry['course_name'] = purchase.course.field_of_study
            if purchase.exam:
                entry['exam_name'] = purchase.exam.exam_name


            if (daystoexpire_filter is None or entry['no_of_days_to_expire'] <= int(daystoexpire_filter)) and \
               (show_expired or not entry['expired']) and \
               (course_name is None or entry.get('course_name', '').lower() == course_name.lower()) and \
               (exam_name is None or entry.get('exam_name', '').lower() == exam_name.lower()):
                result.append(entry)

        serializer = RemainingDatesSerializer(result, many=True)
        return Response(serializer.data)

