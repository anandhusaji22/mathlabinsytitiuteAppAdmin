import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathlab_admin/Constants/AppColor.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/ProfileView/Service/controller.dart';

class UserDetailsView extends StatefulWidget {
  const UserDetailsView({super.key});

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  ProfileController pctrl = Get.put(ProfileController());
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isEditingEmail = false;
  bool isEditingPassword = false;
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _updateEmailController();
  }

  void _updateEmailController() {
    if (pctrl.individualUser != null) {
      emailController.text = pctrl.individualUser!.username ?? '';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (emailController.text.trim().isEmpty) {
      ShowToast(title: "Error", body: "Email cannot be empty");
      return;
    }

    if (emailController.text == pctrl.individualUser?.username) {
      setState(() {
        isEditingEmail = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await pctrl.updateUserEmail(
      pctrl.selectedProfileModel!.username!,
      emailController.text.trim(),
    );

    setState(() {
      isLoading = false;
      isEditingEmail = false;
    });

    if (success) {
      ShowToast(title: "Success", body: "Email updated successfully");
      await pctrl.fetchUser(emailController.text.trim());
    }
  }

  Future<void> _updatePassword() async {
    if (passwordController.text.trim().isEmpty) {
      ShowToast(title: "Error", body: "New password cannot be empty");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ShowToast(title: "Error", body: "New passwords do not match");
      return;
    }

    if (passwordController.text.length < 8) {
      ShowToast(title: "Error", body: "Password must be at least 8 characters");
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await pctrl.updateUserPassword(
      pctrl.selectedProfileModel!.username!,
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    setState(() {
      isLoading = false;
      if (success) {
        isEditingPassword = false;
        passwordController.clear();
        confirmPasswordController.clear();
        showPassword = false;
        showConfirmPassword = false;
      }
    });

    if (success) {
      ShowToast(title: "Success", body: "Password updated successfully");
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User"),
        content: Text(
          "Are you sure you want to delete user ${pctrl.individualUser?.name ?? pctrl.selectedProfileModel?.name}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });

      bool success = await pctrl.deleteUser(
        pctrl.selectedProfileModel!.username!,
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        ShowToast(title: "Success", body: "User deleted successfully");
        pctrl.selectedProfileModel = null;
        pctrl.individualUser = null;
        pctrl.loadProfiles(search: "", paidOnly: pctrl.paidOnlyFilter);
        pctrl.update();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (_) {
        if (pctrl.individualUser == null || pctrl.selectedProfileModel == null) {
          return Container(
            width: 300,
            padding: EdgeInsets.all(20),
            child: Center(
              child: tx500("No user selected", size: 14),
            ),
          );
        }

        // Update email controller when user changes
        if (pctrl.individualUser != null && emailController.text != pctrl.individualUser!.username) {
          emailController.text = pctrl.individualUser!.username ?? '';
        }

        return Container(
          width: 300,
          padding: EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.black12)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                tx600("User Details", size: 18),
                SizedBox(height: 20),
                
                // User Info Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Name", pctrl.individualUser!.name ?? "N/A"),
                      SizedBox(height: 12),
                      _buildInfoRow("Phone", pctrl.individualUser!.phoneNumber ?? "N/A"),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Email Section
                tx600("Email", size: 14),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFCBCBCB)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          enabled: isEditingEmail && !isLoading,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            hintText: "Email address",
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isEditingEmail ? Icons.check : Icons.edit,
                          size: 20,
                        ),
                        onPressed: isLoading ? null : () {
                          if (isEditingEmail) {
                            _updateEmail();
                          } else {
                            setState(() {
                              isEditingEmail = true;
                            });
                          }
                        },
                      ),
                      if (isEditingEmail)
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: isLoading ? null : () {
                            setState(() {
                              isEditingEmail = false;
                              emailController.text = pctrl.individualUser!.username ?? '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Password Section
                tx600("Password", size: 14),
                SizedBox(height: 10),
                if (!isEditingPassword)
                  InkWell(
                    onTap: () {
                      setState(() {
                        isEditingPassword = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFCBCBCB)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: tx500("Click to change password", size: 14, color: Colors.grey),
                          ),
                          Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // New Password Field with Show/Hide Toggle
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFCBCBCB)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: passwordController,
                                enabled: !isLoading,
                                obscureText: !showPassword,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  hintText: "New password",
                                ),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility : Icons.visibility_off,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Confirm Password Field with Show/Hide Toggle
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFCBCBCB)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: confirmPasswordController,
                                enabled: !isLoading,
                                obscureText: !showConfirmPassword,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  hintText: "Confirm password",
                                ),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: isLoading ? null : () {
                                _updatePassword();
                              },
                              child: ButtonContainer(
                                tx500("Update", color: Colors.white),
                                color: primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          InkWell(
                            onTap: isLoading ? null : () {
                              setState(() {
                                isEditingPassword = false;
                                passwordController.clear();
                                confirmPasswordController.clear();
                                showPassword = false;
                                showConfirmPassword = false;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: tx500("Cancel", size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                SizedBox(height: 30),
                
                // Delete User Button
                InkWell(
                  onTap: isLoading ? null : _deleteUser,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                tx500("Delete User", color: Colors.white, size: 14),
                              ],
                            ),
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: tx500("$label:", size: 14),
        ),
        Expanded(
          child: tx600(value, size: 14),
        ),
      ],
    );
  }
}
