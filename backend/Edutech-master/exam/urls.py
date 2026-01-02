from django.urls import path
from .views import (QuestionTypeListCreateView, QuestionTypeRetrieveUpdateDestroyView, 
                    MultipleChoiceListCreateView, MultipleChoiceRetrieveUpdateDestroyView,
                    MultiSelectListCreateView, MultiSelectRetrieveUpdateDestroyView,
                    OptionsListCreateView, OptionsRetrieveUpdateDestroyView,
                    NumericalsListCreateView, NumericalsRetrieveUpdateDestroyView,
                    ExamListCreateView, ExamRetrieveUpdateDestroyView, SectionsListCreateView, SectionsRetrieveUpdateDestroyView,
                    AddAlltoSections, AlterMultipleChoiceExamToSection, AlterMultiselectExamToSection, AlterNumericalExamToSection)

urlpatterns = [

    #this urls is for admin to add,update and view questions.
    path('question-type/', QuestionTypeListCreateView.as_view(), name='exam'),
    path('question-type/<str:slug_question_type>/', QuestionTypeRetrieveUpdateDestroyView.as_view(), name='exam'),
    path('addexam/', ExamListCreateView.as_view(), name='exam'),
    path('addexam/<int:exam_unique_id>/', ExamRetrieveUpdateDestroyView.as_view(), name='exam'),
    path('addexam/<int:exam_unique_id>/multiplechoice/', MultipleChoiceListCreateView.as_view(), name='multiplechoice-list'),
    path('addexam/<int:exam_unique_id>/multiplechoice/<int:mcq_id>/', MultipleChoiceRetrieveUpdateDestroyView.as_view(), name='multiplechoice-detail'),
    path('addexam/<int:exam_unique_id>/multiselect/', MultiSelectListCreateView.as_view(), name='multiselect-list'),
    path('addexam/<int:exam_unique_id>/multiselect/<int:msq_id>/', MultiSelectRetrieveUpdateDestroyView.as_view(), name='multiselect-detail'),
    path('addexam/<int:exam_unique_id>/multiselect/<int:msq_id>/options/', OptionsListCreateView.as_view(), name='multiselect-options-list'),
    path('addexam/<int:exam_unique_id>/multiselect/<int:msq_id>/options/<int:option_id>/', OptionsRetrieveUpdateDestroyView.as_view(), name='multiselect-options-detail'),
    path('addexam/<int:exam_unique_id>/numericals/', NumericalsListCreateView.as_view(), name='numericals-list'),
    path('addexam/<int:exam_unique_id>/numericals/<int:nq_id>/', NumericalsRetrieveUpdateDestroyView.as_view(), name='numericals-detail'),

    path('sections-add/', SectionsListCreateView.as_view()),
    path('sections-add/<str:id>/', SectionsRetrieveUpdateDestroyView.as_view()),

    path('add-section-to-default/', AddAlltoSections.as_view()),

    path('alter-numerical-section/', AlterNumericalExamToSection.as_view()),
    path('alter-multiplechoice-section/', AlterMultipleChoiceExamToSection.as_view()),
    path('alter-multiselect-section/', AlterMultiselectExamToSection.as_view()),
]
