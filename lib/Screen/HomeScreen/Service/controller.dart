// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// Import dart:html for web file download
import 'dart:html' as html if (dart.library.io) 'dart:io';
// Conditional import for file operations
import 'file_helper_impl.dart' if (dart.library.html) 'file_helper_stub.dart' as file_helper;

import 'package:dio/dio.dart' as Request;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/connect.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mathlab_admin/Constants/AppHeaders.dart';
import 'package:mathlab_admin/Constants/Strings.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/main.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/ExamModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/ModulesModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/NoteModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/VideoModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/contentModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/courseModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/sectionModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Models/subjectModel.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Widgets/addExam.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserProfileModel.dart';
import 'package:excel/excel.dart' as ex;

import 'package:quickalert/quickalert.dart';

class HomeController extends GetxController {
  int CurrentMenu = 0;
  bool CourseUploading = false;

  // Helper function to create MultipartFile from file path or web file data
  Future<Request.MultipartFile?> createMultipartFile(String? filePath, String fieldName) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    if (kIsWeb && filePath.startsWith("WEB_FILE:")) {
      // Handle web file upload
      // Format: "WEB_FILE:filename:base64bytes"
      // Find the second ":" which separates filename from base64 data
      final firstColonIndex = filePath.indexOf(":");
      final secondColonIndex = filePath.indexOf(":", firstColonIndex + 1);
      if (secondColonIndex > firstColonIndex) {
        final filename = filePath.substring(firstColonIndex + 1, secondColonIndex);
        final base64Bytes = filePath.substring(secondColonIndex + 1);
        final bytes = base64Decode(base64Bytes);
        return Request.MultipartFile.fromBytes(
          bytes,
          filename: filename,
        );
      }
    } else if (!kIsWeb) {
      // Handle non-web file upload
      return await Request.MultipartFile.fromFile(
        filePath,
        filename: filePath.split("/").last,
      );
    }
    return null;
  }
  String SelectedCourse = "";
  String SelectedSubject = "";
  String SelectedModule = "";
  String SelectedCotent = "";
  String selectedSection = "";
  DateTime? SelectedDate;
  late CourseModel SelectedCourseModel;
  late SubjectModel SelectedSubjectModel;
  late ModuleModel SelectedModuleModel;
  late contentModel SelectedContentModel;
  late SectionModel SelectedSectionModel;

  List<CourseModel> CourseList = [];
  List<SubjectModel> SubjectList = [];
  List<ModuleModel> ModuleList = [];
  List<contentModel> ContentList = [];
  List<SectionModel> SectionList = [];

  SetCourse(String id, {var cs = false}) {
    SelectedCourse = id;
    SubjectList = [];
    if (cs != false) {
      SelectedCourseModel = cs;
      update();
      loadSubject();
    }
    update();
  }

  SetSubject(String id, {var cs = false}) {
    SelectedSubject = id;

    update();
    if (cs != false) {
      SelectedSubjectModel = cs;
      update();
      loadModule();
    }
    update();
  }

  SetModule(String id, {var cs = false}) {
    SelectedModule = id;

    update();
    if (cs != false) {
      SelectedModuleModel = cs;
      update();
      loadContent();
    }
    update();
  }

  SetContent(String id, {var cs = false}) {
    SelectedCotent = id;

    update();
    if (cs != false) {
      SelectedContentModel = cs;
      loadSection();
      update();
      // loadContent();
    }
    update();
  }

  loadSection() async {
    SectionList.clear();
    update();
    final Response = await http.get(
        Uri.parse(endpoint +
            "/exam/addexam/${SelectedContentModel!.examModel!.examUniqueId!}"),
        headers: AuthHeader);

    print(Response.body);
    print(Response.statusCode);
    if (Response.statusCode == 200) {
      var data = json.decode(Response.body);
      for (var st in data["sections"]) {
        SectionList.add(SectionModel.fromJson(st));
      }
      update();
    }
    update();
  }

  deleteSection(String sectionID) async {
    final Response = await http.delete(
        Uri.parse(endpoint + "exam/sections-add/$sectionID/"),
        headers: AuthHeader);

    print(Response.body);
    print(Response.statusCode);
    loadSection();
  }

  loadContent() async {
    ContentList = [];
    final response = await http.get(
        Uri.parse(endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/videos/"),
        headers: AuthHeader);
    print(response.body);
    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      for (var data in res) {
        VideoModel model = VideoModel.fromJson(data);
        contentModel Cmodel = contentModel(
          model.videoUniqueId,
          model.title,
          model.title,
          "VIDEO",
          model.createdDate,
          model,
          null,
          null,
          model.isActive,
        );
        ContentList.add(Cmodel);
      }
      update();
    }

    final res = await http.get(
        Uri.parse(endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/notes/"),
        headers: AuthHeader);
    print(res.body);
    if (res.statusCode == 200) {
      var res1 = json.decode(res.body);
      for (var data in res1) {
        NoteModel model = NoteModel.fromJson(data);
        contentModel Cmodel = contentModel(
          model.notesId,
          model.title,
          model.title,
          "NOTE",
          model.createdDate,
          null,
          model,
          null,
          model.isActive,
        );
        ContentList.add(Cmodel);
      }
      update();
    }
    final eres = await http.get(
        Uri.parse(endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/exams/"),
        headers: AuthHeader);

    if (eres.statusCode == 200) {
      try {
      var res2 = json.decode(eres.body);

      print(res2);
        if (res2 != null && res2 is List) {
      for (var data in res2) {
            try {
        ExamModel model = ExamModel.fromJson(data);
              // Ensure examName is not null for sortTitle
              String examName = model.examName ?? "Untitled Exam";
        contentModel Cmodel = contentModel(
          model.examUniqueId,
                examName,
                examName, // sortTitle - use examName, fallback to "Untitled Exam" if null
          "EXAM",
          model.createdDate,
          null,
          null,
          model,
                model.isActive ?? true, // Default to true if null
        );
        ContentList.add(Cmodel);
            } catch (e) {
              print("Error parsing exam model: $e");
              print("Data: $data");
            }
          }
      }
      update();
      } catch (e) {
        print("Error loading exam content: $e");
        update();
      }
    }

    //   ContentList.sort((a, b) => a.title!.compareTo(b.title!));
    ContentList = sortContentList(ContentList);
    update();
  }

  List<contentModel> sortContentList(List<contentModel> contentList) {
    List<String> _extractVersion(contentModel content) {
      // Use regular expression to extract version numbers
      // Handle null sortTitle safely
      String titleToSort = content.sortTitle ?? content.title ?? "";
      if (titleToSort.isEmpty) {
        content.sortTitle = "0";
        return ['0'];
      }
      
      RegExp regex = RegExp(r'(\d+(\.\d+)*)');
      RegExpMatch? match = regex.firstMatch(titleToSort);
      List<String> versionNumbers =
          match != null ? match.group(1)!.split('.') : ['0'];
      content.sortTitle =
          versionNumbers.join('.'); // Update title with the modified version
      return versionNumbers;
    }

    // Sort content based on extracted version numbers
    try {
    contentList.sort((a, b) {
        try {
      List<String> versionA = _extractVersion(a);
      List<String> versionB = _extractVersion(b);

      for (int i = 0; i < versionA.length && i < versionB.length; i++) {
        int numA = int.parse(versionA[i]);
        int numB = int.parse(versionB[i]);

        if (numA != numB) {
          return numA - numB;
        }
      }

      return versionA.length - versionB.length;
        } catch (e) {
          print("Error sorting content: $e");
          return 0; // Keep original order if sorting fails
        }
    });
    } catch (e) {
      print("Error in sortContentList: $e");
    }

    return contentList;
  }

  loadModule() async {
    ModuleList = [];
    //update();
    final response = await http.get(
        Uri.parse(endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/"),
        headers: AuthHeader);
    print(response.body);
    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      for (var data in res) {
        ModuleModel model = ModuleModel.fromJson(data);
        ModuleList.add(model);
      }
      update();
    }
  }

  AddVideo(VideoModel videoModel, BuildContext context) async {
    final dio = Request.Dio();
    print(json.encode(videoModel.toJson()));
    Request.FormData formData = Request.FormData.fromMap(videoModel.toJson());

    final response = await dio.post(
        endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/videos/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(
          headers: AuthHeader,
          validateStatus: (status) {
            return (status!.toInt() < 500);
          },
        ));
    print(response.data);

    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      ShowToast(
          title: "Video Added",
          body:
              "Video is added succefully in module ${SelectedModuleModel.moduleName}");
      CourseUploading = false;
      ContentList = [];
      loadContent();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  UpdateVideo(VideoModel videoModel, BuildContext context) async {
    final dio = Request.Dio();
    print(json.encode(videoModel.toJson(update: false)));
    Request.FormData formData = Request.FormData.fromMap(videoModel.toJson());

    final response = await dio.patch(
        endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/videos/${videoModel.videoUniqueId}", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(
          headers: AuthHeader,
          validateStatus: (status) {
            return (status!.toInt() < 500);
          },
        ));
    print(response.data);

    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      CourseUploading = false;
      ContentList = [];
      loadContent();
      update();

      try {
      Navigator.of(context).pop();
      } catch (e) {
        try {
          Get.back();
        } catch (e2) {
          print("Error closing dialog: $e2");
        }
      }
      
      Future.delayed(Duration(milliseconds: 300), () {
        try {
          ShowToast(
              title: "Video Updated",
              body:
                  "Video is updated successfully in module ${SelectedModuleModel.moduleName}");
        } catch (e) {
          print("Error showing toast: $e");
        }
      });
    } else {
      CourseUploading = false;
      update();
      try {
        ShowToast(title: "Error occurred", body: "Something went wrong");
      } catch (e) {
        print("Error showing error toast: $e");
      }
    }
  }

  DeleteVideo(String videoId, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your video? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint +
                  "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/videos/$videoId"),
              headers: AuthHeader);
          print(response.body);
          print(response.statusCode);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "video deleted succefully");
            ContentList = [];
            loadContent();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  AddNote(NoteModel noteModel, BuildContext context) async {
    final dio = Request.Dio();

    Map<String, dynamic> formDataMap = {
      "module": noteModel.module,
      "access_type": noteModel.accessType,
      "title": noteModel.title,
      "description": noteModel.description,
      // "pdf": "https://mathlabtech.com/media/pdfs/S8_LinearTransformation_Material.pdf",
      "created_date": noteModel.updatedDate,
      "updated_date": noteModel.createdDate,

      "is_active": noteModel.isActive,
    };

    final pdfFile = await createMultipartFile(noteModel.pdf, 'pdf');
    if (pdfFile != null) {
      formDataMap['pdf'] = pdfFile;
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.post(
        endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/notes/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      NoteModel md = NoteModel.fromJson(response.data);

      ShowToast(
          title: "Note Added",
          body:
              "${md.title} is added succefully with module  ${SelectedModuleModel.moduleName}");
      CourseUploading = false;
      ContentList = [];
      loadContent();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  UpdateNote(NoteModel noteModel, BuildContext context, bool isEdited) async {
    final dio = Request.Dio();

    Map<String, dynamic> formDataMap = {
      "module": noteModel.module,
      "access_type": noteModel.accessType,
      "title": noteModel.title,
      "description": noteModel.description,
      // "pdf": "https://mathlabtech.com/media/pdfs/S8_LinearTransformation_Material.pdf",
      // "created_date": noteModel.updatedDate,
      // "updated_date": noteModel.createdDate,

      "is_active": noteModel.isActive,
    };

    if (isEdited) {
      final pdfFile = await createMultipartFile(noteModel.pdf, 'pdf');
      if (pdfFile != null) {
        formDataMap['pdf'] = pdfFile;
      }
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.patch(
        endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/notes/${noteModel.notesId}", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      NoteModel md = NoteModel.fromJson(response.data);
      CourseUploading = false;
      ContentList = [];
      loadContent();
      update();

      try {
      Navigator.of(context).pop();
      } catch (e) {
        try {
          Get.back();
        } catch (e2) {
          print("Error closing dialog: $e2");
        }
      }
      
      Future.delayed(Duration(milliseconds: 300), () {
        try {
          ShowToast(
              title: "Note Updated",
              body:
                  "${md.title} is updated successfully in module ${SelectedModuleModel.moduleName}");
        } catch (e) {
          print("Error showing toast: $e");
        }
      });
    } else {
      CourseUploading = false;
      update();
      try {
        ShowToast(title: "Error occurred", body: "Something went wrong");
      } catch (e) {
        print("Error showing error toast: $e");
      }
    }
  }

  DeleteNote(String noteID, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your note? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint +
                  "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/notes/$noteID"),
              headers: AuthHeader);
          print(response.body);
          print(response.statusCode);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "Note deleted succefully");
            ContentList = [];
            loadContent();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  AddExam(ExamModel videoModel, BuildContext context) async {
    final dio = Request.Dio();
    print(json.encode(videoModel.toJson()));
    // Request.FormData formData = Request.FormData.fromMap(videoModel.toJson());
    Map<String, dynamic> formDataMap = {
      "module": videoModel.module,
      "access_type": videoModel.accessType,
      "exam_id": videoModel.examId,
      "exam_name": videoModel.examName,
      "instruction": videoModel.instruction,
      "duration_of_exam": videoModel.durationOfExam,
      "total_marks": videoModel.totalMarks,
      "is_active": true,
    };

    final pdfFile = await createMultipartFile(videoModel.pdf, 'solution_pdf');
    if (pdfFile != null) {
      formDataMap['solution_pdf'] = pdfFile;
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.post(
        endpoint +
            "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/exams/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(
          headers: AuthHeader,
          validateStatus: (status) {
            return (status!.toInt() < 500);
          },
        ));
    print(response.data);

    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      CourseUploading = false;
      ContentList = [];
      loadContent();
      update();

      try {
      Navigator.of(context).pop();
      } catch (e) {
        try {
          Get.back();
        } catch (e2) {
          print("Error closing dialog: $e2");
        }
      }
      
      Future.delayed(Duration(milliseconds: 300), () {
        try {
          ShowToast(
              title: "Exam Added",
              body:
                  "Exam is added successfully in module ${SelectedModuleModel.moduleName}");
        } catch (e) {
          print("Error showing toast: $e");
        }
      });
    } else {
      CourseUploading = false;
      update();
      try {
        ShowToast(title: "Error occurred", body: "Something went wrong");
      } catch (e) {
        print("Error showing error toast: $e");
      }
    }
  }

  UpdateExam(ExamModel videoModel, BuildContext context, bool isEdit) async {
    final dio = Request.Dio();
    print(json.encode(videoModel.toJson()));
    
    // Ensure isActive is properly set (false when unchecked, true when checked, default true)
    bool isActiveValue = videoModel.isActive ?? true;
    print("Updating exam with isActive: $isActiveValue");
    
    Map<String, dynamic> formDataMap = {
      "module": videoModel.module,
      "access_type": videoModel.accessType,
      "exam_id": videoModel.examId,
      "exam_name": videoModel.examName,
      "instruction": videoModel.instruction,
      "duration_of_exam": videoModel.durationOfExam,
      "total_marks": videoModel.totalMarks,
      "is_active": isActiveValue, // Use the actual value from model (can be false when unticked)
    };

    if (isEdit) {
      final pdfFile = await createMultipartFile(videoModel.pdf, 'solution_pdf');
      if (pdfFile != null) {
        formDataMap['solution_pdf'] = pdfFile;
      }
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    try {
    final response = await dio.patch(
        endpoint +
              "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/exams/${videoModel.examUniqueId}",
        data: formData,
        options: Request.Options(
          headers: AuthHeader,
          validateStatus: (status) {
            return (status!.toInt() < 500);
          },
        ));
    print(response.data);

    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      CourseUploading = false;
        update();
        
        // Close dialog safely before reloading content
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Fallback to GetX navigation if Navigator fails
          try {
            Get.back();
          } catch (e2) {
            print("Error closing dialog: $e2");
          }
        }
        
        // Reload content after dialog is closed
        Future.delayed(Duration(milliseconds: 200), () {
          try {
      ContentList = [];
      loadContent();
          } catch (e) {
            print("Error reloading content: $e");
          }
        });
        
        // Show toast after a delay to ensure navigation is complete
        Future.delayed(Duration(milliseconds: 400), () {
          try {
            final moduleName = SelectedModuleModel.moduleName ?? "the module";
            ShowToast(
                title: "Exam Updated",
                body: "Exam is updated successfully in module $moduleName");
          } catch (e) {
            print("Error showing toast: $e");
            // Fallback toast without module name
            try {
              ShowToast(title: "Exam Updated", body: "Exam updated successfully");
            } catch (e2) {
              print("Error showing fallback toast: $e2");
            }
          }
        });
    } else {
      CourseUploading = false;
      update();
        try {
          ShowToast(title: "Error occurred", body: "Something went wrong");
        } catch (e) {
          print("Error showing error toast: $e");
        }
      }
    } catch (e) {
      print("Error updating exam: $e");
      CourseUploading = false;
      update();
      try {
        ShowToast(title: "Error occurred", body: "Failed to update exam");
      } catch (e2) {
        print("Error showing error toast: $e2");
      }
    }
  }

  DeleteExam(String ExamID, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your Exam? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint +
                  "users/fieldofstudy/${SelectedCourse}/subjects/${SelectedSubject}/modules/$SelectedModule/exams/$ExamID"),
              headers: AuthHeader);
          print(response.body);
          print(response.statusCode);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "Exam deleted succefully");
            ContentList = [];
            loadContent();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  AddModule(ModuleModel moduleModel, BuildContext context) async {
    final dio = Request.Dio();

    Request.FormData formData = Request.FormData.fromMap({
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "subjects": moduleModel.subjects,
      "is_active": moduleModel.isActive,
      "module_name": moduleModel.moduleName,
      "notes": [],
      "videos": [],
      "created_date": DateTime.now().toString(),
      "updated_date": DateTime.now().toString(),
      "exams": []
    });

    final response = await dio.post(
        endpoint +
            "users/fieldofstudy/$SelectedCourse/subjects/$SelectedSubject/modules/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      ModuleModel md = ModuleModel.fromJson(response.data);

      ShowToast(
          title: "Module Added",
          body:
              "${md.moduleName} is added succefully with module id ${md.modulesId}");
      CourseUploading = false;
      ModuleList = [];
      loadModule();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  UpdateModule(ModuleModel moduleModel, BuildContext context) async {
    final dio = Request.Dio();

    Request.FormData formData = Request.FormData.fromMap({
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "subjects": moduleModel.subjects,
      "is_active": moduleModel.isActive,
      "module_name": moduleModel.moduleName,
    });

    final response = await dio.patch(
        endpoint +
            "users/fieldofstudy/$SelectedCourse/subjects/$SelectedSubject/modules/${moduleModel.modulesId}/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      ModuleModel md = ModuleModel.fromJson(response.data);

      ShowToast(
          title: "Module Updated",
          body:
              "${md.moduleName} is updated succefully with module id ${md.modulesId}");
      CourseUploading = false;
      ModuleList = [];
      loadModule();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  DeleteModule(String ModuleId, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your Module? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint +
                  "users/fieldofstudy/$SelectedCourse/subjects/$SelectedSubject/modules/$ModuleId/"),
              headers: AuthHeader);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "Module deleted succefully");
            ModuleList = [];
            loadModule();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  loadSubject() async {
    SubjectList = [];
    update();
    final response = await http.get(
        Uri.parse(endpoint + "users/fieldofstudy/$SelectedCourse/subjects/"),
        headers: AuthHeader);

    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      for (var data in res) {
        SubjectModel model = SubjectModel.fromJson(data);
        SubjectList.add(model);
      }
      update();
    }
  }

  AddSubject(SubjectModel subjectModel, BuildContext context) async {
    final dio = Request.Dio();

    Map<String, dynamic> formDataMap = {
      "field_of_study": SelectedCourse,
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "subjects": subjectModel.subjects,
      "is_active": subjectModel.isActive,
      "modules": [],
    };

    final imageFile = await createMultipartFile(subjectModel.subjectImage, 'subject_image');
    if (imageFile != null) {
      formDataMap['subject_image'] = imageFile;
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.post(
        endpoint +
            "users/fieldofstudy/$SelectedCourse/subjects/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      SubjectModel md = SubjectModel.fromJson(response.data);

      ShowToast(
          title: "Subject Added",
          body:
              "${md.subjects} is added succefully with subject id ${md.subjectId}");
      CourseUploading = false;
      SubjectList = [];
      loadSubject();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  UpdateSubject(
      SubjectModel subjectModel, bool isEdited, BuildContext context) async {
    final dio = Request.Dio();
    print(json.encode(subjectModel.toJson()));
    Map<String, dynamic> formDataMap = {
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "subjects": subjectModel.subjects,
      "is_active": subjectModel.isActive,
    };

    if (isEdited) {
      final imageFile = await createMultipartFile(subjectModel.subjectImage, 'subject_image');
      if (imageFile != null) {
        formDataMap['subject_image'] = imageFile;
      }
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.patch(
        endpoint +
            "users/fieldofstudy/$SelectedCourse/subjects/${subjectModel.subjectId}/", //users/fieldofstudy/${SelectedCourse}/subjects/",
        data: formData,
        options: Request.Options(headers: AuthHeader));
    print(response.data);
    print(response.statusMessage);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      SubjectModel md = SubjectModel.fromJson(response.data);

      ShowToast(
          title: "Subject Updated",
          body: "${md.subjects} is Updated succefully ");
      CourseUploading = false;
      SubjectList = [];
      loadSubject();

      Navigator.of(context).pop();
    } else {
      ShowToast(title: "Error occurred", body: "Something went to wrong");
      CourseUploading = false;
      update();
    }
  }

  DeleteSubject(String SubjectId, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your subject? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint +
                  "users/fieldofstudy/$SelectedCourse/subjects/$SubjectId/"),
              headers: AuthHeader);
          print(response.body);
          print(response.statusCode);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "Subject deleted succefully");
            SubjectList = [];
            loadSubject();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  loadCourse() async {
    CourseList.clear();
    update();

    // Ensure token is available before making the request
    if (token.isEmpty) {
      print("Token is empty, cannot load courses");
      update();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(endpoint + "users/fieldofstudy/"),
        headers: AuthHeader,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        for (var data in res) {
          CourseModel model = CourseModel.fromJson(data);
          CourseList.add(model);
        }
        update();
      } else {
        print("Failed to load courses: ${response.statusCode}");
        print("Response: ${response.body}");
        // Don't crash, just show empty list
        update();
      }
    } catch (e) {
      print("Error loading courses: $e");
      // Show user-friendly error instead of crashing
      // The UI will show empty course list instead of crashing
      update();
    }
  }

  AddCourse(CourseModel Cmodel, BuildContext context) async {
    final dio = Request.Dio();

    Map<String, dynamic> formDataMap = {
      "field_of_study": Cmodel.fieldOfStudy,
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "price": Cmodel.price,
      "Course_description": Cmodel.courseDescription,
      "user_benefit": Cmodel.userBenefit,
      "only_paid": Cmodel.onlyPaid,
      "Course_duration": Cmodel.validity,
      "subjects": [],
      "is_active": false,
    };

    final courseImageFile = await createMultipartFile(Cmodel.courseImage, 'course_image');
    if (courseImageFile != null) {
      formDataMap['course_image'] = courseImageFile;
    }

    final coverImageFile = await createMultipartFile(Cmodel.coverImage, 'cover_image');
    if (coverImageFile != null) {
      formDataMap['cover_image'] = coverImageFile;
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.post(endpoint + "users/fieldofstudy/",
        data: formData, options: Request.Options(headers: AuthHeader));

    if (response.statusCode == 200 || response.statusCode == 201) {
      CourseModel md = CourseModel.fromJson(response.data);

      ShowToast(
          title: "Course created",
          body:
              "${Cmodel.fieldOfStudy} is created succefully with course id ${md.courseUniqueId}");
      CourseUploading = false;
      CourseList = [];
      loadCourse();

      Navigator.of(context).pop();
    } else {
      CourseUploading = false;
      update();
      ShowToast(title: "Error occurred", body: "Something went to wrong");
    }
  }

  DeleteCourse(String courseUniqueId, BuildContext context) async {
    QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: "Are you sure want to delete",
        text:
            "Do you really want to delete your course? You can't undo this action",
        onConfirmBtnTap: () async {
          final response = await http.delete(
              Uri.parse(endpoint + "users/fieldofstudy/$courseUniqueId/"),
              headers: AuthHeader);
          print(response.body);
          print(response.statusCode);

          if (response.statusCode == 204) {
            ShowToast(title: "Successful", body: "Course deleted succefully");
            CourseList = [];
            loadCourse();
            Navigator.of(context).pop();
          } else {
            ShowToast(title: "Error occurred", body: "Something went to wrong");
          }
        });
  }

  updateCourse(
      CourseModel Cmodel, CourseModel Pmodel, BuildContext context) async {
    final dio = Request.Dio();

    Map<String, dynamic> formDataMap = {
      "field_of_study": Cmodel.fieldOfStudy,
      //  "course_image": "https://mathlabtech.com/media/images/PG_ENTRANCE_EXAM_course_image.jpeg",
      // "cover_image": "https://mathlabtech.com/media/images/1000_F_310275872_2nIcdXv7L61QbLeM8969ARTQWPtxvm5o.jpg",
      "price": Cmodel.price,
      "Course_description": Cmodel.courseDescription,
      "user_benefit": Cmodel.userBenefit,
      "only_paid": Cmodel.onlyPaid,
      "Course_duration": Cmodel.validity,

      "is_active": Cmodel.isActive,
    };

    if (Cmodel.courseImage != "" && Cmodel.courseImage != Pmodel.courseImage) {
      final courseImageFile = await createMultipartFile(Cmodel.courseImage, 'course_image');
      if (courseImageFile != null) {
        formDataMap['course_image'] = courseImageFile;
      }
    }

    if (Cmodel.coverImage != "" && Cmodel.coverImage != Pmodel.coverImage) {
      final coverImageFile = await createMultipartFile(Cmodel.coverImage, 'cover_image');
      if (coverImageFile != null) {
        formDataMap['cover_image'] = coverImageFile;
      }
    }

    Request.FormData formData = Request.FormData.fromMap(formDataMap);

    final response = await dio.put(
        endpoint + "users/fieldofstudy/${Pmodel.courseUniqueId}/",
        data: formData,
        options: Request.Options(headers: AuthHeader));

    if (response.statusCode == 200 || response.statusCode == 201) {
      CourseModel md = CourseModel.fromJson(response.data);

      ShowToast(
          title: "Course Updated",
          body:
              "${Cmodel.fieldOfStudy} is updated succefully with course id ${md.courseUniqueId}");
      CourseUploading = false;
      CourseList = [];
      loadCourse();

      Navigator.of(context).pop();
    } else {
      CourseUploading = false;
      update();
      ShowToast(title: "Error occurred", body: "Something went to wrong");
    }
  }

  exportExamResult(String examUniqueId) async {
    String? path;
    if (!kIsWeb) {
      // Only get directory path on non-web platforms
      final result = await FilePicker.platform.getDirectoryPath();
      path = result;
      if (path == null) {
        ShowToast(title: "Cancelled", body: "Export cancelled");
        return;
      }
    }
    final Response = await http.get(
        Uri.parse(
          endpoint + "applicationview/userresponses/?search=${examUniqueId}",
        ),
        headers: AuthHeader);
    print(examUniqueId);
    print(Response.body);
    if (Response.statusCode == 200) {
      var data = json.decode(Response.body);
      saveResultExcel(data, path);
    }
  }

  saveResultExcel(var data, String? path) async {
    var excel = ex.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers to the worksheet
    sheet.cell(ex.CellIndex.indexByString("A1")).value =
        ex.TextCellValue("Email");
    sheet.cell(ex.CellIndex.indexByString("B1")).value =
        ex.TextCellValue("Name");
    sheet.cell(ex.CellIndex.indexByString("C1")).value =
        ex.TextCellValue("MarkScored");
    sheet.cell(ex.CellIndex.indexByString("D1")).value =
        ex.TextCellValue("Time Taken");
    int i = -1;
    for (var dt in data) {
      i = i + 1;
      sheet.cell(ex.CellIndex.indexByString("A${i + 2}")).value =
          ex.TextCellValue(dt["username"]);
      sheet.cell(ex.CellIndex.indexByString("B${i + 2}")).value =
          ex.TextCellValue(dt["name"] ?? " ");
      sheet.cell(ex.CellIndex.indexByString("C${i + 2}")).value =
          ex.TextCellValue(dt["marks_scored"] ?? "");
      sheet.cell(ex.CellIndex.indexByString("D${i + 2}")).value =
          ex.TextCellValue(dt["time_taken"] ?? "");
    }

    String filename = DateFormat('yyyy-MM-dd-hh:mm:ss').format(DateTime.now());
    filename = "${data["exam_name"]}$filename";
    
    if (kIsWeb) {
      // Web: Download file directly using browser download
      final bytes = excel.encode()!;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$filename.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
      ShowToast(title: "Completed", body: "Exam result downloaded successfully");
    } else {
      // Desktop/Mobile: Save to file system
      if (path != null) {
        String excelFilePath = "${path}/$filename.xlsx";
        // Use helper function for file operations (platform-specific)
        await file_helper.writeFile(excelFilePath, excel.encode()!);
        ShowToast(title: "Completed", body: "Exam result exported successfully");
      }
    }
  }

  @override
  void onInit() {
    // CourseView handles loading courses in its initState
    // No need to load here to avoid duplicate loading
    super.onInit();
  }
}
