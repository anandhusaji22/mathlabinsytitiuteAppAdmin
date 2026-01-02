import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';

class AccessTypesView extends StatefulWidget {
  const AccessTypesView({super.key});

  @override
  State<AccessTypesView> createState() => _AccessTypesViewState();
}

class _AccessTypesViewState extends State<AccessTypesView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());
  TextEditingController accessTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadAccessTypes();
    });
  }

  Future<void> addAccessType() async {
    if (accessTypeController.text.isEmpty) {
      ShowToast(title: "Error", body: "Please enter access type");
      return;
    }

    if (ctrl.accessTypes.length >= 2) {
      ShowToast(
        title: "Error",
        body: "Maximum 2 access types allowed",
      );
      return;
    }

    bool success = await ctrl.addAccessType(accessTypeController.text.trim());
    if (success) {
      ShowToast(title: "Success", body: "Access type added successfully");
      accessTypeController.clear();
    } else {
      ShowToast(title: "Error", body: "Failed to add access type");
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
                  tx700("Access Types", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => ctrl.loadAccessTypes(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: accessTypeController,
                      decoration: InputDecoration(
                        hintText: "Enter access type (e.g., paid, free)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: addAccessType,
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (controller.isLoadingAccessTypes)
                Center(child: CircularProgressIndicator())
              else if (controller.accessTypes.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("No access types found"),
                  ),
                )
              else
                DataTable(
                  columns: [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Access Type")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: controller.accessTypes.map((accessType) {
                    return DataRow(
                      cells: [
                        DataCell(Text("${accessType.id ?? ''}")),
                        DataCell(Text(accessType.accessType ?? "")),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool success = await ctrl.deleteAccessType(
                                accessType.id!,
                              );
                              if (success) {
                                ShowToast(
                                  title: "Success",
                                  body: "Access type deleted successfully",
                                );
                              } else {
                                ShowToast(
                                  title: "Error",
                                  body: "Failed to delete access type",
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              if (controller.accessTypes.length >= 2)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Maximum 2 access types allowed",
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

