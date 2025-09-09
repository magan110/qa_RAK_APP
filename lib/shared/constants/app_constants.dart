class AppConstants {
  // App Information
  static const String appName = 'RAK Business Management';
  static const String appVersion = '1.0.0';
  
  // Company Information
  static const String companyName = 'Ras Al Khaimah Co. For White Cement & Construction Materials';
  static const String companyShortName = 'RAKWCCM';
  static const String companyWebsite = 'https://rakwhitecement.ae/';
  
  // API Configuration
  static const String baseUrl = 'https://api.rakwhitecement.ae'; // Replace with actual API
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // File Upload Configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'
  ];
  
  // Business Constants
  static const List<String> productTypes = [
    'White Cement',
    'Quick Lime (Powder)',
    'Quick Lime (Lumps)', 
    'Hydrated Lime',
    'Dolomitic Lime',
    'Concrete Blocks',
    'Interlocks',
    'Kerbstones',
  ];
  
  static const List<String> registrationTypes = [
    'Contractor',
    'Painter',
    'Retailer',
  ];
  
  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
}