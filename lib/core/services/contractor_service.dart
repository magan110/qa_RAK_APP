import 'dart:async';
import 'dart:convert';
import '../models/contractor_models.dart';
import '../utils/app_logger.dart';
import 'api_service.dart';

class ContractorService {
  static final AppLogger _logger = AppLogger();
  
  // Static data caches
  static List<String>? _contractorTypes;
  static List<String>? _emiratesList;

  // Registration methods
  static Future<ContractorRegistrationResponse> registerContractor(
    ContractorRegistrationRequest request,
  ) async {
    try {
      _logger.info('Registering contractor: ${request.firstName} ${request.lastName}');

      final result = await ApiService.registerContractor(request.toJson());

      if (result['success'] == true) {
        return ContractorRegistrationResponse.fromJson(result['data'] ?? {});
      } else {
        return ContractorRegistrationResponse(
          success: false,
          message: result['error'] ?? 'Registration failed',
          error: result['error'],
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.error('Contractor registration failed', e);
      return ContractorRegistrationResponse(
        success: false,
        message: 'Registration failed: $e',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // Document upload methods
  static Future<DocumentUploadResponse> uploadDocument({
    required String filePath,
    required String documentType,
    String? originalFileName,
  }) async {
    try {
      _logger.info('Uploading document: $documentType');

      final result = await ApiService.uploadContractorDocument(
        filePath: filePath,
        documentType: documentType,
        originalName: originalFileName,
      );

      if (result['success'] == true) {
        return DocumentUploadResponse.fromJson(result['data'] ?? {});
      } else {
        return DocumentUploadResponse(
          success: false,
          message: result['error'] ?? 'Upload failed',
          error: result['error'],
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.error('Document upload failed', e);
      return DocumentUploadResponse(
        success: false,
        message: 'Upload failed: $e',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // Batch document upload
  static Future<List<DocumentUploadResponse>> uploadMultipleDocuments(
    List<DocumentUploadRequest> documents,
  ) async {
    final responses = <DocumentUploadResponse>[];
    
    for (final doc in documents) {
      final response = await uploadDocument(
        filePath: doc.filePath,
        documentType: doc.documentType,
        originalFileName: doc.originalFileName,
      );
      responses.add(response);
      
      // Add a small delay between uploads to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return responses;
  }

  // Configuration data methods
  static Future<List<String>> getContractorTypes({bool forceRefresh = false}) async {
    if (_contractorTypes != null && !forceRefresh) {
      return _contractorTypes!;
    }

    try {
      _logger.info('Fetching contractor types');

      final result = await ApiService.getContractorTypes();

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic> && data['data'] is List) {
          _contractorTypes = (data['data'] as List).cast<String>();
          return _contractorTypes!;
        }
      }
      
      // Fallback to hardcoded values
      _logger.warning('Using fallback contractor types');
      _contractorTypes = ContractorTypes.all;
      return _contractorTypes!;
    } catch (e) {
      _logger.error('Failed to fetch contractor types', e);
      _contractorTypes = ContractorTypes.all;
      return _contractorTypes!;
    }
  }

  static Future<List<String>> getEmiratesList({bool forceRefresh = false}) async {
    if (_emiratesList != null && !forceRefresh) {
      return _emiratesList!;
    }

    try {
      _logger.info('Fetching emirates list');

      final result = await ApiService.getEmiratesList();

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic> && data['data'] is List) {
          _emiratesList = (data['data'] as List).cast<String>();
          return _emiratesList!;
        }
      }
      
      // Fallback to hardcoded values
      _logger.warning('Using fallback emirates list');
      _emiratesList = EmiratesConstants.all;
      return _emiratesList!;
    } catch (e) {
      _logger.error('Failed to fetch emirates list', e);
      _emiratesList = EmiratesConstants.all;
      return _emiratesList!;
    }
  }

  // Validation methods
  static bool isValidEmiratesId(String emiratesId) {
    // UAE Emirates ID format: 784-YYYY-NNNNNNN-N
    final regex = RegExp(r'^784-\d{4}-\d{7}-\d$');
    return regex.hasMatch(emiratesId);
  }

  static bool isValidMobileNumber(String mobileNumber) {
    // UAE mobile number format: +971XXXXXXXXX or 05XXXXXXXX
    final regex = RegExp(r'^(\+971|971|0)?[5][0-9]{8}$');
    return regex.hasMatch(mobileNumber.replaceAll(' ', '').replaceAll('-', ''));
  }

  static bool isValidIban(String iban) {
    // UAE IBAN format: AE followed by 21 digits
    final regex = RegExp(r'^AE\d{21}$');
    return regex.hasMatch(iban.replaceAll(' ', ''));
  }

  static bool isValidDate(String date) {
    if (date.isEmpty) return false;
    
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods for form validation
  static String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmiratesId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Emirates ID is required';
    }
    if (!isValidEmiratesId(value)) {
      return 'Please enter a valid Emirates ID (784-YYYY-NNNNNNN-N)';
    }
    return null;
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!isValidMobileNumber(value)) {
      return 'Please enter a valid UAE mobile number';
    }
    return null;
  }

  static String? validateIban(String? value) {
    if (value != null && value.isNotEmpty && !isValidIban(value)) {
      return 'Please enter a valid UAE IBAN (AE followed by 21 digits)';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!regex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  // Data formatting methods
  static String formatEmiratesId(String emiratesId) {
    // Remove any existing formatting
    String cleaned = emiratesId.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Format as 784-YYYY-NNNNNNN-N
    if (cleaned.length >= 15) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7, 14)}-${cleaned.substring(14, 15)}';
    }
    return emiratesId;
  }

  static String formatMobileNumber(String mobile) {
    // Remove any existing formatting
    String cleaned = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Ensure it starts with +971
    if (cleaned.startsWith('05')) {
      cleaned = '+971${cleaned.substring(1)}';
    } else if (cleaned.startsWith('5')) {
      cleaned = '+971$cleaned';
    } else if (!cleaned.startsWith('+971')) {
      cleaned = '+971$cleaned';
    }
    
    return cleaned;
  }

  static String formatIban(String iban) {
    // Remove any existing formatting and convert to uppercase
    String cleaned = iban.replaceAll(' ', '').toUpperCase();
    
    // Add spaces every 4 characters for readability
    String formatted = '';
    for (int i = 0; i < cleaned.length; i += 4) {
      if (i + 4 < cleaned.length) {
        formatted += '${cleaned.substring(i, i + 4)} ';
      } else {
        formatted += cleaned.substring(i);
      }
    }
    
    return formatted.trim();
  }

  // Utility methods
  static void clearCache() {
    _contractorTypes = null;
    _emiratesList = null;
  }

  static String getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case DocumentTypes.profilePhoto:
        return 'Profile Photo';
      case DocumentTypes.emiratesIdFront:
        return 'Emirates ID (Front)';
      case DocumentTypes.emiratesIdBack:
        return 'Emirates ID (Back)';
      case DocumentTypes.vatCertificate:
        return 'VAT Certificate';
      case DocumentTypes.licenseDocument:
        return 'Commercial License';
      default:
        return documentType;
    }
  }

  static List<String> getRequiredDocuments() {
    return [
      DocumentTypes.emiratesIdFront,
      DocumentTypes.emiratesIdBack,
      DocumentTypes.licenseDocument,
    ];
  }

  static List<String> getOptionalDocuments() {
    return [
      DocumentTypes.profilePhoto,
      DocumentTypes.vatCertificate,
    ];
  }
}