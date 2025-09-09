import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // key import
import 'package:rak_web/features/products/screens/incentive_scheme_form.dart';
import 'package:rak_web/features/quality_control/screens/dashboard_screen.dart';
import 'package:rak_web/screens/splash_screen.dart';
import 'core/theme/theme.dart';
import 'features/auth/screens/login_screen_with_otp.dart';
import 'features/auth/screens/login_with_password_screen.dart';
import 'features/registration/screens/registration_type_screen.dart';
import 'features/registration/screens/contractor_registration_screen.dart';
import 'features/registration/screens/painter_registration_screen.dart';
import 'features/quality_control/screens/approval_dashboard_screen.dart';

import 'features/registration/screens/registration_details_screen.dart';
import 'features/registration/screens/success_screen.dart';
import 'screens/file_manager_screen.dart';

import 'screens/home_screen.dart';
import 'screens/camera_scanner_screen.dart';
import 'screens/qr_input_screen.dart';
import 'features/retail/screens/retailer_onboarding_screen.dart';
import 'features/registration/screens/retailer_registration.dart';
import 'features/retail/screens/retail_entry_screen.dart' as retail_entry;
import 'features/products/screens/new_product_entry_screen.dart';
import 'features/products/screens/sample_distribution_entry_screen.dart';
import 'features/products/screens/sampling_drive_form_screen.dart';
import 'core/di/service_locator.dart';

void main() async {
  // Critical for smooth back/forward inside InAppWebView
  setUrlStrategy(const HashUrlStrategy());

  // Initialize service locator
  await setupServiceLocator();

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
      initialRoute: '/splash-screen',
      // Use pushNamed for user-perceived screen changes to create history entries
      routes: {
        '/splash-screen': (context) => const SplashScreen(),
        '/login-password': (context) => const LoginWithPasswordScreen(),
        '/login-otp': (context) => const LoginScreenWithOtp(),
        '/home': (context) => const HomeScreen(),
        '/registration-type': (context) => const RegistrationTypeScreen(),
        '/contractor-registration': (context) =>
            const ContractorRegistrationScreen(),
        '/painter-registration': (context) => const PainterRegistrationScreen(),
        '/approval-dashboard': (context) => const ApprovalDashboardScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/registration-details': (context) => const RegistrationDetailsScreen(),
        '/success': (context) => const SuccessScreen(),
        '/file-manager': (context) => const FileManagerScreen(),
        '/camera-scanner': (context) => const CameraScannerScreen(),
        '/qr-input': (context) => const QRInputScreen(),
        '/retailer-onboarding': (context) => const RetailerOnboardingApp(),
        '/retailer-registration': (context) => const RetailerRegistration(),
        '/retail-entry': (context) =>
            const retail_entry.RetailerRegistrationPage(),
        '/new-product-entry': (context) => NewProductEntry(),
        '/sample-distribution': (context) => SampleDistributEntry(),
        '/sampling-drive-form': (context) => SamplingDriveFormPage(),
        '/incentive-scheme-form': (context) => IncentiveSchemeFormPage(),
      },
    );
  }
}
