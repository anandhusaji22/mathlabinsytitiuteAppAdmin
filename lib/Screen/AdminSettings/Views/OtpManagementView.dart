import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';

class OtpManagementView extends StatefulWidget {
  const OtpManagementView({super.key});

  @override
  State<OtpManagementView> createState() => _OtpManagementViewState();
}

class _OtpManagementViewState extends State<OtpManagementView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadOtpList();
    });
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
                  tx700("OTP Management", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => ctrl.loadOtpList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (controller.isLoadingOtp)
                Center(child: CircularProgressIndicator())
              else if (controller.otpList.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.security, size: 64, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "No OTP records found",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "OTP records will appear here when users request password resets or phone verification.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total OTPs: ${controller.otpList.length}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    DataTable(
                      columns: [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Username")),
                        DataColumn(label: Text("OTP")),
                        DataColumn(label: Text("Validated")),
                        DataColumn(label: Text("Status")),
                      ],
                      rows: controller.otpList.map((otp) {
                        return DataRow(
                          cells: [
                            DataCell(Text("${otp.id ?? ''}")),
                            DataCell(Text(otp.username ?? "")),
                            DataCell(
                              Text(
                                otp.otp ?? "N/A",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Icon(
                                otp.otpValidated == true
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: otp.otpValidated == true
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: otp.otpValidated == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  otp.otpValidated == true
                                      ? "Validated"
                                      : "Pending",
                                  style: TextStyle(
                                    color: otp.otpValidated == true
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

