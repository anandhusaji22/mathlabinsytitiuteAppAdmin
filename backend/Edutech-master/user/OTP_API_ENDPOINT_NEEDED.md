# OTP API Endpoint Needed

To enable OTP management in the Flutter admin panel, please add the following endpoint to `user/views.py`:

```python
from rest_framework.generics import ListAPIView
from .models import Otp
from rest_framework import serializers

class OtpSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = Otp
        fields = ['id', 'username', 'otp', 'otp_validated']

class OtpListView(ListAPIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAdminUser]
    serializer_class = OtpSerializer
    queryset = Otp.objects.all().select_related('user')
```

And add this URL to `user/urls.py`:

```python
path('otp-list/', OtpListView.as_view(), name='otp-list'),
```

This will allow the Flutter admin panel to fetch all OTP records.

