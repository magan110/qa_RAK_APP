import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/login_screen.dart';
import 'screens/registration/registration_type_screen.dart';
import 'screens/registration/contractor_registration_screen.dart';
import 'screens/registration/painter_registration_screen.dart';
import 'screens/registration/ocr_screen.dart';
import 'screens/dashboard/approval_dashboard_screen.dart';
import 'screens/registration/registration_details_screen.dart';
import 'screens/registration/success_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

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
      title: 'Painter/Contractor Onboarding',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registration-type': (context) => const RegistrationTypeScreen(),
        '/contractor-registration': (context) =>
            const ContractorRegistrationScreen(),
        '/painter-registration': (context) => const PainterRegistrationScreen(),
        '/ocr-screen': (context) => const OcrScreen(),
        '/approval-dashboard': (context) => const ApprovalDashboardScreen(),
        '/registration-details': (context) => const RegistrationDetailsScreen(),
        '/success': (context) => const SuccessScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
