// Example usage of ContractorService for contractor registration
// This file shows how to use the contractor registration API in your Flutter app

import '../models/contractor_models.dart';
import '../services/contractor_service.dart';
import '../utils/app_logger.dart';

class ContractorRegistrationExample {
  static final AppLogger _logger = AppLogger();

  // Example: Basic contractor registration flow
  static Future<void> basicRegistrationFlow() async {
    _logger.info('Starting basic contractor registration flow...');

    try {
      // 1. Get contractor types and emirates for dropdowns
      final contractorTypes = await ContractorService.getContractorTypes();
      final emirates = await ContractorService.getEmiratesList();
      
      _logger.info('Available contractor types: $contractorTypes');
      _logger.info('Available emirates: $emirates');

      // 2. Create a sample contractor registration request
      final request = ContractorRegistrationRequest(
        // Required Personal Details
        contractorType: contractorTypes.first, // Use first available type
        firstName: 'Ahmed',
        lastName: 'Hassan',
        mobileNumber: '+971501234567',
        address: '123 Business District, Downtown',
        area: 'Business Bay',
        emirates: emirates.contains('Dubai') ? 'Dubai' : emirates.first,
        reference: 'REF_${DateTime.now().millisecondsSinceEpoch}',

        // Required Emirates ID Details
        emiratesIdNumber: '784-2023-1234567-1',
        idHolderName: 'Ahmed Hassan',
        nationality: 'UAE',

        // Required Commercial License Details
        licenseNumber: 'LIC123456789',
        issuingAuthority: 'Dubai Municipality',
        licenseType: 'Construction License',
        tradeName: 'Ahmed Construction LLC',
        responsiblePerson: 'Ahmed Hassan',
        licenseAddress: '123 Business District, Downtown, Dubai',

        // Optional fields
        middleName: 'Ali',
        dateOfBirth: '1985-03-15',
        emiratesIdIssueDate: '2023-01-01',
        emiratesIdExpiryDate: '2033-01-01',
        occupation: 'Construction Manager',
        employer: 'Self Employed',
        
        // Bank details (optional but recommended)
        accountHolderName: 'Ahmed Ali Hassan',
        ibanNumber: 'AE470260001015478963201',
        bankName: 'Emirates NBD',
        branchName: 'Business Bay Branch',
        bankAddress: 'Business Bay, Dubai',
        
        // VAT details (optional)
        firmName: 'Ahmed Construction LLC',
        vatAddress: '123 Business District, Dubai',
        taxRegistrationNumber: 'TRN100123456789012',
        vatEffectiveDate: '2020-01-01',
        
        // License dates
        establishmentDate: '2020-01-01',
        licenseExpiryDate: '2025-12-31',
        effectiveDate: '2024-01-01',
      );

      // 3. Validate the request before sending
      if (validateRegistrationRequest(request)) {
        _logger.info('✓ Registration request validation passed');

        // 4. Submit the registration
        final response = await ContractorService.registerContractor(request);

        if (response.success) {
          _logger.info('✅ Registration successful!');
          _logger.info('Contractor ID: ${response.contractorId}');
          _logger.info('Message: ${response.message}');
        } else {
          _logger.error('❌ Registration failed: ${response.message}');
          if (response.error != null) {
            _logger.error('Error details: ${response.error}');
          }
        }
      } else {
        _logger.error('❌ Registration request validation failed');
      }

    } catch (e) {
      _logger.error('❌ Registration flow failed', e);
    }
  }

  // Example: Document upload flow
  static Future<void> documentUploadFlow() async {
    _logger.info('Starting document upload flow...');

    try {
      // Sample document upload requests
      final documents = [
        DocumentUploadRequest(
          documentType: DocumentTypes.emiratesIdFront,
          filePath: '/path/to/emirates_id_front.jpg', // Replace with actual file path
          originalFileName: 'emirates_id_front.jpg',
        ),
        DocumentUploadRequest(
          documentType: DocumentTypes.emiratesIdBack,
          filePath: '/path/to/emirates_id_back.jpg', // Replace with actual file path
          originalFileName: 'emirates_id_back.jpg',
        ),
        DocumentUploadRequest(
          documentType: DocumentTypes.licenseDocument,
          filePath: '/path/to/commercial_license.pdf', // Replace with actual file path
          originalFileName: 'commercial_license.pdf',
        ),
      ];

      // Upload documents in batch
      final responses = await ContractorService.uploadMultipleDocuments(documents);

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        final document = documents[i];
        
        if (response.success) {
          _logger.info('✅ ${document.documentType} uploaded successfully');
          _logger.info('File name: ${response.fileName}');
          _logger.info('File path: ${response.filePath}');
        } else {
          _logger.error('❌ ${document.documentType} upload failed: ${response.message}');
        }
      }

    } catch (e) {
      _logger.error('❌ Document upload flow failed', e);
    }
  }

  // Example: Single document upload
  static Future<DocumentUploadResponse> uploadSingleDocument(
    String filePath,
    String documentType,
    {String? originalFileName}
  ) async {
    _logger.info('Uploading single document: $documentType');

    try {
      final response = await ContractorService.uploadDocument(
        filePath: filePath,
        documentType: documentType,
        originalFileName: originalFileName,
      );

      if (response.success) {
        _logger.info('✅ Document uploaded successfully');
        _logger.info('File: ${response.fileName}');
        _logger.info('Path: ${response.filePath}');
      } else {
        _logger.error('❌ Document upload failed: ${response.message}');
      }

      return response;
    } catch (e) {
      _logger.error('❌ Document upload error', e);
      return DocumentUploadResponse(
        success: false,
        message: 'Upload failed: $e',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // Example: Form validation
  static bool validateRegistrationRequest(ContractorRegistrationRequest request) {
    _logger.info('Validating registration request...');

    final errors = <String>[];

    // Validate required fields
    if (request.firstName.trim().isEmpty) {
      errors.add('First name is required');
    }
    if (request.lastName.trim().isEmpty) {
      errors.add('Last name is required');
    }
    if (request.mobileNumber.trim().isEmpty) {
      errors.add('Mobile number is required');
    }
    if (request.emiratesIdNumber.trim().isEmpty) {
      errors.add('Emirates ID is required');
    }
    if (request.licenseNumber.trim().isEmpty) {
      errors.add('License number is required');
    }

    // Validate formats using ContractorService validation methods
    final mobileError = ContractorService.validateMobileNumber(request.mobileNumber);
    if (mobileError != null) {
      errors.add(mobileError);
    }

    final emiratesIdError = ContractorService.validateEmiratesId(request.emiratesIdNumber);
    if (emiratesIdError != null) {
      errors.add(emiratesIdError);
    }

    if (request.ibanNumber != null && request.ibanNumber!.isNotEmpty) {
      final ibanError = ContractorService.validateIban(request.ibanNumber);
      if (ibanError != null) {
        errors.add(ibanError);
      }
    }

    // Log validation results
    if (errors.isEmpty) {
      _logger.info('✓ All validation checks passed');
      return true;
    } else {
      _logger.error('❌ Validation errors found:');
      for (final error in errors) {
        _logger.error('  - $error');
      }
      return false;
    }
  }

  // Example: Format user input
  static ContractorRegistrationRequest formatUserInput(
    ContractorRegistrationRequest request
  ) {
    return request.copyWith(
      // Format mobile number
      mobileNumber: ContractorService.formatMobileNumber(request.mobileNumber),
      
      // Format Emirates ID
      emiratesIdNumber: ContractorService.formatEmiratesId(request.emiratesIdNumber),
      
      // Format IBAN if provided
      ibanNumber: request.ibanNumber != null 
          ? ContractorService.formatIban(request.ibanNumber!) 
          : null,
      
      // Trim whitespace from text fields
      firstName: request.firstName.trim(),
      lastName: request.lastName.trim(),
      middleName: request.middleName?.trim(),
      address: request.address.trim(),
      area: request.area.trim(),
      reference: request.reference.trim(),
    );
  }

  // Example: Get formatted data for UI display
  static Map<String, String> getFormattedDisplayData(ContractorRegistrationRequest request) {
    return {
      'Full Name': '${request.firstName} ${request.middleName ?? ''} ${request.lastName}'.trim(),
      'Mobile': ContractorService.formatMobileNumber(request.mobileNumber),
      'Emirates ID': ContractorService.formatEmiratesId(request.emiratesIdNumber),
      'IBAN': request.ibanNumber != null 
          ? ContractorService.formatIban(request.ibanNumber!) 
          : 'Not provided',
      'Address': '${request.address}, ${request.area}, ${request.emirates}',
      'Trade Name': request.tradeName,
      'License Number': request.licenseNumber,
    };
  }

  // Run all examples
  static Future<void> runAllExamples() async {
    _logger.info('🚀 Starting ContractorService examples...');
    
    // Note: These examples use mock data and should be adapted for real use
    await basicRegistrationFlow();
    
    // Document upload examples require actual file paths
    // await documentUploadFlow();
    
    _logger.info('✅ All examples completed!');
  }
}

// Usage instructions:
/*
To use the ContractorService in your Flutter app:

1. Import the required files:
   ```dart
   import 'package:your_app/core/models/contractor_models.dart';
   import 'package:your_app/core/services/contractor_service.dart';
   ```

2. Get dropdown data for forms:
   ```dart
   final contractorTypes = await ContractorService.getContractorTypes();
   final emirates = await ContractorService.getEmiratesList();
   ```

3. Create and submit registration:
   ```dart
   final request = ContractorRegistrationRequest(
     // ... fill in the required fields
   );
   final response = await ContractorService.registerContractor(request);
   ```

4. Upload documents:
   ```dart
   final response = await ContractorService.uploadDocument(
     filePath: filePath,
     documentType: DocumentTypes.emiratesIdFront,
   );
   ```

5. Use validation helpers:
   ```dart
   final mobileError = ContractorService.validateMobileNumber(mobileNumber);
   final emiratesIdError = ContractorService.validateEmiratesId(emiratesId);
   ```

The base URL is already configured to http://10.166.220.55/ in the ApiService.
*/