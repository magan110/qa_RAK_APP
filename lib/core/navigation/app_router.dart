import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:rak_web/features/products/screens/incentive_scheme_form.dart';
import 'package:rak_web/features/products/screens/sampling_drive_form_screen.dart';
import 'package:rak_web/features/quality_control/screens/dashboard_screen.dart';

// Auth Screens
import '../../features/auth/screens/login_screen_with_otp.dart';
import '../../features/auth/screens/login_with_password_screen.dart';

// Registration Screens
import '../../features/registration/screens/registration_type_screen.dart';
import '../../features/registration/screens/contractor_registration_screen.dart';
import '../../features/registration/screens/painter_registration_screen.dart';
import '../../features/registration/screens/registration_details_screen.dart';
import '../../features/registration/screens/success_screen.dart';
import '../../features/registration/screens/retailer_registration.dart';

// Retail Screens
import '../../features/retail/screens/retailer_onboarding_screen.dart';
import '../../features/retail/screens/retail_entry_screen.dart' as retail_entry;

// Product Screens
import '../../features/products/screens/new_product_entry_screen.dart';
import '../../features/products/screens/sample_distribution_entry_screen.dart';

// Quality Control Screens
import '../../features/quality_control/screens/approval_dashboard_screen.dart';

// Common Screens (to be moved later)
import '../../screens/splash_screen.dart';
import '../../screens/home_screen.dart';

import '../../screens/file_manager_screen.dart';

import '../../screens/camera_scanner_screen.dart';
import '../../screens/qr_input_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String loginPassword = '/login-password';
  static const String loginOtp = '/login-otp';
  static const String home = '/home';

  // Registration routes
  static const String registrationType = '/registration-type';
  static const String contractorRegistration = '/contractor-registration';
  static const String painterRegistration = '/painter-registration';
  static const String registrationDetails = '/registration-details';
  static const String registrationSuccess = '/success';
  static const String retailerRegistration = '/retailer-registration';

  // Retail routes
  static const String retailerOnboarding = '/retailer-onboarding';
  static const String retailEntry = '/retail-entry';

  // Product routes
  static const String newProductEntry = '/new-product-entry';
  static const String sampleDistribution = '/sample-distribution';
  static const String samplingDriveForm = '/sampling-drive-form';
  static const String incentiveSchemeFormPage = '/incentive-scheme-form';

  // Quality Control routes
  static const String approvalDashboard = '/approval-dashboard';
  static const String dashboard = '/dashboard';

  // Utility routes
  static const String fileManager = '/file-manager';
  static const String uploadTest = '/upload-test';
  static const String cameraScanner = '/camera-scanner';
  static const String qrInput = '/qr-input';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash and Auth
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: loginPassword,
        builder: (context, state) => const LoginWithPasswordScreen(),
      ),
      GoRoute(
        path: loginOtp,
        builder: (context, state) => const LoginScreenWithOtp(),
      ),

      // Main App
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),

      // Registration Feature
      GoRoute(
        path: registrationType,
        builder: (context, state) => const RegistrationTypeScreen(),
      ),
      GoRoute(
        path: contractorRegistration,
        builder: (context, state) => const ContractorRegistrationScreen(),
      ),
      GoRoute(
        path: painterRegistration,
        builder: (context, state) => const PainterRegistrationScreen(),
      ),
      GoRoute(
        path: registrationDetails,
        builder: (context, state) => const RegistrationDetailsScreen(),
      ),
      GoRoute(
        path: registrationSuccess,
        builder: (context, state) => const SuccessScreen(),
      ),
      GoRoute(
        path: retailerRegistration,
        builder: (context, state) => const RetailerRegistration(),
      ),

      // Retail Feature
      GoRoute(
        path: retailerOnboarding,
        builder: (context, state) => const RetailerOnboardingApp(),
      ),
      GoRoute(
        path: retailEntry,
        builder: (context, state) =>
            const retail_entry.RetailerRegistrationPage(),
      ),

      // Product Feature
      GoRoute(
        path: newProductEntry,
        builder: (context, state) => NewProductEntry(),
      ),
      GoRoute(
        path: sampleDistribution,
        builder: (context, state) => SampleDistributEntry(),
      ),
      GoRoute(
        path: samplingDriveForm,
        builder: (context, state) => SamplingDriveFormPage(),
      ),
      GoRoute(
        path: samplingDriveForm,
        builder: (context, state) => IncentiveSchemeFormPage(),
      ),

      // Quality Control Feature
      GoRoute(
        path: approvalDashboard,
        builder: (context, state) => const ApprovalDashboardScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // Utilities
      GoRoute(
        path: fileManager,
        builder: (context, state) => const FileManagerScreen(),
      ),

      GoRoute(
        path: cameraScanner,
        builder: (context, state) => const CameraScannerScreen(),
      ),
      GoRoute(
        path: qrInput,
        builder: (context, state) => const QRInputScreen(),
      ),
    ],
  );
}
