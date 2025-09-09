class ContractorRegistrationRequest {
  // Personal Details
  final String contractorType;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String mobileNumber;
  final String address;
  final String area;
  final String emirates;
  final String reference;
  final String? profilePhoto;

  // Emirates ID Details
  final String? emiratesIdFront;
  final String? emiratesIdBack;
  final String emiratesIdNumber;
  final String idHolderName;
  final String? dateOfBirth;
  final String nationality;
  final String? emiratesIdIssueDate;
  final String? emiratesIdExpiryDate;
  final String? occupation;
  final String? employer;

  // Bank Details
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;

  // VAT Certificate Details
  final String? vatCertificate;
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;

  // Commercial License Details
  final String? licenseDocument;
  final String licenseNumber;
  final String issuingAuthority;
  final String licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String tradeName;
  final String responsiblePerson;
  final String licenseAddress;
  final String? effectiveDate;

  const ContractorRegistrationRequest({
    required this.contractorType,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.mobileNumber,
    required this.address,
    required this.area,
    required this.emirates,
    required this.reference,
    this.profilePhoto,
    this.emiratesIdFront,
    this.emiratesIdBack,
    required this.emiratesIdNumber,
    required this.idHolderName,
    this.dateOfBirth,
    required this.nationality,
    this.emiratesIdIssueDate,
    this.emiratesIdExpiryDate,
    this.occupation,
    this.employer,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
    this.vatCertificate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,
    this.licenseDocument,
    required this.licenseNumber,
    required this.issuingAuthority,
    required this.licenseType,
    this.establishmentDate,
    this.licenseExpiryDate,
    required this.tradeName,
    required this.responsiblePerson,
    required this.licenseAddress,
    this.effectiveDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'contractorType': contractorType,
      'firstName': firstName,
      'middleName': middleName ?? '',
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'address': address,
      'area': area,
      'emirates': emirates,
      'reference': reference,
      'profilePhoto': profilePhoto ?? '',
      'emiratesIdFront': emiratesIdFront ?? '',
      'emiratesIdBack': emiratesIdBack ?? '',
      'emiratesIdNumber': emiratesIdNumber,
      'idHolderName': idHolderName,
      'dateOfBirth': dateOfBirth ?? '',
      'nationelity': nationality, // Note: matches C# property name exactly
      'emiratesIdIssueDate': emiratesIdIssueDate ?? '',
      'emiratesIdExpiryDate': emiratesIdExpiryDate ?? '',
      'occupation': occupation ?? '',
      'employer': employer ?? '',
      'accountHolderName': accountHolderName ?? '',
      'ibanNumber': ibanNumber ?? '',
      'bankName': bankName ?? '',
      'branchName': branchName ?? '',
      'bankAddress': bankAddress ?? '',
      'vatCertificate': vatCertificate ?? '',
      'firmName': firmName ?? '',
      'vatAddress': vatAddress ?? '',
      'taxRegistrationNumber': taxRegistrationNumber ?? '',
      'vatEffectiveDate': vatEffectiveDate ?? '',
      'licenseDocument': licenseDocument ?? '',
      'licenseNumber': licenseNumber,
      'issuingAuthority': issuingAuthority,
      'licenseType': licenseType,
      'establishmentDate': establishmentDate ?? '',
      'licenseExpiryDate': licenseExpiryDate ?? '',
      'tradeName': tradeName,
      'responsiblePerson': responsiblePerson,
      'licenseAddress': licenseAddress,
      'effectiveDate': effectiveDate ?? '',
    };
  }

  factory ContractorRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return ContractorRegistrationRequest(
      contractorType: json['contractorType'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName']?.isEmpty == true ? null : json['middleName'],
      lastName: json['lastName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      address: json['address'] ?? '',
      area: json['area'] ?? '',
      emirates: json['emirates'] ?? '',
      reference: json['reference'] ?? '',
      profilePhoto: json['profilePhoto']?.isEmpty == true ? null : json['profilePhoto'],
      emiratesIdFront: json['emiratesIdFront']?.isEmpty == true ? null : json['emiratesIdFront'],
      emiratesIdBack: json['emiratesIdBack']?.isEmpty == true ? null : json['emiratesIdBack'],
      emiratesIdNumber: json['emiratesIdNumber'] ?? '',
      idHolderName: json['idHolderName'] ?? '',
      dateOfBirth: json['dateOfBirth']?.isEmpty == true ? null : json['dateOfBirth'],
      nationality: json['nationelity'] ?? json['nationality'] ?? '', // Handle both spellings
      emiratesIdIssueDate: json['emiratesIdIssueDate']?.isEmpty == true ? null : json['emiratesIdIssueDate'],
      emiratesIdExpiryDate: json['emiratesIdExpiryDate']?.isEmpty == true ? null : json['emiratesIdExpiryDate'],
      occupation: json['occupation']?.isEmpty == true ? null : json['occupation'],
      employer: json['employer']?.isEmpty == true ? null : json['employer'],
      accountHolderName: json['accountHolderName']?.isEmpty == true ? null : json['accountHolderName'],
      ibanNumber: json['ibanNumber']?.isEmpty == true ? null : json['ibanNumber'],
      bankName: json['bankName']?.isEmpty == true ? null : json['bankName'],
      branchName: json['branchName']?.isEmpty == true ? null : json['branchName'],
      bankAddress: json['bankAddress']?.isEmpty == true ? null : json['bankAddress'],
      vatCertificate: json['vatCertificate']?.isEmpty == true ? null : json['vatCertificate'],
      firmName: json['firmName']?.isEmpty == true ? null : json['firmName'],
      vatAddress: json['vatAddress']?.isEmpty == true ? null : json['vatAddress'],
      taxRegistrationNumber: json['taxRegistrationNumber']?.isEmpty == true ? null : json['taxRegistrationNumber'],
      vatEffectiveDate: json['vatEffectiveDate']?.isEmpty == true ? null : json['vatEffectiveDate'],
      licenseDocument: json['licenseDocument']?.isEmpty == true ? null : json['licenseDocument'],
      licenseNumber: json['licenseNumber'] ?? '',
      issuingAuthority: json['issuingAuthority'] ?? '',
      licenseType: json['licenseType'] ?? '',
      establishmentDate: json['establishmentDate']?.isEmpty == true ? null : json['establishmentDate'],
      licenseExpiryDate: json['licenseExpiryDate']?.isEmpty == true ? null : json['licenseExpiryDate'],
      tradeName: json['tradeName'] ?? '',
      responsiblePerson: json['responsiblePerson'] ?? '',
      licenseAddress: json['licenseAddress'] ?? '',
      effectiveDate: json['effectiveDate']?.isEmpty == true ? null : json['effectiveDate'],
    );
  }

  ContractorRegistrationRequest copyWith({
    String? contractorType,
    String? firstName,
    String? middleName,
    String? lastName,
    String? mobileNumber,
    String? address,
    String? area,
    String? emirates,
    String? reference,
    String? profilePhoto,
    String? emiratesIdFront,
    String? emiratesIdBack,
    String? emiratesIdNumber,
    String? idHolderName,
    String? dateOfBirth,
    String? nationality,
    String? emiratesIdIssueDate,
    String? emiratesIdExpiryDate,
    String? occupation,
    String? employer,
    String? accountHolderName,
    String? ibanNumber,
    String? bankName,
    String? branchName,
    String? bankAddress,
    String? vatCertificate,
    String? firmName,
    String? vatAddress,
    String? taxRegistrationNumber,
    String? vatEffectiveDate,
    String? licenseDocument,
    String? licenseNumber,
    String? issuingAuthority,
    String? licenseType,
    String? establishmentDate,
    String? licenseExpiryDate,
    String? tradeName,
    String? responsiblePerson,
    String? licenseAddress,
    String? effectiveDate,
  }) {
    return ContractorRegistrationRequest(
      contractorType: contractorType ?? this.contractorType,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      area: area ?? this.area,
      emirates: emirates ?? this.emirates,
      reference: reference ?? this.reference,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      emiratesIdFront: emiratesIdFront ?? this.emiratesIdFront,
      emiratesIdBack: emiratesIdBack ?? this.emiratesIdBack,
      emiratesIdNumber: emiratesIdNumber ?? this.emiratesIdNumber,
      idHolderName: idHolderName ?? this.idHolderName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      emiratesIdIssueDate: emiratesIdIssueDate ?? this.emiratesIdIssueDate,
      emiratesIdExpiryDate: emiratesIdExpiryDate ?? this.emiratesIdExpiryDate,
      occupation: occupation ?? this.occupation,
      employer: employer ?? this.employer,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      ibanNumber: ibanNumber ?? this.ibanNumber,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      bankAddress: bankAddress ?? this.bankAddress,
      vatCertificate: vatCertificate ?? this.vatCertificate,
      firmName: firmName ?? this.firmName,
      vatAddress: vatAddress ?? this.vatAddress,
      taxRegistrationNumber: taxRegistrationNumber ?? this.taxRegistrationNumber,
      vatEffectiveDate: vatEffectiveDate ?? this.vatEffectiveDate,
      licenseDocument: licenseDocument ?? this.licenseDocument,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      licenseType: licenseType ?? this.licenseType,
      establishmentDate: establishmentDate ?? this.establishmentDate,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      tradeName: tradeName ?? this.tradeName,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      licenseAddress: licenseAddress ?? this.licenseAddress,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}

class DocumentUploadRequest {
  final String documentType;
  final String filePath;
  final String? originalFileName;

  const DocumentUploadRequest({
    required this.documentType,
    required this.filePath,
    this.originalFileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'filePath': filePath,
      'originalFileName': originalFileName,
    };
  }

  factory DocumentUploadRequest.fromJson(Map<String, dynamic> json) {
    return DocumentUploadRequest(
      documentType: json['documentType'] ?? '',
      filePath: json['filePath'] ?? '',
      originalFileName: json['originalFileName'],
    );
  }
}

class ContractorRegistrationResponse {
  final bool success;
  final String message;
  final String? contractorId;
  final String? error;
  final DateTime timestamp;

  const ContractorRegistrationResponse({
    required this.success,
    required this.message,
    this.contractorId,
    this.error,
    required this.timestamp,
  });

  factory ContractorRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return ContractorRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      contractorId: json['contractorId'],
      error: json['error'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'contractorId': contractorId,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DocumentUploadResponse {
  final bool success;
  final String message;
  final String? fileName;
  final String? filePath;
  final String? documentType;
  final String? error;
  final DateTime timestamp;

  const DocumentUploadResponse({
    required this.success,
    required this.message,
    this.fileName,
    this.filePath,
    this.documentType,
    this.error,
    required this.timestamp,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      fileName: json['fileName'],
      filePath: json['filePath'],
      documentType: json['documentType'],
      error: json['error'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'fileName': fileName,
      'filePath': filePath,
      'documentType': documentType,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Enum-like classes for constants
class ContractorTypes {
  static const String maintenanceContractor = "Maintenance Contractor";
  static const String pettyContractors = "Petty contractors";
  
  static const List<String> all = [
    maintenanceContractor,
    pettyContractors,
  ];
}

class EmiratesConstants {
  static const String dubai = "Dubai";
  static const String abuDhabi = "Abu Dhabi";
  static const String sharjah = "Sharjah";
  static const String ajman = "Ajman";
  static const String ummAlQuwain = "Umm Al Quwain";
  static const String rasAlKhaimah = "Ras Al Khaimah";
  static const String fujairah = "Fujairah";
  
  static const List<String> all = [
    dubai,
    abuDhabi,
    sharjah,
    ajman,
    ummAlQuwain,
    rasAlKhaimah,
    fujairah,
  ];
}

class DocumentTypes {
  static const String profilePhoto = "profilePhoto";
  static const String emiratesIdFront = "emiratesIdFront";
  static const String emiratesIdBack = "emiratesIdBack";
  static const String vatCertificate = "vatCertificate";
  static const String licenseDocument = "licenseDocument";
  
  static const List<String> all = [
    profilePhoto,
    emiratesIdFront,
    emiratesIdBack,
    vatCertificate,
    licenseDocument,
  ];
}