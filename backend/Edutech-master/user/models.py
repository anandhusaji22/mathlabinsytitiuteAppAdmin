from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import RegexValidator
from django.utils.text import slugify
from datetime import date
from django.core.exceptions import ValidationError

phone_regex = RegexValidator(
    regex=r'^\d{10}$',
    message="Phone number must be 10 digits."
)


#Add Course instances.
class FieldOfStudy(models.Model): #parent
    course_unique_id = models.AutoField(unique=True, primary_key=True)
    field_of_study = models.CharField(max_length=200)
    course_image = models.ImageField(upload_to='images/', null=True, blank=True)
    price = models.DecimalField(max_digits=6, decimal_places=2, default=100)
    Course_description = models.TextField(default="course Description")
    Course_duration = models.IntegerField(default=None, blank=True, null=True)
    user_benefit = models.TextField(help_text="Enter what the user's benefit with the course.", default="user benefits")
    cover_image = models.ImageField(upload_to='images/', blank=True,null=True, default=None)
    only_paid = models.BooleanField(default=True)
    slug_studyfield = models.SlugField(blank=True, null=True)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    created_date = models.DateTimeField(auto_now_add=True, blank=True)
    updated_date =  models.DateTimeField(auto_now=True, blank=True)



    def save(self, *args, **kwargs):
        if not self.slug_studyfield:
            self.slug_studyfield = slugify(self.field_of_study)
        return super().save(*args, **kwargs) 

    def __str__(self) -> str:
        return f"course name:{self.field_of_study}"


#overriden user model.
class RegularUserModel(AbstractUser):
    name = models.CharField(max_length=100)
    username = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=10, validators=[phone_regex], unique=True,)
    otps = models.CharField(max_length=9, blank=True, null=True, default='000000')
    otp_session_id = models.CharField(max_length=300, blank=True, null=True)
    verified = models.BooleanField(default=False, help_text='If otp verification got successful')
    count = models.IntegerField(default=0, help_text='Number of otp sent')
    USERNAME_FIELD = 'username'


#store all the subjects.
class Subjects(models.Model):
    subject_id = models.AutoField(unique=True, primary_key=True)
    field_of_study = models.ForeignKey(FieldOfStudy, on_delete=models.CASCADE, related_name='subjects') #FieldOfStudy = parent of subjects.
    subject_image = models.ImageField(upload_to='images/', null=True, blank=True)
    # subject_no = models.IntegerField(unique=True, default=1)
    subjects = models.CharField(max_length=200)
    slug_subjects = models.SlugField(blank=True, null=True)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    direct_slug = models.SlugField(blank=True, null=True)
    created_date = models.DateTimeField(auto_now_add=True, blank=True)
    updated_date =  models.DateTimeField(auto_now=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.slug_subjects:
            self.slug_subjects = slugify(self.subjects)
        return super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f"{self.field_of_study}-{self.subjects}"


#model to add modules of subjects.
class Modules(models.Model):
    modules_id = models.AutoField(unique=True, primary_key=True)
    subjects = models.ForeignKey(Subjects, on_delete=models.CASCADE, related_name='modules') #Subject = parent of modules 
    # module_no = models.IntegerField() 
    module_name = models.CharField(max_length=400)
    slug_modules = models.SlugField(blank=True, null=True)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    created_date = models.DateTimeField( blank=True)
    updated_date =  models.DateTimeField(blank=True)


    def save(self, *args, **kwargs):
        if not self.slug_modules:
            self.slug_modules = slugify(self.module_name)
        return super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        return f"{self.subjects}.{self.module_name}"
    
#model to add the access type (paid or free)
class Access_type(models.Model):
    access_type = models.CharField(max_length=5, unique=True)
    
    def clean(self):
        if Access_type.objects.count()>=2 and not self.pk:
            raise ValidationError("More Than 2 Access Types is not possible.")
        return super().clean()
    
    def __str__(self):
        return f"{self.access_type}"

#model to add notes.
class NotesNested(models.Model):
    notes_id = models.AutoField(primary_key=True, unique=True)
    module = models.ForeignKey(Modules, on_delete=models.CASCADE, related_name="notes") #Modules = parent of Notes
    access_type = models.ForeignKey(Access_type, on_delete=models.CASCADE)
    title = models.CharField(max_length=200) #To store the title of note,
    description = models.TextField(max_length=600, blank=True) #To store the description of notes 
    pdf = models.FileField(upload_to='pdfs/')
    created_date = models.DateTimeField( blank=True)
    updated_date =  models.DateTimeField( blank=True)
    slug_notes = models.SlugField(blank=True, null=True, max_length=200)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    

    def save(self, *args, **kwargs):
        if not self.slug_notes:
            self.slug_notes = slugify(self.title)
        return super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.title}"
    

#models to add videos
class videosNested(models.Model):
    video_unique_id = models.AutoField(primary_key=True, unique=True)
    module = models.ForeignKey(Modules, on_delete=models.CASCADE, related_name="videos") #Modules = parent of  video.
    access_type = models.ForeignKey(Access_type, on_delete=models.CASCADE)
    video_id = models.CharField(max_length=50, null = True) 
    title = models.CharField(max_length=200) #To store the title video
    description = models.TextField(max_length=600, blank=True) #To store the description of video
    created_date = models.DateTimeField()
    updated_date =  models.DateTimeField()
    slug_videos = models.SlugField(blank=True, null=True)
    is_active = models.BooleanField(default=True, help_text="Make Sure to Set Active-state while creating.")
    
    #Customised manager object
    # objects = ActiveFieldManager()

    def save(self, *args, **kwargs):
        if not self.slug_videos:
            self.slug_videos = slugify(self.video_id)
        return super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.title}.{self.video_id}"

# models to add slider image
class SliderImage(models.Model):
    images_id = models.AutoField(primary_key=True,unique=True)
    images = models.ImageField(upload_to='images/', null=True, blank=True)
    
    def clean(self):
        if SliderImage.objects.count() >= 10 and not self.pk:
            raise ValidationError("More Than 10 Images is not possible.")
        return super().clean()

    def save(self, *args, **kwargs):
        return super().save(*args, **kwargs)
    
# models to add popular course
class PopularCourses(models.Model):
    popular_course_id = models.AutoField(unique=True, primary_key=True)
    course = models.ManyToManyField(FieldOfStudy,blank=True)

# models to store otp
class Otp(models.Model):
    user = models.OneToOneField(RegularUserModel, on_delete=models.CASCADE)
    otp = models.CharField(max_length=6, null=True, blank=True)
    otp_validated = models.BooleanField(default=False, blank=True)

class AbstractOtp(models.Model):
    user = models.OneToOneField(RegularUserModel, on_delete=models.CASCADE)
    abstract_otp = models.CharField(max_length=6, null=True, blank=True)
