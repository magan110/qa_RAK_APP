class RetailerOnboardingRequest {
  final String? firmName;
  final String? taxRegistrationNumber;
  final String? registeredAddress;
  final String? effectiveRegistrationDate;
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? establishmentDate;
  final String? expiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? branchAddress;
  final String? latitude;
  final String? longitude;

  const RetailerOnboardingRequest({
    this.firmName,
    this.taxRegistrationNumber,
    this.registeredAddress,
    this.effectiveRegistrationDate,
    this.licenseNumber,
    this.issuingAuthority,
    this.establishmentDate,
    this.expiryDate,
    this.tradeName,
    this.responsiblePerson,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.branchAddress,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['firmName'] = firmName;
    data['taxRegistrationNumber'] = taxRegistrationNumber;
    data['registeredAddress'] = registeredAddress;
    data['effectiveRegistrationDate'] = effectiveRegistrationDate;
    data['licenseNumber'] = licenseNumber;
    data['issuingAuthority'] = issuingAuthority;
    data['establishmentDate'] = establishmentDate;
    data['expiryDate'] = expiryDate;
    data['tradeName'] = tradeName;
    data['responsiblePerson'] = responsiblePerson;
    data['accountHolderName'] = accountHolderName;
    data['ibanNumber'] = ibanNumber;
    data['bankName'] = bankName;
    data['branchName'] = branchName;
    data['branchAddress'] = branchAddress;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }

  factory RetailerOnboardingRequest.fromJson(Map<String, dynamic> json) {
    return RetailerOnboardingRequest(
      firmName: json['firmName'] as String?,
      taxRegistrationNumber: json['taxRegistrationNumber'] as String?,
      registeredAddress: json['registeredAddress'] as String?,
      effectiveRegistrationDate: json['effectiveRegistrationDate'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      issuingAuthority: json['issuingAuthority'] as String?,
      establishmentDate: json['establishmentDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      tradeName: json['tradeName'] as String?,
      responsiblePerson: json['responsiblePerson'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      ibanNumber: json['ibanNumber'] as String?,
      bankName: json['bankName'] as String?,
      branchName: json['branchName'] as String?,
      branchAddress: json['branchAddress'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
    );
  }
}

class RetailerOnboardingResponse {
  final bool success;
  final String message;
  final String? retailerCode;
  final String? error;
  final DateTime timestamp;

  const RetailerOnboardingResponse({
    required this.success,
    required this.message,
    this.retailerCode,
    this.error,
    required this.timestamp,
  });

  factory RetailerOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return RetailerOnboardingResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      retailerCode: json['retailerCode'] as String?,
      error: json['error'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}