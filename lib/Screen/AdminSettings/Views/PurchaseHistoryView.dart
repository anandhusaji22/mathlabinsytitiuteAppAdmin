import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';

class PurchaseHistoryView extends StatefulWidget {
  const PurchaseHistoryView({super.key});

  @override
  State<PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<PurchaseHistoryView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());
  TextEditingController usernameController = TextEditingController();
  String? selectedUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all users first
      ctrl.loadAllUsers();
    });
  }

  void searchByUsername() {
    String username = usernameController.text.trim();
    if (username.isNotEmpty) {
      setState(() {
        selectedUsername = username;
      });
      ctrl.loadPurchaseHistory(username: username);
    } else {
      ShowToast(title: "Error", body: "Please enter a username");
    }
  }

  void selectUser(String username) {
    setState(() {
      selectedUsername = username;
      usernameController.text = username;
    });
    ctrl.loadPurchaseHistory(username: username);
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
                  tx700("Purchase History", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  Container(
                    width: 300,
                    child: TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: "Enter username (email)",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: searchByUsername,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => searchByUsername(),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      ctrl.loadAllUsers();
                      if (selectedUsername != null) {
                        ctrl.loadPurchaseHistory(username: selectedUsername);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (ctrl.isLoadingUsers)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("Loading users..."),
                )
              else if (ctrl.allUsers.isNotEmpty)
                Container(
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tx600("Select User:", size: 16),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: ctrl.allUsers.length,
                          itemBuilder: (context, index) {
                            final user = ctrl.allUsers[index];
                            return ListTile(
                              title: Text(user.username ?? ""),
                              subtitle: Text(user.name ?? ""),
                              selected: selectedUsername == user.username,
                              selectedTileColor: Colors.blue.withOpacity(0.1),
                              onTap: () => selectUser(user.username ?? ""),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              if (selectedUsername == null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.blue),
                        SizedBox(height: 20),
                        Text(
                          "Please select or search for a user to view purchase history",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else if (controller.isLoadingPurchaseHistory)
                Center(child: CircularProgressIndicator())
              else if (controller.purchaseHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "No purchase history found for $selectedUsername",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Purchase History for: $selectedUsername",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                DataTable(
                  columns: [
                    DataColumn(label: Text("Username")),
                    DataColumn(label: Text("Course/Exam")),
                    DataColumn(label: Text("Purchase Date")),
                    DataColumn(label: Text("Expiration Date")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Payment ID")),
                    DataColumn(label: Text("Paid")),
                  ],
                  rows: controller.purchaseHistory.map((purchase) {
                    return DataRow(
                      cells: [
                        DataCell(Text(purchase.username ?? "")),
                        DataCell(Text(
                          purchase.courseName ?? purchase.examName ?? "",
                        )),
                        DataCell(Text(purchase.dateOfPurchase ?? "")),
                        DataCell(Text(purchase.expirationDate ?? "")),
                        DataCell(Text("₹${purchase.orderAmount ?? 0}")),
                        DataCell(Text(purchase.orderPaymentId ?? "")),
                        DataCell(
                          Icon(
                            purchase.isPaid == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: purchase.isPaid == true
                                ? Colors.green
                                : Colors.red,
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

