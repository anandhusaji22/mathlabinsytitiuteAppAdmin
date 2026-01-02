import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:mathlab_admin/Constants/AppHeaders.dart';
import 'package:mathlab_admin/Constants/Strings.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Service/controller.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/CUserListModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/IndividualUserModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserListModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserProfileModel.dart';
import 'package:excel/excel.dart' as ex;
import 'package:mathlab_admin/Screen/ProfileView/View/IndividualProfileView.dart';

// Conditional import for web
import 'dart:html' as html if (dart.library.html) 'dart:html';

class ProfileController extends GetxController {
  List<UserProfileModel> userList = [];
  List<UserListModel> SearchStudentList = [];
  UserListModel? selectedProfileModel;
  IndividualUserModel? individualUser;
  bool loading = false;
  bool paidOnlyFilter = false; // Filter for paid users only
  
  // Sorting state
  String? sortColumn;
  bool sortAscending = true;
  
  // Search suggestions
  List<String> searchSuggestions = [];
  
  TextEditingController courseText = TextEditingController();
  TextEditingController exportCourseText = TextEditingController();
  TextEditingController notificationCourseText = TextEditingController();
  TextEditingController NotificationMessage = TextEditingController();
  TextEditingController NotificationBody = TextEditingController();
  TextEditingController NotificationDate = TextEditingController();
  
  // Advanced filter controllers
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController weekFilterController = TextEditingController();
  TextEditingController paymentStatusController = TextEditingController(); // "all", "paid", "unpaid"
  
  var profileDatas;

  String getCourseID(String courseName) {
    HomeController ctrl = Get.put(HomeController());
    for (var data in ctrl.CourseList) {
      if (data.fieldOfStudy == courseName)
        return data.courseUniqueId.toString();
    }
    return "";
  }

  fetchUser(String email) async {
    individualUser = null;
    update();
    final Response = await get(
        Uri.parse(endpoint +
            "applicationview/get-all-user-list/${selectedProfileModel!.username!}"),
        headers: AuthHeader);

    if (Response.statusCode == 200) {
      individualUser = IndividualUserModel.fromJson(json.decode(Response.body));
      update();
    }
  }

  sendNotificationActiveCourse({bool isexpired = false}) async {
    if (notificationCourseText.text.isNotEmpty &&
        NotificationMessage.text.isNotEmpty &&
        NotificationBody.text.isNotEmpty) {
      //  final Response = await
      String parms = "";

      if (notificationCourseText.text != "All") {
        parms = "&course_name=${notificationCourseText.text}&";
      }
      if (isexpired) parms = parms + "show_expired=True";

      print(parms);
      final Response = await get(
          Uri.parse(endpoint + "users/get-remaning-dates?course=true${parms}"),
          headers: AuthHeader);

      if (Response.statusCode == 200) {
        var data = json.decode(Response.body);

        List<CUserlistModel> clist = [];
        for (var user in data) {
          clist.add(CUserlistModel.fromJson(user));
        }
        print(clist);

        final notResponse =
            await post(Uri.parse("https://api.engagespot.com/v3/notifications"),
                headers: {
                  "X-ENGAGESPOT-API-KEY": "4j76o2qeddbwmfqat1pczp",
                  'Accept': 'application/json',
                  "Content-Type": "application/json",
                  "X-ENGAGESPOT-API-SECRET":
                      "9cjcp7c8a7gptpi1eknc9m0j2g22ga2bb5hi0eh90a8j8b65"
                },
                body: json.encode({
                  "notification": {
                    "title": NotificationMessage.text.toString(),
                    "message": NotificationBody.text.toString(),
                  },
                  "recipients": [for (var data in clist) data.username]
                }));

        print(notResponse.body);
        print(notResponse.statusCode);

        if (Response.statusCode == 200 || Response.statusCode == 201) {
          NotificationBody.text = "";
          NotificationMessage.text = "";
          update();
          ShowToast(
              title: "Completed",
              body: "Notification has been send succeessfully");
        }
      }
    } else {
      ShowToast(
          title: "Notification Send Failed",
          body: "Course and title are mandatory");
    }
  }

  exportToExcel(String courseName, {bool expired = false}) async {
    try {
      // For web, use download instead of directory picker
      if (kIsWeb) {
        await exportToExcelWeb(courseName, expired: expired);
        return;
      }
      
      final result = await FilePicker.platform.getDirectoryPath();
      String parm = "";
      if (result != null) {
        if (courseName != "" && courseName != "All") parm = "&course_name=$courseName";
        String param2 = "";
        if (expired) param2 = "show_expired=True";
        
        final Response = await get(
            Uri.parse(
                endpoint + "users/get-remaning-dates?course=true$parm$param2"),
            headers: AuthHeader);

        if (Response.statusCode == 200) {
          var data = json.decode(Response.body);

          List<CUserlistModel> clist = [];
          for (var user in data) {
            clist.add(CUserlistModel.fromJson(user));
          }

          if (clist.isEmpty) {
            ShowToast(title: "No Data", body: "No users found for this course");
            return;
          }

          saveExcel(clist, result, expired: expired);
        } else {
          ShowToast(title: "Export Failed", body: "Failed to fetch user data. Status: ${Response.statusCode}");
        }
      }
    } catch (e) {
      print("Export error: $e");
      ShowToast(title: "Export Failed", body: "Error: ${e.toString()}");
    }
  }

  exportToExcelWeb(String courseName, {bool expired = false}) async {
    try {
      String parm = "";
      if (courseName != "" && courseName != "All") parm = "&course_name=$courseName";
      String param2 = "";
      if (expired) param2 = "show_expired=True";
      
      final Response = await get(
          Uri.parse(
              endpoint + "users/get-remaning-dates?course=true$parm$param2"),
          headers: AuthHeader);

      if (Response.statusCode == 200) {
        var data = json.decode(Response.body);

        List<CUserlistModel> clist = [];
        for (var user in data) {
          clist.add(CUserlistModel.fromJson(user));
        }

        if (clist.isEmpty) {
          ShowToast(title: "No Data", body: "No users found for this course");
          return;
        }

        // Create Excel file
        var excel = ex.Excel.createExcel();
        var sheet = excel['Sheet1'];

        // Add headers
        sheet.cell(ex.CellIndex.indexByString("A1")).value = ex.TextCellValue("User ID");
        sheet.cell(ex.CellIndex.indexByString("B1")).value = ex.TextCellValue("Name");
        sheet.cell(ex.CellIndex.indexByString("C1")).value = ex.TextCellValue("Email");
        sheet.cell(ex.CellIndex.indexByString("D1")).value = ex.TextCellValue("Phone");
        sheet.cell(ex.CellIndex.indexByString("E1")).value = ex.TextCellValue("Course Name");
        if (!expired) {
          sheet.cell(ex.CellIndex.indexByString("F1")).value = ex.TextCellValue("Expiry Date");
        }

        // Add data
        for (int i = 0; i < clist.length; i++) {
          CUserlistModel data = clist[i];
          sheet.cell(ex.CellIndex.indexByString("A${i + 2}")).value = ex.TextCellValue(data.userId.toString());
          sheet.cell(ex.CellIndex.indexByString("B${i + 2}")).value = ex.TextCellValue(data.name ?? " ");
          sheet.cell(ex.CellIndex.indexByString("C${i + 2}")).value = ex.TextCellValue(data.username ?? "");
          sheet.cell(ex.CellIndex.indexByString("D${i + 2}")).value = ex.TextCellValue(data.phoneNumber ?? "");
          sheet.cell(ex.CellIndex.indexByString("E${i + 2}")).value = ex.TextCellValue(data.courseName ?? "");
          if (!expired) {
            sheet.cell(ex.CellIndex.indexByString("F${i + 2}")).value = ex.TextCellValue(
                DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: data.noOfDaysToExpire ?? 0))));
          }
        }

        // Download file for web
        var fileBytes = excel.save();
        if (fileBytes != null) {
          String filename = DateFormat('yyyy-MM-dd-hh:mm:ss').format(DateTime.now());
          filename = "StudentList_$filename.xlsx";
          
          // Create download link for web
          final blob = html.Blob([fileBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = filename;
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
          
          ShowToast(title: "Completed", body: "Student List Downloaded Successfully");
        }
      } else {
        ShowToast(title: "Export Failed", body: "Failed to fetch user data. Status: ${Response.statusCode}");
      }
    } catch (e) {
      print("Export error: $e");
      ShowToast(title: "Export Failed", body: "Error: ${e.toString()}");
    }
  }

  saveExcel(List<CUserlistModel> userlist, String path,
      {bool expired = false}) async {
    var excel = ex.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers to the worksheet
    sheet.cell(ex.CellIndex.indexByString("A1")).value =
        ex.TextCellValue("User ID");
    sheet.cell(ex.CellIndex.indexByString("B1")).value =
        ex.TextCellValue("Name");
    sheet.cell(ex.CellIndex.indexByString("C1")).value =
        ex.TextCellValue("Email");
    sheet.cell(ex.CellIndex.indexByString("D1")).value =
        ex.TextCellValue("Phone");
    sheet.cell(ex.CellIndex.indexByString("E1")).value =
        ex.TextCellValue("Course Name");
    if (!expired)
      sheet.cell(ex.CellIndex.indexByString("F1")).value =
          ex.TextCellValue("Expiry Date");

    // Add data to the worksheet
    for (int i = 0; i < userlist.length; i++) {
      CUserlistModel data = userlist[i];
      sheet.cell(ex.CellIndex.indexByString("A${i + 2}")).value =
          ex.TextCellValue(data.userId.toString());
      sheet.cell(ex.CellIndex.indexByString("B${i + 2}")).value =
          ex.TextCellValue(data.name ?? " ");
      sheet.cell(ex.CellIndex.indexByString("C${i + 2}")).value =
          ex.TextCellValue(data.username ?? "");
      sheet.cell(ex.CellIndex.indexByString("D${i + 2}")).value =
          ex.TextCellValue(data.phoneNumber ?? "");
      sheet.cell(ex.CellIndex.indexByString("E${i + 2}")).value =
          ex.TextCellValue(data.courseName ?? "");
      if (!expired)
        sheet.cell(ex.CellIndex.indexByString("F${i + 2}")).value =
            ex.TextCellValue(DateFormat('yyyy MM dd').format(DateTime.now()
                .add(Duration(days: data.noOfDaysToExpire ?? 0))));
    }

    // Directory? documentsDirectory = await getDownloadsDirectory();
    // print(documentsDirectory!.path);
// when you are in flutter web then save() downloads the excel file.

// Call function save() to download the file
    // var fileBytes = excel.save();
    // var directory = await getApplicationDocumentsDirectory();
    String filename = DateFormat('yyyy-MM-dd-hh:mm:ss').format(DateTime.now());
    filename = "StudentList_$filename";
    String excelFilePath = "${path}/$filename.xlsx";
    File file = File(excelFilePath);
    await file.writeAsBytes(excel.encode()!);
    print(excel.encode());
    print(file.path);

    ShowToast(title: "Completed", body: "Student List Exported Successfully");

    // FlutterPlatformAlert.showAlert(
    //     windowTitle: "File Exported",
    //     text: "Your exported file is save in ${file.path} ");
  }

  loadProfiles({String search = "", bool paidOnly = false}) async {
    String parm = "";

    // Improved search logic: Check for email, phone, or name
    if (search.contains("@")) {
      // Email search - support partial matches
      parm = "username=${search}";
    } else if (RegExp(r'^[0-9+\-\s()]+$').hasMatch(search.replaceAll(' ', ''))) {
      // Phone number search (contains digits, +, -, spaces, parentheses)
      parm = "phone_number=${search}";
    } else if (search.isNotEmpty) {
      // Name search - support partial matches
      parm = "name=${search}";
    }

    // Determine paid filter from payment status controller or paidOnly parameter
    bool usePaidFilter = paidOnly;
    if (paymentStatusController.text.isNotEmpty) {
      usePaidFilter = paymentStatusController.text.toLowerCase() == "paid";
    }
    String paidFilter = usePaidFilter ? "&is_paid=true" : "";

    SearchStudentList.clear();
    String courseIdParam = getCourseID(courseText.text);
    String courseParam = courseIdParam.isNotEmpty ? "&course_id=$courseIdParam" : "";
    
    // Add date filters
    String dateFilter = "";
    if (startDateController.text.isNotEmpty) {
      dateFilter += "&start_date=${startDateController.text}";
    }
    if (endDateController.text.isNotEmpty) {
      dateFilter += "&end_date=${endDateController.text}";
    }
    
    // Build the full URL with all parameters
    String url = endpoint + "applicationview/get-all-user-list";
    List<String> params = [];
    if (parm.isNotEmpty) params.add(parm);
    if (courseParam.isNotEmpty) params.add(courseParam.replaceFirst("&", ""));
    if (paidFilter.isNotEmpty) params.add(paidFilter.replaceFirst("&", ""));
    if (dateFilter.isNotEmpty) params.add(dateFilter.replaceFirst("&", ""));
    
    String fullUrl = params.isNotEmpty ? "$url?${params.join("&")}" : url;
    
    print("Search URL: $fullUrl");
    print("Search params: $parm, Course: ${courseText.text}, Paid only: $usePaidFilter, Date range: ${startDateController.text} to ${endDateController.text}");
    
    final Response = await get(Uri.parse(fullUrl), headers: AuthHeader);
    print(Response.body);
    print(Response.statusCode);
    if (Response.statusCode == 200) {
      var js = json.decode(Response.body);
      profileDatas = js;
      
      // Use Set to track unique users and prevent duplicates
      Set<String> seenUsernames = {};
      List<UserListModel> uniqueUsers = [];
      
      for (var data in js["results"]) {
        UserListModel user = UserListModel.fromJson(data);
        // Check if user already exists (by username/email)
        if (user.username != null && !seenUsernames.contains(user.username)) {
          seenUsernames.add(user.username!);
          uniqueUsers.add(user);
        }
      }
      
      SearchStudentList = uniqueUsers;
      _sortUserList(); // Apply sorting after loading
      
      // Update suggestions if there's a search query
      if (search.isNotEmpty) {
        updateSearchSuggestions(search);
      }
      
      update();
    }
  }

  // Sort user list based on current sort column and direction
  void _sortUserList() {
    if (sortColumn == null) return;
    
    SearchStudentList.sort((a, b) {
      int comparison = 0;
      
      switch (sortColumn) {
        case 'name':
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case 'email':
          comparison = (a.username ?? '').compareTo(b.username ?? '');
          break;
        case 'phone':
          comparison = (a.phoneNumber ?? '').compareTo(b.phoneNumber ?? '');
          break;
        case 'enrolled':
          int aCount = (a.countOfCoursesPurchased ?? 0) + (a.countOfExamsPurchased ?? 0);
          int bCount = (b.countOfCoursesPurchased ?? 0) + (b.countOfExamsPurchased ?? 0);
          comparison = aCount.compareTo(bCount);
          break;
        default:
          return 0;
      }
      
      return sortAscending ? comparison : -comparison;
    });
  }

  // Method to handle column sorting
  void sortUsers(String column) {
    if (sortColumn == column) {
      // Toggle sort direction if clicking same column
      sortAscending = !sortAscending;
    } else {
      // Set new column and default to ascending
      sortColumn = column;
      sortAscending = true;
    }
    _sortUserList();
    update();
  }

  // Generate search suggestions based on current user list
  void updateSearchSuggestions(String query) {
    if (query.isEmpty) {
      searchSuggestions = [];
      update();
      return;
    }

    Set<String> suggestions = {};
    query = query.toLowerCase().trim();

    // Use all loaded users for suggestions
    List<UserListModel> usersToSearch = SearchStudentList;
    
    // If no users loaded yet, try to use any cached data
    if (usersToSearch.isEmpty && profileDatas != null && profileDatas["results"] != null) {
      try {
        for (var data in profileDatas["results"]) {
          usersToSearch.add(UserListModel.fromJson(data));
        }
      } catch (e) {
        print("Error loading suggestions: $e");
      }
    }

    for (var user in usersToSearch) {
      // Suggest by name
      if (user.name != null && user.name!.toLowerCase().contains(query)) {
        suggestions.add(user.name!);
      }
      // Suggest by email
      if (user.username != null && user.username!.toLowerCase().contains(query)) {
        suggestions.add(user.username!);
      }
      // Suggest by phone
      if (user.phoneNumber != null && user.phoneNumber!.contains(query)) {
        suggestions.add(user.phoneNumber!);
      }
    }

    // Limit suggestions to 10 and sort them
    searchSuggestions = suggestions.take(10).toList()..sort();
    print("Search suggestions generated: ${searchSuggestions.length} for query: $query");
    update();
  }

  loadProfilesMore() async {
    final Response =
        await get(Uri.parse(profileDatas["next"]), headers: AuthHeader);

    if (Response.statusCode == 200) {
      var js = json.decode(Response.body);
      profileDatas = js;
      
      // Use Set to track unique users and prevent duplicates
      Set<String> seenUsernames = {};
      for (var user in SearchStudentList) {
        if (user.username != null) {
          seenUsernames.add(user.username!);
        }
      }
      
      for (var data in js["results"]) {
        UserListModel user = UserListModel.fromJson(data);
        // Check if user already exists (by username/email)
        if (user.username != null && !seenUsernames.contains(user.username)) {
          seenUsernames.add(user.username!);
          SearchStudentList.add(user);
        }
      }
      _sortUserList(); // Apply sorting after loading more
      update();
    }
  }

  String getEnrollCount(UserProfileModel up) {
    int courseC = 0;
    int examc = 0;
    if (up.purchaseList != null) {
      if (up.purchaseList!.purchasedCourses != null)
        courseC = up.purchaseList!.purchasedCourses!.length;
      if (up.purchaseList!.purchasedExams != null)
        examc = up.purchaseList!.purchasedExams!.length;
    }

    return "$courseC , $examc";
  }

  String DateView(String dt) {
    return DateFormat.yMMMMd().format(DateTime.parse(dt).toLocal());
  }

  // Update user email
  Future<bool> updateUserEmail(String username, String newEmail) async {
    try {
      final Response = await patch(
        Uri.parse(endpoint + "users/viewallusers/$username/"),
        headers: {
          ...AuthHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': newEmail,
        }),
      );

      if (Response.statusCode == 200) {
        update();
        return true;
      } else {
        var errorData = json.decode(Response.body);
        String errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Failed to update email';
        ShowToast(title: "Error", body: errorMessage);
        return false;
      }
    } catch (e) {
      ShowToast(title: "Error", body: "Failed to update email: ${e.toString()}");
      return false;
    }
  }

  // Update user password
  Future<bool> updateUserPassword(String username, String newPassword, String confirmPassword) async {
    try {
      final Response = await patch(
        Uri.parse(endpoint + "users/viewallusers/$username/"),
        headers: {
          ...AuthHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      if (Response.statusCode == 200) {
        update();
        return true;
      } else {
        var errorData = json.decode(Response.body);
        String errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Failed to update password';
        if (errorData['password'] != null && errorData['password'] is List) {
          errorMessage = errorData['password'][0];
        }
        ShowToast(title: "Error", body: errorMessage);
        return false;
      }
    } catch (e) {
      ShowToast(title: "Error", body: "Failed to update password: ${e.toString()}");
      return false;
    }
  }

  // Export filtered data (current SearchStudentList)
  Future<void> exportFilteredData() async {
    try {
      if (SearchStudentList.isEmpty) {
        ShowToast(title: "No Data", body: "No users to export. Please apply filters first.");
        return;
      }

      if (kIsWeb) {
        await exportFilteredDataWeb();
        return;
      }

      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await saveFilteredExcel(SearchStudentList, result);
      }
    } catch (e) {
      print("Export error: $e");
      ShowToast(title: "Export Failed", body: "Error: ${e.toString()}");
    }
  }

  Future<void> exportFilteredDataWeb() async {
    try {
      var excel = ex.Excel.createExcel();
      var sheet = excel['Sheet1'];

      // Add headers
      sheet.cell(ex.CellIndex.indexByString("A1")).value = ex.TextCellValue("Name");
      sheet.cell(ex.CellIndex.indexByString("B1")).value = ex.TextCellValue("Email");
      sheet.cell(ex.CellIndex.indexByString("C1")).value = ex.TextCellValue("Phone");
      sheet.cell(ex.CellIndex.indexByString("D1")).value = ex.TextCellValue("Courses Enrolled");
      sheet.cell(ex.CellIndex.indexByString("E1")).value = ex.TextCellValue("Exams Enrolled");
      sheet.cell(ex.CellIndex.indexByString("F1")).value = ex.TextCellValue("Status");

      // Add data
      for (int i = 0; i < SearchStudentList.length; i++) {
        UserListModel user = SearchStudentList[i];
        sheet.cell(ex.CellIndex.indexByString("A${i + 2}")).value = ex.TextCellValue(user.name ?? "");
        sheet.cell(ex.CellIndex.indexByString("B${i + 2}")).value = ex.TextCellValue(user.username ?? "");
        sheet.cell(ex.CellIndex.indexByString("C${i + 2}")).value = ex.TextCellValue(user.phoneNumber ?? "");
        sheet.cell(ex.CellIndex.indexByString("D${i + 2}")).value = ex.TextCellValue((user.countOfCoursesPurchased ?? 0).toString());
        sheet.cell(ex.CellIndex.indexByString("E${i + 2}")).value = ex.TextCellValue((user.countOfExamsPurchased ?? 0).toString());
        sheet.cell(ex.CellIndex.indexByString("F${i + 2}")).value = ex.TextCellValue((user.isActive ?? false) ? "Active" : "Inactive");
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        String filename = DateFormat('yyyy-MM-dd-hh-mm-ss').format(DateTime.now());
        filename = "FilteredUsers_$filename.xlsx";
        
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = filename;
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ShowToast(title: "Completed", body: "Filtered data downloaded successfully");
      }
    } catch (e) {
      print("Export error: $e");
      ShowToast(title: "Export Failed", body: "Error: ${e.toString()}");
    }
  }

  Future<void> saveFilteredExcel(List<UserListModel> userlist, String path) async {
    var excel = ex.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers
    sheet.cell(ex.CellIndex.indexByString("A1")).value = ex.TextCellValue("Name");
    sheet.cell(ex.CellIndex.indexByString("B1")).value = ex.TextCellValue("Email");
    sheet.cell(ex.CellIndex.indexByString("C1")).value = ex.TextCellValue("Phone");
    sheet.cell(ex.CellIndex.indexByString("D1")).value = ex.TextCellValue("Courses Enrolled");
    sheet.cell(ex.CellIndex.indexByString("E1")).value = ex.TextCellValue("Exams Enrolled");
    sheet.cell(ex.CellIndex.indexByString("F1")).value = ex.TextCellValue("Status");

    // Add data
    for (int i = 0; i < userlist.length; i++) {
      UserListModel user = userlist[i];
      sheet.cell(ex.CellIndex.indexByString("A${i + 2}")).value = ex.TextCellValue(user.name ?? "");
      sheet.cell(ex.CellIndex.indexByString("B${i + 2}")).value = ex.TextCellValue(user.username ?? "");
      sheet.cell(ex.CellIndex.indexByString("C${i + 2}")).value = ex.TextCellValue(user.phoneNumber ?? "");
      sheet.cell(ex.CellIndex.indexByString("D${i + 2}")).value = ex.TextCellValue((user.countOfCoursesPurchased ?? 0).toString());
      sheet.cell(ex.CellIndex.indexByString("E${i + 2}")).value = ex.TextCellValue((user.countOfExamsPurchased ?? 0).toString());
      sheet.cell(ex.CellIndex.indexByString("F${i + 2}")).value = ex.TextCellValue((user.isActive ?? false) ? "Active" : "Inactive");
    }

    String filename = DateFormat('yyyy-MM-dd-hh-mm-ss').format(DateTime.now());
    filename = "FilteredUsers_$filename";
    String excelFilePath = "${path}/$filename.xlsx";
    File file = File(excelFilePath);
    await file.writeAsBytes(excel.encode()!);
    
    ShowToast(title: "Completed", body: "Filtered data exported successfully");
  }

  // Get count of active filters
  int getActiveFilterCount() {
    int count = 0;
    if (courseText.text.isNotEmpty && courseText.text != "All") count++;
    if (paymentStatusController.text.isNotEmpty && paymentStatusController.text != "All") count++;
    return count;
  }

  // Get total user count from API response
  int getTotalUserCount() {
    if (profileDatas != null && profileDatas is Map) {
      // Try to get count from API response (common in paginated APIs)
      if (profileDatas["count"] != null) {
        return profileDatas["count"] as int;
      }
      // If count is not available, return the currently loaded count
      // This happens when API doesn't provide total count
    }
    // Fallback to loaded list length if profileDatas is not available
    return SearchStudentList.length;
  }

  // Delete user
  Future<bool> deleteUser(String username) async {
    try {
      final Response = await delete(
        Uri.parse(endpoint + "users/viewallusers/$username/"),
        headers: AuthHeader,
      );

      if (Response.statusCode == 204 || Response.statusCode == 200) {
        update();
        return true;
      } else {
        var errorData = json.decode(Response.body);
        String errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Failed to delete user';
        ShowToast(title: "Error", body: errorMessage);
        return false;
      }
    } catch (e) {
      ShowToast(title: "Error", body: "Failed to delete user: ${e.toString()}");
      return false;
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    loadProfiles(search: "", paidOnly: paidOnlyFilter);
    super.onInit();
  }
}
