import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Service/controller.dart';

class PopularCoursesView extends StatefulWidget {
  const PopularCoursesView({super.key});

  @override
  State<PopularCoursesView> createState() => _PopularCoursesViewState();
}

class _PopularCoursesViewState extends State<PopularCoursesView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());
  HomeController homeCtrl = Get.find<HomeController>();
  Set<int> selectedCourseIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await homeCtrl.loadCourse();
      await ctrl.loadPopularCourses();
      if (ctrl.popularCourses != null && ctrl.popularCourses!.courses != null) {
        selectedCourseIds = Set.from(ctrl.popularCourses!.courses!);
      }
    });
  }

  Future<void> savePopularCourses() async {
    bool success;
    if (ctrl.popularCourses?.popularCourseId != null) {
      success = await ctrl.updatePopularCourses(selectedCourseIds.toList());
    } else {
      success = await ctrl.createPopularCourses(selectedCourseIds.toList());
    }

    if (success) {
      ShowToast(title: "Success", body: "Popular courses updated successfully");
    } else {
      ShowToast(title: "Error", body: "Failed to update popular courses");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminSettingsController>(
      builder: (controller) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  tx700("Popular Courses", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  ElevatedButton.icon(
                    onPressed: savePopularCourses,
                    icon: Icon(Icons.save),
                    label: Text("Save"),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () async {
                      await homeCtrl.loadCourse();
                      await ctrl.loadPopularCourses();
                      if (ctrl.popularCourses != null &&
                          ctrl.popularCourses!.courses != null) {
                        setState(() {
                          selectedCourseIds =
                              Set.from(ctrl.popularCourses!.courses!);
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (controller.isLoadingPopularCourses)
                Center(child: CircularProgressIndicator())
              else
                GetBuilder<HomeController>(
                  builder: (homeController) {
                    if (homeController.CourseList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("No courses available"),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          "Select courses to mark as popular (${selectedCourseIds.length} selected)",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: homeController.CourseList.length,
                          itemBuilder: (context, index) {
                            final course = homeController.CourseList[index];
                            final isSelected = selectedCourseIds
                                .contains(course.courseUniqueId);

                            return CheckboxListTile(
                              title: Text(course.fieldOfStudy ?? ""),
                              subtitle: Text("ID: ${course.courseUniqueId}"),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedCourseIds
                                        .add(course.courseUniqueId!);
                                  } else {
                                    selectedCourseIds
                                        .remove(course.courseUniqueId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

