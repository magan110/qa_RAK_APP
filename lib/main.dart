import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'theme.dart';
import 'screens/login_screen_with_otp.dart';
import 'screens/login_with_password_screen.dart';

import 'screens/registration/registration_type_screen.dart';
import 'screens/registration/contractor_registration_screen.dart';
import 'screens/registration/painter_registration_screen.dart';

import 'screens/dashboard/approval_dashboard_screen.dart';
import 'screens/registration/registration_details_screen.dart';
import 'screens/registration/success_screen.dart';

import 'screens/file_manager_screen.dart';
import 'screens/upload_test_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_scanner_screen.dart';
import 'screens/qr_input_screen.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RAK Business Management',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/login-password',
      routes: {
        '/login-password': (context) => const LoginWithPasswordScreen(),
        '/login-otp': (context) => const LoginScreenWithOtp(),
        '/home': (context) => const HomeScreen(),
        '/registration-type': (context) => const RegistrationTypeScreen(),
        '/contractor-registration': (context) =>
            const ContractorRegistrationScreen(),
        '/painter-registration': (context) => const PainterRegistrationScreen(),
        '/approval-dashboard': (context) => const ApprovalDashboardScreen(),
        '/registration-details': (context) => const RegistrationDetailsScreen(),
        '/success': (context) => const SuccessScreen(),

        '/file-manager': (context) => const FileManagerScreen(),
        '/upload-test': (context) => const UploadTestScreen(),
        '/camera-scanner': (context) => const CameraScannerScreen(),
        '/qr-input': (context) => const QRInputScreen(),
      },
    );
  }
}
