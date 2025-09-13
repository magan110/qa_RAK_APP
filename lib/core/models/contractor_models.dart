class ContractorRegistrationRequest {
  // Personal
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
  final String? reference;
  final String? profilePhoto; // not used now

  // Bank
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;

  // VAT
  final String? vatCertificate; // not used now
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate; // send as yyyy-MM-dd or same as UI text

  // License
  final String? licenseDocument; // not used now
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;

  ContractorRegistrationRequest({
    // personal
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.reference,
    this.profilePhoto,

    // bank
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,

    // vat
    this.vatCertificate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,

    // license
    this.licenseDocument,
    this.licenseNumber,
    this.issuingAuthority,
    this.licenseType,
    this.establishmentDate,
    this.licenseExpiryDate,
    this.tradeName,
    this.responsiblePerson,
    this.licenseAddress,
    this.effectiveDate,
  });

  // helper: empty string if null/blank
  String _empty(String? v) => (v == null || v.trim().isEmpty) ? '' : v.trim();

  Map<String, dynamic> toJson() {
    return {
      // These names match the ASP.NET model properties (case-insensitive)
      "contractorType": _empty(contractorType),
      "firstName": _empty(firstName),
      "middleName": _empty(middleName),
      "lastName": _empty(lastName),
      "mobileNumber": _empty(mobileNumber),
      "address": _empty(address),
      "area": _empty(area),
      "emirates": _empty(emirates),
      "reference": _empty(reference),
      "profilePhoto": _empty(profilePhoto),

      "accountHolderName": _empty(accountHolderName),
      "ibanNumber": _empty(ibanNumber),
      "bankName": _empty(bankName),
      "branchName": _empty(branchName),
      "bankAddress": _empty(bankAddress),

      "vatCertificate": _empty(vatCertificate),
      "firmName": _empty(firmName),
      "vatAddress": _empty(vatAddress),
      "taxRegistrationNumber": _empty(taxRegistrationNumber),
      "vatEffectiveDate": _empty(vatEffectiveDate),

      "licenseDocument": _empty(licenseDocument),
      "licenseNumber": _empty(licenseNumber),
      "issuingAuthority": _empty(issuingAuthority),
      "licenseType": _empty(licenseType),
      "establishmentDate": _empty(establishmentDate),
      "licenseExpiryDate": _empty(licenseExpiryDate),
      "tradeName": _empty(tradeName),
      "responsiblePerson": _empty(responsiblePerson),
      "licenseAddress": _empty(licenseAddress),
      "effectiveDate": _empty(effectiveDate),
    };
  }
}

class ContractorRegistrationResponse {
  final bool success;
  final String message;
  final String? contractorId; // API returns influencerCode or contractorId; handle both
  final String? influencerCode;

  ContractorRegistrationResponse({
    required this.success,
    required this.message,
    this.contractorId,
    this.influencerCode,
  });

  factory ContractorRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return ContractorRegistrationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      contractorId: json['contractorId']?.toString(),
      influencerCode: json['influencerCode']?.toString(),
    );
  }
}
