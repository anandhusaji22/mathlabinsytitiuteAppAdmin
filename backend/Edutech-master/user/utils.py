from django.core.mail import EmailMessage
from rest_framework.response import Response
import random
import json
import requests
from dotenv import load_dotenv
load_dotenv()
import os
#method to send mail.
class Utils:
    @staticmethod
    def send_email(data):
        email = EmailMessage(subject=data['email_subject'], body=data['email_body'], to = [data['to_email']])
        email.send()
        return Response('Email sent successfully!')
    
#method to generate OTP
def otpgenerator():
    rand_no = [x for x in range(10)]
    code_items_for_otp = []

    for i in range(6):
        num = random.choice(rand_no)
        code_items_for_otp.append(num)
        code_string = "".join(str(item) for item in code_items_for_otp)

    return code_string

#method to validate OTP
def checkOTP(otp, saved_otp_instance):
    if saved_otp_instance.otp == otp:
        return True
    else:
        return False
        

#method to delete OTP
def deleteOTP(saved_otp_instance):
    saved_otp_instance.delete()
    

def send_otp(phone):
    """
    This is an helper function to send otp to session stored phones or 
    passed phone number as argument.
    """
    if phone:
        key = otpgenerator()
        phone = str(phone)
        print(f"+91{phone}")
        otp_key = str(key)
        api_key = 'fe3b4756-1275-11ef-8b60-0200cd936042'
        link = f'http://2factor.in/API/V1/{api_key}/SMS/+91{phone}/{otp_key}/'
        result = requests.get(link, verify=False)
        result_string = result.content.decode('utf-8')
        result_json = json.loads(result_string)
        response = result_json['Details']
        return response, otp_key
    else:
        return False
    
def verify_otp(otp_session_id, otp):
    """
    This is an helper function to verify otp
    """
    api_key = 'fe3b4756-1275-11ef-8b60-0200cd936042'
    link = f'https://2factor.in/API/V1/{api_key}/SMS/VERIFY/{otp_session_id}/{otp}'
    result = requests.get(link, verify=False)
    result_string = result.content.decode('utf-8')
    result_json = json.loads(result_string)
    response = result_json['Details']
    print(response)
    return response


import os
from engagespot import Engagespot
def notification(title, users):
    client = Engagespot(api_key=os.getenv('api_key'), api_secret=os.getenv('api_secret'))
    user_ids = [str(user.id) for user in users]  # Convert user IDs to strings

    send_request = {
        "notification": {
            "title":title
        },
        "recipients":user_ids
    }

    response = client.send(send_request)
    return response

# 1. course existing aaytullavark
# 2. date and time 
# course_id = response
# take expirty date and send notification

