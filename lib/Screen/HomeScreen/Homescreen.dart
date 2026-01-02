import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathlab_admin/Constants/AppColor.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Service/controller.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Widgets/CourseView.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/ProfileView.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Views/ExamResultsView.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Views/SliderImageView.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Views/PopularCoursesView.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Views/AccessTypesView.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Views/QuestionTypesView.dart';

import 'Widgets/SideBar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  HomeController ctrl = Get.put(HomeController());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Widget _getCurrentScreen() {
    switch (ctrl.CurrentMenu) {
      case 0:
        return CourseView();
      case 1:
        return ProfileViewScreen();
      case 2:
        return ExamResultsView();
      case 3:
        return SliderImageView();
      case 4:
        return PopularCoursesView();
      case 5:
        return AccessTypesView();
      case 6:
        return QuestionTypesView();
      default:
        return CourseView();
    }
  }

  String _getCurrentScreenTitle() {
    switch (ctrl.CurrentMenu) {
      case 0:
        return "Dashboard";
      case 1:
        return "User Management";
      case 2:
        return "Exam Results";
      case 3:
        return "Slider Images";
      case 4:
        return "Popular Courses";
      case 5:
        return "Access Types";
      case 6:
        return "Question Types";
      default:
        return "Dashboard";
    }
  }

  IconData _getCurrentScreenIcon() {
    switch (ctrl.CurrentMenu) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.people_rounded;
      case 2:
        return Icons.assignment_rounded;
      case 3:
        return Icons.image_rounded;
      case 4:
        return Icons.star_rounded;
      case 5:
        return Icons.lock_rounded;
      case 6:
        return Icons.help_outline_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (context) {
        return Scaffold(
          backgroundColor: Color(0xffF5F7FA),
          body: Row(
            children: [
              // Modern Sidebar
              SideBar(),
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Enhanced Top App Bar
                    _buildTopBar(),
                    // Content Area with Animation
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          child: _getCurrentScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon and Title
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCurrentScreenIcon(),
              color: primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getCurrentScreenTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1A2332),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                _getBreadcrumb(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Spacer(),
          // Additional Actions Area
          _buildTopBarActions(),
        ],
      ),
    );
  }

  Widget _buildTopBarActions() {
    return Row(
      children: [
        // Notification Icon (optional - can be implemented later)
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Color(0xff2C3E50),
            size: 22,
          ),
        ),
        SizedBox(width: 12),
        // User Avatar/Profile (optional)
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.account_circle_rounded,
            color: primaryColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  String _getBreadcrumb() {
    return "Home / ${_getCurrentScreenTitle()}";
  }
}
