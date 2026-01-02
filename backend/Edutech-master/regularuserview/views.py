from django.shortcuts import render
from rest_framework.generics import CreateAPIView,ListAPIView, RetrieveAPIView,ListCreateAPIView, RetrieveUpdateDestroyAPIView
from rest_framework.views import APIView
from user.models import (FieldOfStudy, Subjects,
                         Modules,RegularUserModel,
                         videosNested, NotesNested, 
                         SliderImage, PopularCourses)
from user.serializers import (FieldOfStudySerializer, SubjectSerializer, ModuleSerializer,
                              RegularUserSerializer, VideoNestedSerializer,
                              NotesNestedSerializer, SliderImageSerializer, PopularCourseSerializer)
from .serializer import (UserResponseSerializer, UserProfileSerializer, GetAllUserResponseSerializer,
                         PurchasedDateSerializer, DurationSerializer, CustomGetUserListSerializer)
from exam.models import Exam
from exam.serializer import ExamSerializer
from .models import UserProfile,UserResponse, PurchasedDate
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response
from rest_framework import status
from rest_framework.filters import SearchFilter
from django.db.models import Q
from rest_framework.pagination import LimitOffsetPagination
import pandas as pd
from datetime import datetime
import razorpay
import os
import json
from rest_framework.decorators import api_view
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from razorpay import errors 
from .utils import CustomPagination
from django.db.models import Q
from rest_framework.filters import SearchFilter
import logging

logger = logging.getLogger(__name__)


from dotenv import load_dotenv
load_dotenv()
#course List
class CoursesList(ListAPIView):
    queryset = FieldOfStudy.objects.filter(is_active = True)
    serializer_class = FieldOfStudySerializer


#Course DetailView
class CoursesRetrieveView(RetrieveAPIView):
    queryset = FieldOfStudy.objects.all()
    serializer_class = FieldOfStudySerializer
    lookup_field = 'course_unique_id'


#subjects List view
class SubjectsList(ListAPIView):
    serializer_class = SubjectSerializer
    lookup_field = 'course_unique_id'

    def get_queryset(self):
        course_unique_id = self.kwargs['course_unique_id']
        course = FieldOfStudy.objects.get(course_unique_id = course_unique_id)
        return course.subjects.filter(is_active = True)


#subjects Detail view
class SubjectsRetrieveView(RetrieveAPIView):
    queryset = Subjects.objects.filter(is_active = True)
    serializer_class = SubjectSerializer
    lookup_field = 'subject_id'


#Modules List view
class ModulesList(ListAPIView):
    serializer_class = ModuleSerializer
    lookup_field = 'subject_id'

    def get_queryset(self):
        subject_id = self.kwargs['subject_id']
        subjects = Subjects.objects.get(subject_id = subject_id)
        return subjects.modules.filter(is_active = True)


#Modules Detail view
class ModulesRetrieveView(RetrieveAPIView):
    queryset = Modules.objects.filter(is_active = True)
    serializer_class = ModuleSerializer
    lookup_field = 'modules_id'
    

#list and write exams inside of the course
class ExamsNestedListView(ListAPIView):
    serializer_class = ExamSerializer
    lookup_field = "modules_id"
    def get_queryset(self):
        modules_id = self.kwargs["modules_id"] #extract 'modules_id'
        modules = Modules.objects.get(modules_id = modules_id)   #extract modules based on that 'modules_id'
        return modules.exams.filter(is_active = True)  #extract all exams based on that 'modules_id'
    

#Exams inside Modules Detailview
class ExamsNestedDetailView(RetrieveAPIView):
    queryset = Exam.objects.filter(is_active = True)
    serializer_class = ExamSerializer
    lookup_field = "exam_unique_id"


#list and write videos
class videosNestedListView(ListAPIView):
    serializer_class = VideoNestedSerializer
    lookup_field = "modules_id"

    def get_queryset(self):
        modules_id = self.kwargs["modules_id"] #extract 'modules_id'
        modules = Modules.objects.get(modules_id = modules_id)  #extract modules based on that 'modules_id'
        return modules.videos.filter(is_active = True)   #extract all videos based on that 'modules_id'
    

#Videos inside Modules Detailview
class VideosNestedDetailView(RetrieveAPIView):
    queryset = videosNested.objects.filter(is_active = True)
    serializer_class = VideoNestedSerializer
    lookup_field = "video_unique_id"


#list and write notes
class NotesNestedListView(ListAPIView):
    serializer_class = NotesNestedSerializer
    lookup_field = "modules_id"

    def get_queryset(self):
        modules_id = self.kwargs["modules_id"]  #extract 'modules_id'
        modules = Modules.objects.get(modules_id = modules_id)  #extract modules based on that 'modules_id'
        return modules.notes.filter(is_active = True) #extract all notes based on that 'modules_id'
    

#Videos inside Modules Detailview
class NotesNestedDetailView(RetrieveAPIView):
    queryset = NotesNested.objects.filter(is_active = True)
    serializer_class = NotesNestedSerializer
    lookup_field = "notes_id"


#List all available exams.
class ExamListView(ListAPIView):
    serializer_class = ExamSerializer
    queryset = Exam.objects.all()


#retrieve exams according to examid as slug
class ExamRetrieveView(RetrieveAPIView):
    serializer_class = ExamSerializer
    queryset = Exam.objects.filter(is_active = True)
    lookup_field = 'exam_unique_id'


class BuyExam(APIView):
    @method_decorator(csrf_exempt)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)
    
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data['amount']
        exam_unique_id = request.data['exam_unique_id']
        duration = int(request.data.get('duration')) #duration in days

        try:
            exam = Exam.objects.get(exam_unique_id=exam_unique_id)
        except Exam.DoesNotExist:
            return Response("Exam not found", status=status.HTTP_404_NOT_FOUND)
        
        PUBLIC_KEY = os.getenv('PUBLIC_KEY')
        SECRET_KEY = os.getenv('SECRET_RAZ_KEY')

        client = razorpay.Client(auth=(PUBLIC_KEY, SECRET_KEY))
        
        payment = client.order.create({
            "amount": int(amount) * 100,
            "currency": "INR",
            "payment_capture": "1"
        })
        user_profile, created = UserProfile.objects.get_or_create(user=request.user)

        date_of_purchase = timezone.now()
        expiration_date = date_of_purchase + timezone.timedelta(days=duration)

        user_profile.purchased_exams.add(exam)

        purchased_date = PurchasedDate.objects.create(user_profile=user_profile, 
                                                      exam=exam,
                                                      date_of_purchase=date_of_purchase,
                                                      expiration_date=expiration_date,
                                                      order_amount = amount,
                                                      order_payment_id = payment['id'],
                                                      isPaid = False)
        serializer = PurchasedDateSerializer(purchased_date)

        data = {
        "payment": payment,
        "order": serializer.data
        }
        return Response(data, status=status.HTTP_200_OK)
    

class BuyCourse(APIView):
    @method_decorator(csrf_exempt)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)   
     
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data['amount']
        course_unique_id = request.data['course_unique_id']
        duration = int(request.data.get('duration')) #duration in days
        try:
            course = FieldOfStudy.objects.get(course_unique_id=course_unique_id)
        except FieldOfStudy.DoesNotExist:
            return Response("Course not found", status=status.HTTP_404_NOT_FOUND)
        
        PUBLIC_KEY = os.getenv('PUBLIC_KEY')
        SECRET_KEY = os.getenv('SECRET_RAZ_KEY')

        print(PUBLIC_KEY)
        client = razorpay.Client(auth=(PUBLIC_KEY, SECRET_KEY))
        
        print(f"{client} is client")

        payment = client.order.create({
            "amount": int(amount) * 100,
            "currency": "INR",
            "payment_capture": "1"
        })

        user_profile, created = UserProfile.objects.get_or_create(user=request.user)

        date_of_purchase = timezone.now()
        expiration_date = date_of_purchase + timezone.timedelta(days=duration)

        user_profile.purchased_courses.add(course)

        purchased_date = PurchasedDate.objects.create(user_profile=user_profile,
                                                      course=course,
                                                      date_of_purchase=date_of_purchase,
                                                      expiration_date=expiration_date,
                                                      order_amount = amount,
                                                      order_payment_id = payment['id'],
                                                      isPaid = False)
        serializer = PurchasedDateSerializer(purchased_date)

        data = {
        "payment": payment,
        "order": serializer.data
        }
        return Response(data, status=status.HTTP_200_OK)
    

@api_view(['POST'])
def handle_payment_success(request):
    try:
        ord_id = request.data.get('razorpay_order_id')
        raz_pay_id = request.data.get('razorpay_payment_id')
        raz_signature = request.data.get('razorpay_signature')

        if not ord_id or not raz_pay_id or not raz_signature:
            return Response({'error': 'Missing required parameters'}, status=400)
        
        order = PurchasedDate.objects.get(order_payment_id=ord_id)

        data = {
            'razorpay_order_id': ord_id,
            'razorpay_payment_id': raz_pay_id,
            'razorpay_signature': raz_signature
        }
        
        PUBLIC_KEY = os.getenv('PUBLIC_KEY')
        SECRET_KEY = os.getenv('SECRET_RAZ_KEY')
        client = razorpay.Client(auth=(PUBLIC_KEY, SECRET_KEY))

        try:
            client.utility.verify_payment_signature(data)
            order.isPaid = True
            order.save()
            return Response({'message': 'Payment successful'}, status=200)
        
        except errors.SignatureVerificationError:
            logger.error(f"Signature Verification Failed for order {ord_id}")
        
        except errors.BadRequestError as e:
            logger.error(f"Payment Failed for order {ord_id}: {str({e})}")
            return Response({'error': 'Bad request'}, status=400)
        
        except Exception as e:
            logger.error(f"An unexpected error occurred for order {ord_id}: {str(e)}")
            return Response({'error': 'Payment Processing Failed'}, status=500)
    
    except PurchasedDate.DoesNotExist:
        return Response({'error': 'Order does not exist.'}, status=404)
    except KeyError:
        return Response({'error': 'Invalid request format'}, status=400)
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return Response({'error': 'Internal Server error'}, status=500)
    

from .utils import ExamScoreEvaluator
#view to add ExamResponse of User.
class UserExamResponseAdd(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        user = request.user
        exam_id = request.data.get('exam_id')
        exam_response = request.data.get('exam_response')
        time_taken = request.data.get('time_taken')

        if exam_id:
            try:
                exam = Exam.objects.get(exam_unique_id = exam_id)
            except Exam.DoesNotExist:
                response = {"message":"exam Not Exist", "status": status.HTTP_404_NOT_FOUND}
                return Response(response)
            
            # Ensure exam_response is a dictionary
            if not isinstance(exam_response, dict):
                response = {"message": "Invalid exam_response format", "status": status.HTTP_400_BAD_REQUEST}
                return Response(response)
            
            score = ExamScoreEvaluator(response=exam_response)

            exam_id = exam.exam_unique_id
            exam_name = exam.exam_name
            response = exam_response
            time_taken = time_taken
            mark_scored = score
            total_scored = exam.total_marks
            response_dict = exam_response

            user_response = UserResponse.objects.create(
                user=user,
                exam_id=exam_id,
                exam_name = exam_name,
                response=response_dict,
                time_taken = time_taken,
                marks_scored=mark_scored,
                total_scored = total_scored,
            )

            data = UserResponseSerializer(user_response).data

            response = {
                "message": "User response added successfully",
                'data': {
                    'exam_id': exam_id,
                    'response': data,
                },
                'status': status.HTTP_201_CREATED
            }
            return Response(response, status=status.HTTP_201_CREATED)
        return Response("Exam-id Not Found", status=status.HTTP_404_NOT_FOUND)
    

#This is for user to get their data.
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    serializer_class = RegularUserSerializer

    def get(self, request):
        user = request.user
        user_data = RegularUserModel.objects.get(username = user.username)
        ret_data = RegularUserSerializer(user_data)

        response = {'data' : ret_data.data,
                    'status' : status.HTTP_200_OK}
        return Response(response)


#view for admin to get all the registered user list.
#need to do from here.
class GetAllUser(APIView):
    permission_classes = [IsAdminUser]
    serializer_class = RegularUserSerializer
    def get(self, request):
        username = request.GET.get('username', '')
        phone_number = request.GET.get('phone_number', '')
        name = request.GET.get('name', '')
        course_id = request.GET.get('course_id', '')
        exam_id = request.GET.get('exam_id', '')
        # Filter users who are not superusers
        data = RegularUserModel.objects.filter(is_superuser=False)

        # Apply filters based on provided parameters
        if username:
            data = data.filter(username__icontains=username)
        if phone_number:
            data = data.filter(phone_number__icontains=phone_number)
        if name:
            data = data.filter(name__icontains=name)
        if course_id:
            data = data.filter(user_profile__purchased_dates__course_id = course_id)
        if exam_id:
            data = data.filter(user_profile__purchased_dates__exam_id = exam_id)

        pagination = CustomPagination()

        paginator_data = pagination.paginate_queryset(data, request)

        ret_data = CustomGetUserListSerializer(paginator_data, many = True)
        
        return pagination.get_paginated_response(ret_data.data)


class RetrieveSpecificUser(RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAdminUser]
    serializer_class = RegularUserSerializer
    lookup_field = 'username'
    def get_queryset(self):
        # Only allow the user to access their own instance
        return RegularUserModel.objects.filter(is_superuser = False)


#show the purchased history.
class PurchaseHistoryView(ListAPIView):
    serializer_class = UserProfileSerializer
    lookup_field = 'username'
    def get_queryset(self): 
        return UserProfile.objects.filter(user = self.request.user)


class SliderImageView(ListAPIView):
    permission_classes = [IsAdminUser]
    serializer_class = SliderImageSerializer
    queryset = SliderImage.objects.all()


class PopularCourseView(ListAPIView):
    serializer_class = PopularCourseSerializer
    queryset = PopularCourses.objects.all()


class UserResponses(ListAPIView):
    pagination_class = LimitOffsetPagination
    permission_classes = [IsAdminUser]
    serializer_class = GetAllUserResponseSerializer
    queryset = UserResponse.objects.all()
    filter_backends = [SearchFilter]
    search_fields = ['exam_id', 'exam_name','user__username']

    def get_queryset(self):
        queryset = super().get_queryset()
        # Apply search filtering
        search_query = self.request.query_params.get('search')
        if search_query:
            # Split the search query into individual words and create a Q object for each word
            search_words = search_query.split()
            search_filter = Q()
            for word in search_words:
                search_filter |= (Q(exam_id__exact=word) | Q(user__username__icontains=word))
                                  
            queryset = queryset.filter(search_filter)
        return queryset


#view to handle excel file for user registration.
class CourseAdditionThroughExcel(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        file = request.FILES['file']
        df = pd.read_excel(file)

        success_users = []
        errors = []

        for index, row in df.iterrows():
            username = row['username']
            course_id = row['course_id']
            duration = row['duration'] #should be integer

            try:
                course = FieldOfStudy.objects.get(course_unique_id = course_id)
                user = RegularUserModel.objects.get(username = username)
            except RegularUserModel.DoesNotExist:
                return Response("User not found", status=status.HTTP_404_NOT_FOUND)
            except FieldOfStudy.DoesNotExist:
                return Response("Course not found", status=status.HTTP_404_NOT_FOUND)
            
            duration = duration
            date_of_purchase = timezone.now()
            expiration_date = date_of_purchase + timezone.timedelta(days=duration)
            user_profile, created = UserProfile.objects.get_or_create(user = user)

            if course not in user_profile.purchased_courses.all():
                user_profile.purchased_courses.add(course)

            # Now, update or create the PurchasedDate record
            purchased_date, created = PurchasedDate.objects.get_or_create(
                user_profile=user_profile,
                course=course,
                defaults={'date_of_purchase': timezone.now(),
                        'expiration_date': expiration_date}
            )

            # If the PurchasedDate record already exists, update the expiration date
            if not created:
                purchased_date.expiration_date = expiration_date
                purchased_date.save()

        return Response("Course purchased successfully", status=status.HTTP_200_OK)
 
 
#view to handle excel file for exam addition
class ExamAdditionThroughExcel(APIView):
    permission_classes = [IsAdminUser]
    def post(self, request):
        file = request.FILES['file']
        df = pd.read_excel(file)

        for index, row in df.iterrows():
            username = row['username']
            exam_id = row['exam_id']
            duration = row['duration'] #should be integer
        
        #get associated user and exam
            try:
                exam = Exam.objects.get(exam_unique_id = exam_id)
                user = RegularUserModel.objects.get(username = username)
            except RegularUserModel.DoesNotExist:
                return Response("User not found", status=status.HTTP_404_NOT_FOUND)
            except Exam.DoesNotExist:
                return Response("Exam not found", status=status.HTTP_404_NOT_FOUND)
              
            date_of_purchase = timezone.now()
            expiration_date = date_of_purchase + timezone.timedelta(days=duration)

            user_profile, created = UserProfile.objects.get_or_create(user = user)

            if exam not in user_profile.purchased_exams.all():
                user_profile.purchased_exams.add(exam)

            # Now, update or create the PurchasedDate record
            purchased_date, created = PurchasedDate.objects.get_or_create(
                user_profile=user_profile,
                exam=exam,
                defaults={'date_of_purchase': timezone.now(),
                        'expiration_date': expiration_date}
            )

            # If the PurchasedDate record already exists, update the expiration date
            if not created:
                purchased_date.expiration_date = expiration_date
                purchased_date.save()

        return Response("Exam purchased successfully", status=status.HTTP_200_OK)