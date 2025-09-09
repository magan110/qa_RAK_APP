// Test file for ContractorService - This is for development testing only
// Remove or move to test directory before production

import '../models/contractor_models.dart';
import 'contractor_service.dart';
import '../utils/app_logger.dart';

class ContractorServiceTest {
  static final AppLogger _logger = AppLogger();

  // Test methods
  static Future<void> testContractorTypes() async {
    _logger.info('Testing contractor types fetch...');
    
    try {
      final types = await ContractorService.getContractorTypes();
      _logger.info('Contractor types: $types');
      
      // Verify expected types are present
      final expectedTypes = ['Maintenance Contractor', 'Petty contractors'];
      for (final type in expectedTypes) {
        if (!types.contains(type)) {
          _logger.warning('Expected contractor type not found: $type');
        }
      }
      
      _logger.info('✓ Contractor types test completed');
    } catch (e) {
      _logger.error('✗ Contractor types test failed', e);
    }
  }

  static Future<void> testEmiratesList() async {
    _logger.info('Testing emirates list fetch...');
    
    try {
      final emirates = await ContractorService.getEmiratesList();
      _logger.info('Emirates: $emirates');
      
      // Verify expected emirates are present
      final expectedEmirates = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah'];
      for (final emirate in expectedEmirates) {
        if (!emirates.contains(emirate)) {
          _logger.warning('Expected emirate not found: $emirate');
        }
      }
      
      _logger.info('✓ Emirates list test completed');
    } catch (e) {
      _logger.error('✗ Emirates list test failed', e);
    }
  }

  static Future<void> testValidation() async {
    _logger.info('Testing validation methods...');
    
    try {
      // Test Emirates ID validation
      final validEmiratesId = '784-2023-1234567-1';
      final invalidEmiratesId = '123-456-789';
      
      assert(ContractorService.isValidEmiratesId(validEmiratesId), 'Valid Emirates ID should pass validation');
      assert(!ContractorService.isValidEmiratesId(invalidEmiratesId), 'Invalid Emirates ID should fail validation');
      
      // Test mobile number validation
      final validMobile = '0501234567';
      final invalidMobile = '123456';
      
      assert(ContractorService.isValidMobileNumber(validMobile), 'Valid mobile should pass validation');
      assert(!ContractorService.isValidMobileNumber(invalidMobile), 'Invalid mobile should fail validation');
      
      // Test IBAN validation
      final validIban = 'AE123456789012345678901';
      final invalidIban = 'AE123';
      
      assert(ContractorService.isValidIban(validIban), 'Valid IBAN should pass validation');
      assert(!ContractorService.isValidIban(invalidIban), 'Invalid IBAN should fail validation');
      
      _logger.info('✓ Validation tests completed');
    } catch (e) {
      _logger.error('✗ Validation tests failed', e);
    }
  }

  static Future<void> testFormatting() async {
    _logger.info('Testing formatting methods...');
    
    try {
      // Test Emirates ID formatting
      final emiratesIdInput = '78420231234567­1';
      final formattedEmiratesId = ContractorService.formatEmiratesId(emiratesIdInput);
      _logger.info('Formatted Emirates ID: $formattedEmiratesId');
      
      // Test mobile formatting
      final mobileInput = '0501234567';
      final formattedMobile = ContractorService.formatMobileNumber(mobileInput);
      _logger.info('Formatted mobile: $formattedMobile');
      
      // Test IBAN formatting
      final ibanInput = 'AE123456789012345678901';
      final formattedIban = ContractorService.formatIban(ibanInput);
      _logger.info('Formatted IBAN: $formattedIban');
      
      _logger.info('✓ Formatting tests completed');
    } catch (e) {
      _logger.error('✗ Formatting tests failed', e);
    }
  }

  static Future<void> testContractorRegistration() async {
    _logger.info('Testing contractor registration...');
    
    try {
      // Create a sample contractor registration request
      final request = ContractorRegistrationRequest(
        contractorType: 'Maintenance Contractor',
        firstName: 'Ahmed',
        middleName: 'Ali',
        lastName: 'Hassan',
        mobileNumber: '+971501234567',
        address: '123 Test Street, Test Area',
        area: 'Test Area',
        emirates: 'Dubai',
        reference: 'TEST_REF_001',
        emiratesIdNumber: '784-2023-1234567-1',
        idHolderName: 'Ahmed Ali Hassan',
        nationality: 'UAE',
        licenseNumber: 'LIC123456',
        issuingAuthority: 'Dubai Municipality',
        licenseType: 'Construction License',
        tradeName: 'Ahmed Construction LLC',
        responsiblePerson: 'Ahmed Ali Hassan',
        licenseAddress: '123 Test Street, Dubai',
        dateOfBirth: '1990-01-01',
        emiratesIdIssueDate: '2023-01-01',
        emiratesIdExpiryDate: '2033-01-01',
        establishmentDate: '2020-01-01',
        licenseExpiryDate: '2025-01-01',
        effectiveDate: '2024-01-01',
        // Optional fields
        occupation: 'Construction Manager',
        employer: 'Self Employed',
        accountHolderName: 'Ahmed Ali Hassan',
        ibanNumber: 'AE123456789012345678901',
        bankName: 'Emirates NBD',
        branchName: 'Dubai Main Branch',
        bankAddress: 'Sheikh Zayed Road, Dubai',
        firmName: 'Ahmed Construction LLC',
        vatAddress: '123 Test Street, Dubai',
        taxRegistrationNumber: 'TRN123456789',
        vatEffectiveDate: '2020-01-01',
      );
      
      _logger.info('Sample request created: ${request.toJson()}');
      
      // This would make an actual API call - comment out for now to avoid hitting the server during testing
      // final response = await ContractorService.registerContractor(request);
      // _logger.info('Registration response: ${response.toJson()}');
      
      _logger.info('✓ Contractor registration test structure completed (API call skipped)');
    } catch (e) {
      _logger.error('✗ Contractor registration test failed', e);
    }
  }

  static Future<void> runAllTests() async {
    _logger.info('🧪 Starting ContractorService tests...');
    
    await testValidation();
    await testFormatting();
    
    // Skip API tests for now to avoid hitting the server during development
    // await testContractorTypes();
    // await testEmiratesList();
    // await testContractorRegistration();
    
    _logger.info('🎉 All tests completed!');
  }
}

// Helper function to run tests (can be called from main or debug environment)
Future<void> runContractorServiceTests() async {
  await ContractorServiceTest.runAllTests();
}