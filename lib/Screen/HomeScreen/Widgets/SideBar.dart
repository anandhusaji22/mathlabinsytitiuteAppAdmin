import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathlab_admin/Constants/AppColor.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Service/controller.dart';
import 'package:mathlab_admin/Screen/LoginScreen/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> with SingleTickerProviderStateMixin {
  HomeController ctrl = Get.put(HomeController());

  final List<NavItem> _mainNavItems = [
    NavItem(
      title: "Dashboard",
      icon: Icons.dashboard_rounded,
      index: 0,
    ),
    NavItem(
      title: "Users",
      icon: Icons.people_rounded,
      index: 1,
    ),
  ];

  final List<NavItem> _contentNavItems = [
    NavItem(
      title: "Exam Results",
      icon: Icons.assignment_rounded,
      index: 2,
    ),
    NavItem(
      title: "Slider Images",
      icon: Icons.image_rounded,
      index: 3,
    ),
    NavItem(
      title: "Popular Courses",
      icon: Icons.star_rounded,
      index: 4,
    ),
  ];

  final List<NavItem> _settingsNavItems = [
    NavItem(
      title: "Access Types",
      icon: Icons.lock_rounded,
      index: 5,
    ),
    NavItem(
      title: "Question Types",
      icon: Icons.help_outline_rounded,
      index: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Logo/Header Section
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MathLab",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "Admin Panel",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items with Sections
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Section
                  _buildSectionHeader("MAIN"),
                  SizedBox(height: 8),
                  ..._mainNavItems.map((item) => _buildNavItem(item)),
                  SizedBox(height: 24),
                  
                  // Content Section
                  _buildSectionHeader("CONTENT"),
                  SizedBox(height: 8),
                  ..._contentNavItems.map((item) => _buildNavItem(item)),
                  SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSectionHeader("SETTINGS"),
                  SizedBox(height: 8),
                  ..._settingsNavItems.map((item) => _buildNavItem(item)),
                ],
              ),
            ),
          ),
          
          // Enhanced Logout Button
          Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  SharedPreferences pref = await SharedPreferences.getInstance();
                  pref.setString("LOGIN", "OUT");
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Logout",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isSelected = ctrl.CurrentMenu == item.index;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ctrl.CurrentMenu = item.index;
            ctrl.update();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? primaryColor.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected 
                      ? primaryColor 
                      : Colors.grey.shade600,
                  size: 22,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.w500,
                      color: isSelected 
                          ? primaryColor 
                          : Color(0xff2C3E50),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final String title;
  final IconData icon;
  final int index;

  NavItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}
