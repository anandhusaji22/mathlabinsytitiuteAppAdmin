from django.shortcuts import render
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from .serializer import (QuestionTypeSerializer,
                          MultipleChoiceSerializer,
                            NumericalSerializer, ExamSerializer, SectionsSerializer)
from rest_framework.views import APIView
from .models import (QuestionType,
                    MultipleChoice,
                    Numericals, Exam, Sections)
from .serializer import MultiSelectSerializer,OptionSerializer
from .models import Options,MultiSelect
from rest_framework.permissions import IsAdminUser
from rest_framework.authentication import TokenAuthentication
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

#listview for Question type list
class QuestionTypeListCreateView(ListCreateAPIView):
    # permission_classes = [IsAdminUser]
    # authentication_classes = [TokenAuthentication]
    queryset = QuestionType.objects.all()
    serializer_class = QuestionTypeSerializer
    

#Detail view of QuestionType
class QuestionTypeRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    queryset = QuestionType.objects.all()
    serializer_class = QuestionTypeSerializer
    lookup_field = "slug_question_type"

#listview of Exams
class ExamListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Exam.objects.all()
    serializer_class = ExamSerializer

#Detail view of Exams
class ExamRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Exam.objects.all()
    serializer_class = ExamSerializer
    lookup_field = "exam_unique_id"
    

#listview for Numericals questions
class NumericalsListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Numericals.objects.all()
    serializer_class = NumericalSerializer
    lookup_field = 'exam_unique_id'

    def get_queryset(self):
        exam_unique_id = self.kwargs['exam_unique_id']
        exam_name = Exam.objects.get(exam_unique_id = exam_unique_id)
        return exam_name.numericals.all()
    

#Detail view of Numericals Questions
class NumericalsRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Numericals.objects.all()
    serializer_class = NumericalSerializer
    lookup_field = "nq_id"
    

#listview for Multipletype questions
class MultipleChoiceListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = MultipleChoice.objects.all()
    serializer_class = MultipleChoiceSerializer
    lookup_field = 'exam_unique_id'
    
    
    def get_queryset(self):
        exam_unique_id = self.kwargs['exam_unique_id']
        exam_name = Exam.objects.get(exam_unique_id = exam_unique_id)
        return exam_name.multiplechoice.all()

#Detail view of Multipletype questions
class MultipleChoiceRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = MultipleChoice.objects.all()
    serializer_class = MultipleChoiceSerializer
    lookup_field = "mcq_id"

#listview for Multiselect questions
class MultiSelectListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = MultiSelect.objects.all()
    serializer_class = MultiSelectSerializer
    lookup_field = 'exam_unique_id'
    
    def get_queryset(self):
        exam_unique_id = self.kwargs['exam_unique_id']
        exam_name = Exam.objects.get(exam_unique_id = exam_unique_id)
        return exam_name.multiselect.all()

#Detailview for Multiselect questions
class MultiSelectRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = MultiSelect.objects.all()
    serializer_class = MultiSelectSerializer
    lookup_field = "msq_id"

#List view of options of multiselect questions.
class OptionsListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = OptionSerializer
    lookup_field = "msq_id"

    def get_queryset(self):
        msq_id = self.kwargs["msq_id"]
        question_no = MultiSelect.objects.get(msq_id = msq_id)
        return question_no.options.all()

#DetailView of options of multiselect Questions
class OptionsRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Options.objects.all()
    serializer_class = OptionSerializer
    lookup_field = "option_id"


#List view of options of multiselect questions.
class SectionsListCreateView(ListCreateAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    serializer_class = SectionsSerializer
    queryset = Sections.objects.all()


#DetailView of options of multiselect Questions
class SectionsRetrieveUpdateDestroyView(RetrieveUpdateDestroyAPIView):
    # authentication_classes = [TokenAuthentication]
    # permission_classes = [IsAdminUser]
    queryset = Sections.objects.all()
    serializer_class = SectionsSerializer
    lookup_field = "id"


@method_decorator(csrf_exempt, name='dispatch')
class AlterMultipleChoiceExamToSection(APIView):

    def post(self, request):
        section_id = request.data.get('section_id')
        question_id = request.data.get('question_id')

        try:
            question = MultipleChoice.objects.get(mcq_id = question_id)
        except MultipleChoice.DoesNotExist:
            respone = {
                "success": False,
                "message": f"Question with id - {question_id} Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)
        try:
            new_section = Sections.objects.get(id = section_id)
        except Sections.DoesNotExist:
            respone = {
                "success": False,
                "message": "Section Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)

        question.section = new_section
        question.save()

        respone = {
                "success": True,
                "message": "Section updated Successfully",
                "status" : status.HTTP_200_OK
            }
        return Response(respone)
    
@method_decorator(csrf_exempt, name='dispatch')
class AlterMultiselectExamToSection(APIView):

    def post(self, request):
        section_id = request.data.get('section_id')
        question_id = request.data.get('question_id')

        try:
            question = MultiSelect.objects.get(msq_id = question_id)
        except MultiSelect.DoesNotExist:
            respone = {
                "success": False,
                "message": f"Question with id - {question_id} Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)
        try:
            new_section = Sections.objects.get(id = section_id)
        except Sections.DoesNotExist:
            respone = {
                "success": False,
                "message": "Section Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)

        question.section = new_section
        question.save()

        respone = {
                "success": True,
                "message": "Section updated Successfully",
                "status" : status.HTTP_200_OK
            }
        return Response(respone)


@method_decorator(csrf_exempt, name='dispatch')
class AlterNumericalExamToSection(APIView):
    
    def post(self, request):
        section_id = request.data.get('section_id')
        question_id = request.data.get('question_id')

        try:
            question = Numericals.objects.get(nq_id = question_id)
        except Numericals.DoesNotExist:
            respone = {
                "success": False,
                "message": f"Question with id - {question_id} Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)
        try:
            new_section = Sections.objects.get(id = section_id)
        except Sections.DoesNotExist:
            respone = {
                "success": False,
                "message": "Section Doesn't exist",
                "status" : status.HTTP_404_NOT_FOUND
            }
            return Response(respone)

        question.section = new_section
        question.save()

        respone = {
                "success": True,
                "message": "Section updated Successfully",
                "status" : status.HTTP_200_OK
            }
        return Response(respone)
    





from rest_framework.response import Response
from rest_framework import status
class AddAlltoSections(APIView):
    def post(self, request):
        # Retrieve exams with empty sections
        exams = Exam.objects.filter(sections = None)

        for exam in exams:
            total_score = exam.total_marks
            positive_marks = 3.0

            # Create the section and associate it with the exam
            section = Sections.objects.create(
                exam_name=exam,
                section_no='1',
                section_name='section 1',
                total_score=total_score,
                positive_marks=positive_marks,
                negetive_mark=1.0,
                no_of_ques_to_be_validated=int(total_score / positive_marks)
            )
            MultipleChoice.objects.filter(exam_name = exam).update(section = section)
            MultiSelect.objects.filter(exam_name = exam).update(section = section)
            Numericals.objects.filter(exam_name = exam).update(section = section)
        return Response({'success': True, 'message': "Successful"})


        
                

    