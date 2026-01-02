import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart' as Request;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mathlab_admin/Constants/AppHeaders.dart';
import 'package:mathlab_admin/Constants/Strings.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/AccessTypeModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/OtpModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/PopularCourseModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/PurchaseHistoryModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/QuestionTypeModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/SliderImageModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/UserResponseModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/courseModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserListModel.dart';
import 'package:mathlab_admin/main.dart';

class AdminSettingsController extends GetxController {
  // Slider Images
  List<SliderImageModel> sliderImages = [];
  bool isLoadingSliderImages = false;

  // Popular Courses
  PopularCourseModel? popularCourses;
  List<CourseModel> allCourses = [];
  bool isLoadingPopularCourses = false;

  // Access Types
  List<AccessTypeModel> accessTypes = [];
  bool isLoadingAccessTypes = false;

  // Question Types
  List<QuestionTypeModel> questionTypes = [];
  bool isLoadingQuestionTypes = false;

  // User Responses
  List<UserResponseModel> userResponses = [];
  bool isLoadingUserResponses = false;

  // Purchase History
  List<PurchaseHistoryModel> purchaseHistory = [];
  bool isLoadingPurchaseHistory = false;
  String? selectedUsernameForPurchaseHistory;
  List<UserListModel> allUsers = [];
  bool isLoadingUsers = false;

  // OTP Management
  List<OtpModel> otpList = [];
  bool isLoadingOtp = false;

  // Load Slider Images
  Future<void> loadSliderImages() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load slider images");
      return;
    }
    isLoadingSliderImages = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/users/sliderimageadd/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        sliderImages = [];
        if (data is List) {
          for (var item in data) {
            sliderImages.add(SliderImageModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      print("Error loading slider images: $e");
    }
    isLoadingSliderImages = false;
    update();
  }

  // Add Slider Image
  Future<bool> addSliderImage(String? imagePath) async {
    try {
      final dio = Request.Dio();
      Request.FormData formData = Request.FormData();
      
      if (imagePath != null && imagePath.isNotEmpty) {
        if (kIsWeb && imagePath.startsWith("WEB_FILE:")) {
          final firstColonIndex = imagePath.indexOf(":");
          final secondColonIndex = imagePath.indexOf(":", firstColonIndex + 1);
          if (secondColonIndex > firstColonIndex) {
            final filename = imagePath.substring(firstColonIndex + 1, secondColonIndex);
            final base64Bytes = imagePath.substring(secondColonIndex + 1);
            final bytes = base64Decode(base64Bytes);
            formData.files.add(MapEntry(
              'images',
              Request.MultipartFile.fromBytes(bytes, filename: filename),
            ));
          }
        } else if (!kIsWeb) {
          formData.files.add(MapEntry(
            'images',
            await Request.MultipartFile.fromFile(imagePath, filename: imagePath.split("/").last),
          ));
        }
      }

      final response = await dio.post(
        "$endpoint/users/sliderimageadd/",
        data: formData,
        options: Request.Options(headers: ImageHeader),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadSliderImages();
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding slider image: $e");
      return false;
    }
  }

  // Delete Slider Image
  Future<bool> deleteSliderImage(int imagesId) async {
    try {
      final response = await http.delete(
        Uri.parse("$endpoint/users/sliderimageadd/$imagesId"),
        headers: AuthHeader,
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        await loadSliderImages();
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting slider image: $e");
      return false;
    }
  }

  // Load Popular Courses
  Future<void> loadPopularCourses() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load popular courses");
      return;
    }
    isLoadingPopularCourses = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/users/popularcourseadd/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          popularCourses = PopularCourseModel.fromJson(data[0] as Map<String, dynamic>);
        } else if (data is Map) {
          popularCourses = PopularCourseModel.fromJson(data as Map<String, dynamic>);
        }
      }
      // Also load all courses for selection
      await loadAllCourses();
    } catch (e) {
      print("Error loading popular courses: $e");
    }
    isLoadingPopularCourses = false;
    update();
  }

  Future<void> loadAllCourses() async {
    try {
      final response = await http.get(
        Uri.parse("$endpoint/users/fieldofstudy/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        allCourses = [];
        for (var data in res) {
          allCourses.add(CourseModel.fromJson(data));
        }
      }
    } catch (e) {
      print("Error loading all courses: $e");
    }
  }

  // Update Popular Courses
  Future<bool> updatePopularCourses(List<int> courseIds) async {
    try {
      final response = await http.put(
        Uri.parse("$endpoint/users/popularcourseadd/${popularCourses?.popularCourseId ?? ''}"),
        headers: AuthHeader,
        body: json.encode({"course": courseIds}),
      );
      if (response.statusCode == 200) {
        await loadPopularCourses();
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating popular courses: $e");
      return false;
    }
  }

  // Create Popular Courses
  Future<bool> createPopularCourses(List<int> courseIds) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/users/popularcourseadd/"),
        headers: AuthHeader,
        body: json.encode({"course": courseIds}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadPopularCourses();
        return true;
      }
      return false;
    } catch (e) {
      print("Error creating popular courses: $e");
      return false;
    }
  }

  // Load Access Types
  Future<void> loadAccessTypes() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load access types");
      return;
    }
    isLoadingAccessTypes = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/users/access-type-add/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        accessTypes = [];
        if (data is List) {
          for (var item in data) {
            accessTypes.add(AccessTypeModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      print("Error loading access types: $e");
    }
    isLoadingAccessTypes = false;
    update();
  }

  // Add Access Type
  Future<bool> addAccessType(String accessType) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/users/access-type-add/"),
        headers: AuthHeader,
        body: json.encode({"access_type": accessType}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadAccessTypes();
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding access type: $e");
      return false;
    }
  }

  // Delete Access Type
  Future<bool> deleteAccessType(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$endpoint/users/access-type-add/$id"),
        headers: AuthHeader,
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        await loadAccessTypes();
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting access type: $e");
      return false;
    }
  }

  // Load Question Types
  Future<void> loadQuestionTypes() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load question types");
      return;
    }
    isLoadingQuestionTypes = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/exam/question-type/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        questionTypes = [];
        if (data is List) {
          for (var item in data) {
            questionTypes.add(QuestionTypeModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      print("Error loading question types: $e");
    }
    isLoadingQuestionTypes = false;
    update();
  }

  // Add Question Type
  Future<bool> addQuestionType(String questionType) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/exam/question-type/"),
        headers: AuthHeader,
        body: json.encode({"question_type": questionType}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadQuestionTypes();
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding question type: $e");
      return false;
    }
  }

  // Delete Question Type
  Future<bool> deleteQuestionType(String slug) async {
    try {
      final response = await http.delete(
        Uri.parse("$endpoint/exam/question-type/$slug/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        await loadQuestionTypes();
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting question type: $e");
      return false;
    }
  }

  // Load User Responses
  Future<void> loadUserResponses() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load user responses");
      return;
    }
    isLoadingUserResponses = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/applicationview/userresponses/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        userResponses = [];
        if (data is List) {
          for (var item in data) {
            userResponses.add(UserResponseModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      print("Error loading user responses: $e");
    }
    isLoadingUserResponses = false;
    update();
  }

  // Load All Users
  Future<void> loadAllUsers() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load users");
      return;
    }
    isLoadingUsers = true;
    update();
    try {
      final response = await http.get(
        Uri.parse("$endpoint/applicationview/get-all-user-list/"),
        headers: AuthHeader,
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        allUsers = [];
        if (data is Map && data['results'] != null) {
          for (var item in data['results']) {
            allUsers.add(UserListModel.fromJson(item));
          }
        } else if (data is List) {
          for (var item in data) {
            allUsers.add(UserListModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      print("Error loading users: $e");
    }
    isLoadingUsers = false;
    update();
  }

  // Load Purchase History
  Future<void> loadPurchaseHistory({String? username}) async {
    if (token.isEmpty) {
      print("Token is empty, cannot load purchase history");
      return;
    }
    
    if (username == null || username.isEmpty) {
      print("Username is required for purchase history");
      purchaseHistory = [];
      update();
      return;
    }
    
    isLoadingPurchaseHistory = true;
    update();
    try {
      String url = "$endpoint/applicationview/userlist/$username/purchase_history/";
      final response = await http.get(
        Uri.parse(url),
        headers: AuthHeader,
      );
      print("Purchase history response status: ${response.statusCode}");
      print("Purchase history response body: ${response.body}");
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        purchaseHistory = [];
        if (data is List) {
          for (var item in data) {
            purchaseHistory.add(PurchaseHistoryModel.fromJson(item));
          }
        } else if (data is Map) {
          // Handle different response formats
          if (data['purchased_dates'] != null) {
            for (var item in data['purchased_dates']) {
              purchaseHistory.add(PurchaseHistoryModel.fromJson(item));
            }
          } else if (data['results'] != null) {
            for (var item in data['results']) {
              purchaseHistory.add(PurchaseHistoryModel.fromJson(item));
            }
          } else {
            // Try to parse as single purchase history item
            purchaseHistory.add(PurchaseHistoryModel.fromJson(data as Map<String, dynamic>));
          }
        }
      } else {
        print("Failed to load purchase history: ${response.statusCode}");
        purchaseHistory = [];
      }
    } catch (e) {
      print("Error loading purchase history: $e");
      purchaseHistory = [];
    }
    isLoadingPurchaseHistory = false;
    update();
  }

  // Load OTP List
  // First tries direct OTP endpoint, then falls back to user details
  Future<void> loadOtpList() async {
    if (token.isEmpty) {
      print("Token is empty, cannot load OTP list");
      return;
    }
    isLoadingOtp = true;
    update();
    try {
      // Try direct OTP endpoint first (if backend endpoint exists)
      try {
        final otpResponse = await http.get(
          Uri.parse("$endpoint/users/otp-list/"),
          headers: AuthHeader,
        ).timeout(Duration(seconds: 10));
        
        if (otpResponse.statusCode == 200) {
          var otpData = json.decode(otpResponse.body);
          otpList = [];
          
          if (otpData is List) {
            for (var item in otpData) {
              otpList.add(OtpModel.fromJson(item));
            }
          } else if (otpData is Map && otpData['results'] != null) {
            for (var item in otpData['results']) {
              otpList.add(OtpModel.fromJson(item));
            }
          }
          
          isLoadingOtp = false;
          update();
          return; // Successfully loaded from direct endpoint
        }
      } catch (e) {
        print("Direct OTP endpoint not available, trying alternative method: $e");
      }
      
      // Fallback: Try to fetch from user details
      // This is slower but works if OTP data is included in user responses
      final usersResponse = await http.get(
        Uri.parse("$endpoint/users/viewallusers/"),
        headers: AuthHeader,
      );
      
      print("Users response status: ${usersResponse.statusCode}");
      
      if (usersResponse.statusCode == 200) {
        var usersData = json.decode(usersResponse.body);
        otpList = [];
        
        // Handle paginated response
        List<dynamic> users = [];
        if (usersData is Map && usersData['results'] != null) {
          users = usersData['results'];
        } else if (usersData is List) {
          users = usersData;
        }
        
        // Fetch detailed user info which might include OTP
        // Limit to first 100 users to avoid too many API calls
        int limit = users.length > 100 ? 100 : users.length;
        for (int i = 0; i < limit; i++) {
          var userData = users[i];
          String? username = userData['username'];
          
          if (username != null && username.isNotEmpty) {
            try {
              // Try user detail endpoint
              final userDetailResponse = await http.get(
                Uri.parse("$endpoint/users/viewallusers/$username/"),
                headers: AuthHeader,
              ).timeout(Duration(seconds: 5));
              
              if (userDetailResponse.statusCode == 200) {
                var userDetail = json.decode(userDetailResponse.body);
                
                // Check various possible OTP field names
                dynamic otpData;
                if (userDetail['otp'] != null) {
                  otpData = userDetail['otp'];
                } else if (userDetail['otps'] != null) {
                  otpData = userDetail['otps'];
                } else if (userDetail['otp_record'] != null) {
                  otpData = userDetail['otp_record'];
                }
                
                if (otpData != null) {
                  // Handle both object and direct value
                  if (otpData is Map) {
                    otpList.add(OtpModel.fromJson({
                      'id': otpData['id'],
                      'user': {'username': username},
                      'otp': otpData['otp'],
                      'otp_validated': otpData['otp_validated'] ?? false,
                    }));
                  } else if (otpData is String && otpData.isNotEmpty && otpData != '000000') {
                    // If OTP is returned as a string directly (and not default)
                    otpList.add(OtpModel(
                      id: userData['id'],
                      username: username,
                      otp: otpData,
                      otpValidated: userDetail['otp_validated'] ?? false,
                    ));
                  }
                }
              }
            } catch (e) {
              print("Error fetching OTP for user $username: $e");
              // Continue with next user
            }
          }
        }
      }
    } catch (e) {
      print("Error loading OTP list: $e");
      otpList = [];
    }
    isLoadingOtp = false;
    update();
  }
}

