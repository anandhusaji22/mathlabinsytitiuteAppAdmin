import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';

class ExamResultsView extends StatefulWidget {
  const ExamResultsView({super.key});

  @override
  State<ExamResultsView> createState() => _ExamResultsViewState();
}

class _ExamResultsViewState extends State<ExamResultsView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadUserResponses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminSettingsController>(
      builder: (controller) {
        if (controller.isLoadingUserResponses) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  tx700("Exam Results", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => ctrl.loadUserResponses(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (controller.userResponses.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("No exam results found"),
                  ),
                )
              else
                DataTable(
                  columns: [
                    DataColumn(label: Text("Username")),
                    DataColumn(label: Text("Exam ID")),
                    DataColumn(label: Text("Exam Name")),
                    DataColumn(label: Text("Marks Scored")),
                    DataColumn(label: Text("Total Scored")),
                    DataColumn(label: Text("Qualify Score")),
                    DataColumn(label: Text("Time Taken")),
                  ],
                  rows: controller.userResponses.map((response) {
                    return DataRow(
                      cells: [
                        DataCell(Text(response.username ?? "")),
                        DataCell(Text(response.examId ?? "")),
                        DataCell(Text(response.examName ?? "")),
                        DataCell(Text(response.marksScored ?? "0")),
                        DataCell(Text(response.totalScored ?? "0")),
                        DataCell(Text("${response.qualifyScore ?? 0}")),
                        DataCell(Text(response.timeTaken ?? "00:00:00")),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

