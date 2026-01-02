import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';

class QuestionTypesView extends StatefulWidget {
  const QuestionTypesView({super.key});

  @override
  State<QuestionTypesView> createState() => _QuestionTypesViewState();
}

class _QuestionTypesViewState extends State<QuestionTypesView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());
  TextEditingController questionTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadQuestionTypes();
    });
  }

  Future<void> addQuestionType() async {
    if (questionTypeController.text.isEmpty) {
      ShowToast(title: "Error", body: "Please enter question type");
      return;
    }

    if (ctrl.questionTypes.length >= 3) {
      ShowToast(
        title: "Error",
        body: "Maximum 3 question types allowed",
      );
      return;
    }

    bool success =
        await ctrl.addQuestionType(questionTypeController.text.trim());
    if (success) {
      ShowToast(title: "Success", body: "Question type added successfully");
      questionTypeController.clear();
    } else {
      ShowToast(title: "Error", body: "Failed to add question type");
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
                  tx700("Question Types", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => ctrl.loadQuestionTypes(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: questionTypeController,
                      decoration: InputDecoration(
                        hintText: "Enter question type (e.g., Multiple Choice)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: addQuestionType,
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (controller.isLoadingQuestionTypes)
                Center(child: CircularProgressIndicator())
              else if (controller.questionTypes.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("No question types found"),
                  ),
                )
              else
                DataTable(
                  columns: [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Question Type")),
                    DataColumn(label: Text("Slug")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: controller.questionTypes.map((questionType) {
                    return DataRow(
                      cells: [
                        DataCell(Text("${questionType.id ?? ''}")),
                        DataCell(Text(questionType.questionType ?? "")),
                        DataCell(Text(questionType.slugQuestionType ?? "")),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool success = await ctrl.deleteQuestionType(
                                questionType.slugQuestionType!,
                              );
                              if (success) {
                                ShowToast(
                                  title: "Success",
                                  body: "Question type deleted successfully",
                                );
                              } else {
                                ShowToast(
                                  title: "Error",
                                  body: "Failed to delete question type",
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              if (controller.questionTypes.length >= 3)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Maximum 3 question types allowed",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

