import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:http/http.dart';
import 'package:mathlab_admin/Screen/HomeScreen/Homescreen.dart';
import 'package:mathlab_admin/Screen/LoginScreen/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Constants/Strings.dart';

String token = "";
String log = "";

void main() async {
  // Error handling wrapper
  runZonedGuarded(() async {
    // HttpOverrides not needed on web - browser handles certificates
    // For mobile/desktop, HttpOverrides would be set here if needed
    
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      
      // Fix null check - getString returns null, not "null" string
      String? loginStatus = pref.getString("LOGIN");
      log = loginStatus ?? "OUT";
      
      // Check authentication in background without blocking app startup
      if (log == "IN") {
        String? savedToken = pref.getString("TOKEN");
        token = savedToken ?? "";
        
        // Run auth check asynchronously without blocking app startup
        _checkAuthStatus(pref).catchError((error) {
          print("Auth check error: $error");
          // Don't block app if auth check fails
        });
      }
    } catch (e) {
      print("Error initializing app: $e");
      // Set default values if SharedPreferences fails
      log = "OUT";
    }
    
    runApp(MathLabAdmin());
  }, (error, stack) {
    print("Uncaught error: $error");
    print("Stack trace: $stack");
    // Still try to run the app even if there's an error
    runApp(ErrorWidget(error));
  });
}

// Separate function for auth check to avoid blocking
Future<void> _checkAuthStatus(SharedPreferences pref) async {
  try {
    if (token.isNotEmpty) {
      final response = await get(
        Uri.parse("$endpoint/applicationview/get-user-profile/"),
        headers: {"Authorization": "token $token"},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        log = "out";
        await pref.setString("LOGIN", "OUT");
        // Note: ShowToast won't work here as context isn't available
        // This will be handled when user tries to access protected routes
      } else if (response.statusCode == 200) {
        // Auth is valid
      } else {
        log = "error";
      }
    }
  } catch (e) {
    print("Error checking auth status: $e");
    // Don't block app if network request fails
  }
}

class MathLabAdmin extends StatelessWidget {
  const MathLabAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MathLab Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xffBB2828),
          primary: Color(0xffBB2828),
          secondary: Color(0xff2C3E50),
        ),
        scaffoldBackgroundColor: Color(0xffF5F7FA),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff2C3E50),
        ),
      ),
      builder: (context, child) {
        // Add error boundary
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
      home: Builder(
        builder: (context) {
          try {
            Widget homeWidget = (log == "IN") ? HomeScreen() : LoginScreen();
            return homeWidget;
          } catch (e, stack) {
            print("Error building home widget: $e");
            print("Stack: $stack");
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading app",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "$e",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

