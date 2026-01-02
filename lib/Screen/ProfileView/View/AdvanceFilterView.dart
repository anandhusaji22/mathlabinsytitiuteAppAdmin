import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathlab_admin/Constants/AppColor.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Service/controller.dart';
import 'package:mathlab_admin/Screen/ProfileView/Service/controller.dart';

class Advancefilterview extends StatefulWidget {
  Advancefilterview({super.key});

  @override
  State<Advancefilterview> createState() => _AdvancefilterviewState();
}

class _AdvancefilterviewState extends State<Advancefilterview> {
  HomeController hctrl = Get.put(HomeController());
  ProfileController pctrl = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: GetBuilder<ProfileController>(builder: (_) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 16),
              
              // Stats Section
              _buildStatsSection(),
              SizedBox(height: 24),
              
              // Quick Filters Section
              _buildQuickFilters(),
              SizedBox(height: 24),
              
              // Advanced Filters
              _buildAdvancedFilters(),
              SizedBox(height: 24),
              
              // Export Section
              _buildExportSection(),
              SizedBox(height: 24),
              
              // Notifications Section
              _buildNotificationSection(),
              SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filters & Tools",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Refine your search",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final filterCount = pctrl.getActiveFilterCount();
    final userCount = pctrl.getTotalUserCount();
    
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter Count
          Expanded(
            child: _buildStatItem(
              icon: Icons.filter_list,
              label: "Filters",
              count: filterCount.toString(),
              color: primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          // User Count
          Expanded(
            child: _buildStatItem(
              icon: Icons.people,
              label: "Users",
              count: userCount.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 6),
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Filters",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        
        // Payment Status Chips
        _buildChipFilter(
          label: "Payment",
          icon: Icons.payment,
          options: ["All", "Paid", "Unpaid"],
          controller: pctrl.paymentStatusController,
          onChanged: (value) {
            pctrl.update();
          },
        ),
      ],
    );
  }

  Widget _buildChipFilter({
    required String label,
    required IconData icon,
    required List<String> options,
    required TextEditingController controller,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((option) {
            final isSelected = controller.text == option || (controller.text.isEmpty && option == "All");
            return FilterChip(
              label: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                controller.text = selected ? option : "";
                if (option == "All") {
                  controller.text = "";
                }
                onChanged(selected ? option : null);
              },
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Advanced Filters",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (_hasActiveFilters(pctrl))
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Active",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        
        // Course Filter
        _buildModernDropdown(
          label: "Course",
          icon: Icons.school,
          controller: pctrl.courseText,
          options: ["All", ...hctrl.CourseList.map((data) => data.fieldOfStudy ?? "").where((s) => s.isNotEmpty)],
          onChanged: (value) {
            pctrl.update();
          },
        ),
        SizedBox(height: 12),
        
        // Action Buttons
        _buildActionButton(
          label: "Apply Filters",
          icon: Icons.search,
          color: primaryColor,
          onTap: () {
            pctrl.loadProfiles(search: "", paidOnly: pctrl.paidOnlyFilter);
            ShowToast(title: "Filters Applied", body: "User list has been filtered");
          },
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: "Download",
                icon: Icons.download,
                color: Colors.green,
                onTap: () {
                  pctrl.exportFilteredData();
                },
              ),
            ),
            SizedBox(width: 8),
            _buildActionButton(
              label: "Clear",
              icon: Icons.refresh,
              color: Colors.grey.shade600,
              isOutlined: true,
              onTap: () {
                _clearAllFilters(pctrl);
                pctrl.loadProfiles(search: "", paidOnly: false);
                ShowToast(title: "Filters Cleared", body: "All filters have been reset");
              },
            ),
          ],
        ),
    ],
  );
}

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    final hasValue = controller.text.isNotEmpty && controller.text != "All";
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasValue ? primaryColor : Colors.grey.shade300,
          width: hasValue ? 1.5 : 1,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: hasValue ? primaryColor : Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          hintText: "Select $label",
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: option == controller.text ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          controller.text = value ?? "";
          onChanged(value);
        },
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        style: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }


  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          ),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.file_download, size: 16, color: Colors.green),
              ),
              SizedBox(width: 10),
              Text(
                "Export Users",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildModernDropdown(
            label: "Course",
            icon: Icons.book,
            controller: pctrl.exportCourseText,
            options: ["All", ...hctrl.CourseList.map((data) => data.fieldOfStudy ?? "").where((s) => s.isNotEmpty)],
            onChanged: (value) {
              pctrl.update();
            },
          ),
          SizedBox(height: 10),
          _buildActionButton(
            label: "Export Active",
            icon: Icons.download,
            color: Colors.green,
            onTap: () {
              pctrl.exportToExcel(pctrl.exportCourseText.text);
            },
          ),
          SizedBox(height: 8),
          _buildActionButton(
            label: "Export Expired",
            icon: Icons.access_time,
            color: Colors.orange,
            onTap: () {
              pctrl.exportToExcel(pctrl.exportCourseText.text, expired: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.notifications, size: 16, color: Colors.blue),
              ),
              SizedBox(width: 10),
              Text(
                "Send Notification",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildModernTextField(
            label: "Title",
            controller: pctrl.NotificationMessage,
            icon: Icons.title,
            height: 50,
          ),
          SizedBox(height: 10),
          _buildModernTextField(
            label: "Message",
            controller: pctrl.NotificationBody,
            icon: Icons.message,
            height: 70,
          ),
          SizedBox(height: 10),
          _buildModernDropdown(
            label: "Course",
            icon: Icons.book,
            controller: pctrl.notificationCourseText,
            options: ["All", ...hctrl.CourseList.map((data) => data.fieldOfStudy ?? "").where((s) => s.isNotEmpty)],
            onChanged: (value) {
              pctrl.update();
            },
          ),
          SizedBox(height: 10),
          _buildActionButton(
            label: "Send to Active",
            icon: Icons.send,
            color: Colors.blue,
            onTap: () {
              pctrl.sendNotificationActiveCourse();
            },
          ),
          SizedBox(height: 8),
          _buildActionButton(
            label: "Send to Renewable",
            icon: Icons.refresh,
            color: Colors.purple,
            onTap: () {
              pctrl.sendNotificationActiveCourse(isexpired: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    double height = 50,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: height > 50 ? null : 1,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
          hintText: "Enter $label",
          hintStyle: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  bool _hasActiveFilters(ProfileController pctrl) {
    return (pctrl.courseText.text.isNotEmpty && pctrl.courseText.text != "All") ||
           (pctrl.paymentStatusController.text.isNotEmpty && pctrl.paymentStatusController.text != "All");
  }

  void _clearAllFilters(ProfileController pctrl) {
    pctrl.courseText.text = "";
    pctrl.paymentStatusController.text = "";
    pctrl.update();
  }
}

