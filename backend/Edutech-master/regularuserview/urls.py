from django.urls import path
from .views import (CoursesList, CoursesRetrieveView,
                    SubjectsList, SubjectsRetrieveView,
                    ModulesList, ModulesRetrieveView,
                     UserProfileView, ExamsNestedDetailView, ExamsNestedListView,
                    VideosNestedDetailView, videosNestedListView, NotesNestedDetailView, 
                    NotesNestedListView,BuyCourse, ExamListView, ExamRetrieveView, BuyExam, UserExamResponseAdd,
                    PopularCourseView, SliderImageView, PurchaseHistoryView, UserResponses, CourseAdditionThroughExcel,
                    ExamAdditionThroughExcel, handle_payment_success, GetAllUser, RetrieveSpecificUser)
urlpatterns = [
    path('courses/', CoursesList.as_view(), name='courses'),
    path('courses/<int:course_unique_id>/', CoursesRetrieveView.as_view(), name='coursesretrieve'),
    path('courses/<int:course_unique_id>/subjects/', SubjectsList.as_view(), name='subjects'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/', SubjectsRetrieveView.as_view(), name='subjectsretrieve'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/', ModulesList.as_view(), name='modules'), 
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/', ModulesRetrieveView.as_view(), name='modulesretrieve'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/notes/', NotesNestedListView.as_view(), name='notes-list'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/notes/<int:notes_id>', NotesNestedDetailView.as_view(), name='notes-detail'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/exams/', ExamsNestedListView.as_view(), name='exams-list'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/exams/<int:exam_unique_id>', ExamsNestedDetailView.as_view(), name='exams-detail'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/videos/', videosNestedListView.as_view(), name='videos-list'),
    path('courses/<int:course_unique_id>/subjects/<int:subject_id>/modules/<int:modules_id>/videos/<int:video_unique_id>', VideosNestedDetailView.as_view(), name='videos-detail'),
    path('courses/buycourse/', BuyCourse.as_view(), name='buy_course'),
    path('exams/buyexam/', BuyExam.as_view(), name='buy_exam'),

    path('get-user-profile/', UserProfileView.as_view(), name='user_profile'),

    path('exams/', ExamListView.as_view(), name='exams'),
    path('exams/<int:exam_unique_id>/', ExamRetrieveView.as_view(), name='exam-details'),

    path('examresponseadd/', UserExamResponseAdd.as_view(), name='examresponseadd'),

    path('sliderimageview/', SliderImageView.as_view(), name='sliderimageview'),
    path('popularcourseview/', PopularCourseView.as_view(), name='popularcourseview'),
    # path('example/', Example.as_view(), name='example')
    path('get-all-user-list/', GetAllUser.as_view(), name='userlist'),
    path('get-all-user-list/<str:username>/', RetrieveSpecificUser.as_view()),
    path('userlist/<str:username>/purchase_history/', PurchaseHistoryView.as_view(), name='purchase_history'),
    path('userresponses/', UserResponses.as_view(), name='userresponses'),

    path('course-add-excel/', CourseAdditionThroughExcel.as_view(), name='course-add-excel'),
    path('exam-add-excel/', ExamAdditionThroughExcel.as_view(), name='exam-add-excel'),
    path('payment/success/', handle_payment_success, name="payment_success")
]
