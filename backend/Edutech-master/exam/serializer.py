from rest_framework import serializers
from .models import (Exam, MultipleChoice,Numericals, QuestionType,Sections)
from .models import MultiSelect, Options
#Validate QuestionType-Multiplechoice, multiselect, numericals
class QuestionTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuestionType
        fields = ["question_type", 'slug_question_type']

#Validate Options of Multiselect
class OptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Options
        fields = ['option_id','question','option_no', 'options_text', 'options_image','is_answer', 'slug_options']

#Validate Multiplechoice questions data
class MultipleChoiceSerializer(serializers.ModelSerializer):
    # section_name = serializers.SerializerMethodField()
    # exam_name = serializers.SerializerMethodField()
    class Meta:
        model = MultipleChoice
        fields = ['mcq_id','question_type','exam_name', 'section','question_no','question', 'question_image','option1_text','option2_text','option3_text','option4_text','option1_image','option2_image','option3_image','option4_image','positive_marks','negetive_mark','choose','answer','solution_text','solution_image','solution_pdf', 'slug_multiplechoice']

    # def get_section_name(self, obj):
    #     return obj.section.section_name if obj.section else None
    
    # def get_exam_name(self, obj):
    #     return obj.exam_name.exam_name if obj.exam_name else None
    
#Validate Multiselect questions data
class MultiSelectSerializer(serializers.ModelSerializer):
    options = OptionSerializer(many = True, read_only = True)
    # section = serializers.SerializerMethodField()
    # exam_name = serializers.SerializerMethodField()
    class Meta:
        model = MultiSelect
        fields = ['msq_id','question_no','question_type', 'section','exam_name','question','question_image','positive_marks','negetive_mark', 'options','solution_image','solution_text','solution_pdf', 'slug_multiselect']

    # def get_section_name(self, obj):
    #     return obj.section.section_name if obj.section else None

    # def get_exam_name(self, obj):
    #     return obj.exam_name.exam_name if obj.exam_name else None
    
#Validate Numerical question data
class NumericalSerializer(serializers.ModelSerializer):
    # section_name = serializers.SerializerMethodField()
    # exam_name = serializers.SerializerMethodField()

    class Meta:
        model = Numericals
        fields = ['nq_id', 'question_type', 'exam_name', 'section', 'question_no', 'question', 'question_image', 'ans_min_range', 'ans_max_range', 'answer', 'positive_marks', 'negetive_mark', 'solution_text', 'solution_image','solution_pdf', 'slug_numericals']

    # def get_section_name(self, obj):
    #     return obj.section.section_name if obj.section else None
    
    # def get_exam_name(self, obj):
    #     return obj.exam_name.exam_name if obj.exam_name else None
    
class SectionsSerializer(serializers.ModelSerializer):
    multiplechoice = MultipleChoiceSerializer(many = True, read_only =True)
    multiselect = MultiSelectSerializer(many = True, read_only =True)
    numericals = NumericalSerializer(many=True, read_only=True)
    no_of_questions = serializers.SerializerMethodField()
    class Meta:
        model = Sections
        fields = ['id','exam_name','section_no', 'section_name','no_of_ques_to_be_validated', 'positive_marks', 'negetive_mark','total_score','no_of_questions','multiplechoice','multiselect','numericals']

    def get_no_of_questions(self, obj):
        return (obj.multiplechoice.count() + obj.multiselect.count() +obj.numericals.count())

#validates Exam data.
class ExamSerializer(serializers.ModelSerializer):
    multiplechoice = MultipleChoiceSerializer(many = True, read_only =True)
    multiselect = MultiSelectSerializer(many = True, read_only =True)
    numericals = NumericalSerializer(many=True, read_only=True)
    sections = SectionsSerializer(many = True, read_only = True)
    no_of_questions = serializers.SerializerMethodField()

    class Meta:
        model = Exam
        fields = ['exam_unique_id','module','access_type','exam_id','exam_name','instruction','duration_of_exam','total_marks','no_of_questions','created_date','updated_date','solution_pdf', 'slug_exams','is_active', 'sections','multiplechoice','multiselect','numericals']

    def get_no_of_questions(self, obj):
        return (obj.multiplechoice.count() + obj.multiselect.count() +obj.numericals.count())