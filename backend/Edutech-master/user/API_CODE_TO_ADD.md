# API Code to Add - Implementation Guide

## 1. User Statistics API

### Add to `regularuserview/views.py`:

```python
from datetime import timedelta
from django.utils import timezone

class UserStatisticsView(APIView):
    permission_classes = [IsAdminUser]
    
    def get(self, request):
        """
        Get user statistics: total users, new users per day/week/month
        """
        now = timezone.now()
        today = now.date()
        week_ago = today - timedelta(days=7)
        month_ago = today - timedelta(days=30)
        
        # Total users (excluding superusers)
        total_users = RegularUserModel.objects.filter(is_superuser=False).count()
        
        # New users today
        new_users_today = RegularUserModel.objects.filter(
            is_superuser=False,
            date_joined__date=today
        ).count()
        
        # New users this week
        new_users_this_week = RegularUserModel.objects.filter(
            is_superuser=False,
            date_joined__date__gte=week_ago
        ).count()
        
        # New users this month
        new_users_this_month = RegularUserModel.objects.filter(
            is_superuser=False,
            date_joined__date__gte=month_ago
        ).count()
        
        return Response({
            'total_users': total_users,
            'new_users_today': new_users_today,
            'new_users_this_week': new_users_this_week,
            'new_users_this_month': new_users_this_month
        }, status=status.HTTP_200_OK)
```

### Add to `regularuserview/urls.py`:

```python
from .views import UserStatisticsView  # Add to imports

urlpatterns = [
    # ... existing paths ...
    path('user-statistics/', UserStatisticsView.as_view(), name='user-statistics'),
]
```

---

## 2. User Progress Tracking API

### Add to `regularuserview/views.py`:

```python
from django.db.models import Count, Q
from django.db.models.functions import Coalesce

class UserProgressView(APIView):
    permission_classes = [IsAdminUser]
    
    def get(self, request, user_id):
        """
        Get user's progress: videos watched, exams attended per course
        """
        try:
            user = RegularUserModel.objects.get(id=user_id, is_superuser=False)
        except RegularUserModel.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        try:
            user_profile = UserProfile.objects.get(user=user)
        except UserProfile.DoesNotExist:
            return Response({
                'user_id': user.id,
                'username': user.username,
                'courses': []
            })
        
        courses_data = []
        
        # Get all purchased courses
        purchased_courses = user_profile.purchased_courses.all()
        
        for course in purchased_courses:
            # Get all modules in this course
            modules = Modules.objects.filter(
                subjects__field_of_study=course
            )
            
            # Count total videos and exams
            total_videos = videosNested.objects.filter(
                module__in=modules,
                is_active=True
            ).count()
            
            total_exams = Exam.objects.filter(
                module__in=modules,
                is_active=True
            ).count()
            
            # Count videos watched (assuming you track this - you may need to add a model for this)
            # For now, we'll use a placeholder. You'll need to implement video watch tracking
            videos_watched = 0  # TODO: Implement video watch tracking
            
            # Count exams attended (from UserResponse)
            exams_attended = UserResponse.objects.filter(
                user=user,
                exam_id__in=[str(exam.exam_unique_id) for exam in Exam.objects.filter(module__in=modules)]
            ).distinct().count()
            
            # Calculate progress percentage
            total_items = total_videos + total_exams
            completed_items = videos_watched + exams_attended
            progress_percentage = (completed_items / total_items * 100) if total_items > 0 else 0.0
            
            courses_data.append({
                'course_id': course.course_unique_id,
                'course_name': course.field_of_study,
                'videos_watched': videos_watched,
                'total_videos': total_videos,
                'exams_attended': exams_attended,
                'total_exams': total_exams,
                'progress_percentage': round(progress_percentage, 2)
            })
        
        return Response({
            'user_id': user.id,
            'username': user.username,
            'courses': courses_data
        }, status=status.HTTP_200_OK)
```

### Add to `regularuserview/urls.py`:

```python
from .views import UserProgressView  # Add to imports

urlpatterns = [
    # ... existing paths ...
    path('user-progress/<int:user_id>/', UserProgressView.as_view(), name='user-progress'),
]
```

**Note**: You'll need to implement video watch tracking. Consider adding a `VideoWatch` model to track which videos users have watched.

---

## 3. Bulk Extend Course Duration API

### Add to `user/views.py`:

```python
class BulkExtendCourseDuration(APIView):
    permission_classes = [IsAdminUser]
    
    def post(self, request):
        """
        Extend course duration for multiple users
        Body: {
            "user_ids": [1, 2, 3],
            "course_id": 123,
            "additional_days": 30
        }
        """
        user_ids = request.data.get('user_ids', [])
        course_id = request.data.get('course_id')
        additional_days = int(request.data.get('additional_days', 0))
        
        if not user_ids or not course_id:
            return Response({
                'error': 'user_ids and course_id are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            course = FieldOfStudy.objects.get(course_unique_id=course_id)
        except FieldOfStudy.DoesNotExist:
            return Response({'error': 'Course not found'}, status=status.HTTP_404_NOT_FOUND)
        
        updated_count = 0
        errors = []
        
        for user_id in user_ids:
            try:
                user = RegularUserModel.objects.get(id=user_id, is_superuser=False)
                user_profile, created = UserProfile.objects.get_or_create(user=user)
                
                # Get or create PurchasedDate for this user and course
                purchased_date, created = PurchasedDate.objects.get_or_create(
                    user_profile=user_profile,
                    course=course,
                    defaults={
                        'date_of_purchase': timezone.now(),
                        'expiration_date': timezone.now() + timedelta(days=additional_days),
                        'isPaid': True
                    }
                )
                
                # Extend expiration date
                if not created:
                    purchased_date.expiration_date += timedelta(days=additional_days)
                    purchased_date.save()
                
                updated_count += 1
                
            except RegularUserModel.DoesNotExist:
                errors.append(f'User {user_id} not found')
            except Exception as e:
                errors.append(f'Error updating user {user_id}: {str(e)}')
        
        return Response({
            'message': f'Successfully updated {updated_count} user(s)',
            'updated_count': updated_count,
            'errors': errors if errors else None
        }, status=status.HTTP_200_OK)
```

### Add to `user/urls.py`:

```python
from .views import BulkExtendCourseDuration  # Add to imports

urlpatterns = [
    # ... existing paths ...
    path('bulk-extend-course/', BulkExtendCourseDuration.as_view(), name='bulk-extend-course'),
]
```

---

## 4. Enhance GetAllUser API - Add Paid/Unpaid Filter

### Modify `GetAllUser` in `regularuserview/views.py`:

```python
class GetAllUser(APIView):
    permission_classes = [IsAdminUser]
    serializer_class = RegularUserSerializer
    def get(self, request):
        username = request.GET.get('username', '')
        phone_number = request.GET.get('phone_number', '')
        name = request.GET.get('name', '')
        course_id = request.GET.get('course_id', '')
        exam_id = request.GET.get('exam_id', '')
        is_paid = request.GET.get('is_paid', None)  # NEW: Add paid filter
        
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
            # NEW: Filter by paid status if course_id is provided
            if is_paid is not None:
                is_paid_bool = is_paid.lower() == 'true'
                data = data.filter(
                    user_profile__purchased_dates__course_id=course_id,
                    user_profile__purchased_dates__isPaid=is_paid_bool
                ).distinct()
        if exam_id:
            data = data.filter(user_profile__purchased_dates__exam_id = exam_id)
            # NEW: Filter by paid status if exam_id is provided
            if is_paid is not None:
                is_paid_bool = is_paid.lower() == 'true'
                data = data.filter(
                    user_profile__purchased_dates__exam_id=exam_id,
                    user_profile__purchased_dates__isPaid=is_paid_bool
                ).distinct()

        pagination = CustomPagination()

        paginator_data = pagination.paginate_queryset(data, request)

        ret_data = CustomGetUserListSerializer(paginator_data, many = True)
        
        return pagination.get_paginated_response(ret_data.data)
```

---

## Summary of Changes

### Files to Modify:
1. ✅ `regularuserview/views.py` - Add `UserStatisticsView` and `UserProgressView`
2. ✅ `regularuserview/urls.py` - Add routes for new views
3. ✅ `user/views.py` - Add `BulkExtendCourseDuration`
4. ✅ `user/urls.py` - Add route for bulk extend
5. ✅ `regularuserview/views.py` - Enhance `GetAllUser` with paid filter

### Import Statements Needed:

**In `regularuserview/views.py`:**
```python
from datetime import timedelta
from django.utils import timezone
from user.models import Modules, videosNested
from exam.models import Exam
```

**In `user/views.py`:**
```python
from datetime import timedelta
from regularuserview.models import UserProfile, PurchasedDate
```

---

## Testing Checklist

After implementing, test each API:

1. ✅ User Statistics: `GET /applicationview/user-statistics/`
2. ✅ User Progress: `GET /applicationview/user-progress/<user_id>/`
3. ✅ Bulk Extend: `POST /users/bulk-extend-course/`
4. ✅ Paid Filter: `GET /applicationview/get-all-user-list/?course_id=123&is_paid=true`

---

## Notes

- **Video Watch Tracking**: The progress API assumes you'll implement video watch tracking. You may need to add a model to track which videos users have watched.
- **Error Handling**: All APIs include proper error handling
- **Permissions**: All APIs require `IsAdminUser` permission
- **Pagination**: User statistics and progress APIs don't need pagination, but GetAllUser already has it

