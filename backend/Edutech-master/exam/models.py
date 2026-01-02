from django.db import models
from django.utils.text import slugify
from user.models import Access_type, Modules
from django.core.exceptions import ValidationError
# from user.models import ActiveFieldManager
#Three types of Question-(multiple choice, multiselect, numericals)


class QuestionType(models.Model):
    question_type = models.CharField(max_length=50, unique=True)
    slug_question_type = models.SlugField(blank=True, unique=True)

    def clean(self):
        if QuestionType.objects.count()>= 3 and not self.pk:
            raise ValidationError("More than 3 Question Types is not possible.")
        return super().clean()
    
    def save(self, *args, **kwargs):
        if not self.slug_question_type:
            self.slug_question_type = slugify(self.question_type)
        return super().save(*args, **kwargs)    

    def __str__(self) -> str:
        return f"{self.question_type}"

class CustomDurationField(models.DurationField):
    def format_duration(self, duration):
        formatted_duration = super().format_duration(duration)
        hours, minutes, seconds = formatted_duration.split(':')
        return f'{int(hours):02}:{int(minutes):02}:{int(seconds):02}'
    

#Model to save Exam
class Exam(models.Model):
    exam_unique_id = models.AutoField(unique=True, primary_key=True)
    module = models.ForeignKey(Modules, on_delete=models.CASCADE, related_name="exams", default=None, null=True, blank=True) #Modules = parent of Exams
    access_type = models.ForeignKey(Access_type, on_delete=models.SET_DEFAULT, null=True, default="paid")
    exam_id = models.CharField(max_length=50,default='000000')
    exam_name = models.TextField()
    instruction = models.TextField()
    duration_of_exam = CustomDurationField(default='02:30:00')
    total_marks = models.PositiveIntegerField()
    pass_mark = models.PositiveIntegerField(default=00)
    solution_text = models.TextField(default=None, blank=True, null=True)
    solution_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    solution_pdf = models.FileField(upload_to='pdfs/', blank=True, null=True, default=None)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    created_date = models.DateTimeField(auto_now_add=True, blank=True)
    updated_date =  models.DateTimeField(auto_now=True, blank=True)
    slug_exams = models.SlugField(blank=True)

    #Customised manager object
    # objects = ActiveFieldManager()

    def save(self, *args, **kwargs):
        if not self.slug_exams:
            self.slug_exams = slugify(self.exam_id)
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.module}-{self.exam_name}-{self.exam_id}"


class Sections(models.Model):
    exam_name= models.ForeignKey(Exam, on_delete=models.CASCADE, blank=True, null=True, related_name='sections')
    section_no = models.CharField(max_length=300)
    section_name = models.CharField(max_length=400, blank=True, null=True)
    positive_marks = models.FloatField(default=0.0)
    negetive_mark = models.FloatField(default=0.0)
    no_of_ques_to_be_validated = models.IntegerField()
    total_score = models.IntegerField(blank=True, null=True, default=0)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['exam_name', 'section_no'], name='unique_section_no_per_exam')]

    def save(self, *args, **kwargs):
        self.total_score = self.positive_marks * self.no_of_ques_to_be_validated
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.exam_name}-{self.section_no}"


#Model to add Multiplechoice questions
#Options are need to enter and correct answer can be choosen within this model
class MultipleChoice(models.Model):
    mcq_id = models.AutoField(primary_key=True, unique=True)
    section = models.ForeignKey(Sections, on_delete=models.SET_NULL, blank=True, null=True, related_name='multiplechoice')
    question_type = models.ForeignKey(QuestionType, on_delete=models.SET_NULL,null=True)
    exam_name = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='multiplechoice')
    question_no = models.IntegerField()
    question = models.TextField(null=True, blank=True)
    question_image = models.ImageField(upload_to='images/', null=True,blank=True)
    option1_text = models.TextField( blank=True,null=True)
    option2_text = models.TextField( blank=True,null=True)
    option3_text = models.TextField( blank=True,null=True)
    option4_text = models.TextField( blank=True,null=True)
    option1_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    option2_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    option3_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    option4_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    positive_marks = models.FloatField(default=0.0)
    negetive_mark = models.FloatField(default=0.0)
    choose = (('A', 'option1'), ('B', 'option2'), ('C', 'option3'), ('D', 'option4'))
    answer = models.CharField(max_length=1, choices=choose)
    solution_text = models.TextField(default=None, blank=True, null=True)
    solution_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    solution_pdf = models.FileField(upload_to='pdfs/', blank=True, null=True, default=None)
    slug_multiplechoice = models.SlugField(blank=True)

    def save(self, *args, **kwargs):
        if not self.slug_multiplechoice:
            self.slug_multiplechoice = slugify(self.question_no)
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.exam_name}-{self.question_no}"

# # Model to add MultiSelect Question
class MultiSelect(models.Model): 
    msq_id = models.AutoField(primary_key=True, unique=True)
    section = models.ForeignKey(Sections, on_delete=models.SET_NULL, blank=True, null=True, related_name='multiselect')
    question_type = models.ForeignKey(QuestionType, on_delete=models.SET_NULL,null=True)
    exam_name = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='multiselect',)
    question_no = models.IntegerField()
    question = models.TextField(null=True, blank=True)
    question_image = models.ImageField(upload_to='images/', null=True,blank=True)
    positive_marks = models.FloatField(default=0.0)
    negetive_mark = models.FloatField(default=0.0)
    solution_text = models.TextField(default=None, blank=True, null=True)
    solution_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    solution_pdf = models.FileField(upload_to='pdfs/', blank=True, null=True, default=None)
    slug_multiselect = models.SlugField(blank=True)

    def save(self, *args, **kwargs):
        if not self.slug_multiselect:
            self.slug_multiselect= slugify(self.question_no)
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.exam_name}{self.question_no}"


#model to add options to Multiselect Question Type
class Options(models.Model):
    option_id = models.AutoField(primary_key=True, unique=True)
    question = models.ForeignKey(MultiSelect, on_delete=models.CASCADE, related_name='options')
    option_no = models.PositiveIntegerField()
    options_text = models.TextField( blank=True,null=True)
    options_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    solution_pdf = models.FileField(upload_to='pdfs/', blank=True, null=True, default=None)
    is_answer = models.BooleanField(default=False)
    slug_options = models.SlugField(blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['question', 'option_no'], name='unique_option_no_per_question')]

    def clean(self):
        # Retrieve the question and check the number of related options
        question = self.question
        num_options = Options.objects.filter(question=question).count()
        # Ensure there are at most 4 options for the question
        if num_options >= 4:
            raise ValidationError("Each question can only have a maximum of 4 options.")
        super().clean()

    def save(self, *args, **kwargs):
        if not self.slug_options:
            self.slug_options = slugify(self.option_no)
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f"{self.question}-{self.option_no}"
    
#model to add Numerical questions
class Numericals(models.Model):
    nq_id = models.AutoField(primary_key=True, unique=True)
    section = models.ForeignKey(Sections, on_delete=models.SET_NULL, blank=True, null=True, related_name='numericals')
    question_type = models.ForeignKey(QuestionType, on_delete=models.SET_NULL, null=True)
    exam_name = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='numericals')
    question_no = models.IntegerField()
    question = models.TextField(blank=True, null=True)
    question_image = models.ImageField(upload_to='images/', null=True,blank=True)
    ans_min_range = models.DecimalField(max_digits=6,decimal_places=2)
    ans_max_range = models.DecimalField(max_digits=6,decimal_places=2)
    answer = models.DecimalField(max_digits=6,decimal_places=2)
    positive_marks = models.FloatField(default=0.0)
    negetive_mark = models.FloatField(default=0.0)
    solution_text = models.TextField(default=None, blank=True, null=True)
    solution_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    solution_pdf = models.FileField(upload_to='pdfs/', blank=True, null=True, default=None)
    slug_numericals = models.SlugField(blank=True)
    
    def save(self, *args, **kwargs):
        if not self.slug_numericals:
            self.slug_numericals= slugify(self.question_no)
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.exam_name}{self.question_no}"
    

#structure used here is 
"""  
            ACCESSTYPE(paid or free)
                |
              EXAM    QUESTION_TYPE             --PARENTS
                |           |
    (MULTIPLECHOICE, MULTISELECT, NUMERICALS)  --CHILDRENS
        |                 |            |
contains multiple-   contains mu-   contain numerical
choice questions    select ques     questions    
"""
