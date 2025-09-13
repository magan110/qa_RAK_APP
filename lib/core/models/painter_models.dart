class PainterRegistrationRequest {
  // Personal
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
  final String? reference;

  // Emirates ID Details
  final String? emiratesIdNumber;
  final String? idName;          // Name on ID
  final String? dateOfBirth;     // yyyy-MM-dd preferred
  final String? nationality;
  final String? companyDetails;  // Employer
  final String? issueDate;       // yyyy-MM-dd or string
  final String? expiryDate;      // yyyy-MM-dd or string
  final String? occupation;

  // Bank (optional)
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;

  PainterRegistrationRequest({
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.reference,
    this.emiratesIdNumber,
    this.idName,
    this.dateOfBirth,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
  });

  // empty string for null/blank
  String _empty(String? v) => (v == null || v.trim().isEmpty) ? '' : v.trim();

  Map<String, dynamic> toJson() => {
        // Personal
        "firstName": _empty(firstName),
        "middleName": _empty(middleName),
        "lastName": _empty(lastName),
        "mobileNumber": _empty(mobileNumber),
        "address": _empty(address),
        "area": _empty(area),
        "emirates": _empty(emirates),
        "reference": _empty(reference),

        // Emirates ID
        "emiratesIdNumber": _empty(emiratesIdNumber),
        "idName": _empty(idName),
        "dateOfBirth": _empty(dateOfBirth),
        "nationality": _empty(nationality),
        "companyDetails": _empty(companyDetails),
        "issueDate": _empty(issueDate),
        "expiryDate": _empty(expiryDate),
        "occupation": _empty(occupation),

        // Bank
        "accountHolderName": _empty(accountHolderName),
        "ibanNumber": _empty(ibanNumber),
        "bankName": _empty(bankName),
        "branchName": _empty(branchName),
        "bankAddress": _empty(bankAddress),
      };
}

class PainterRegistrationResponse {
  final bool success;
  final String message;
  final String? influencerCode; // inflCode returned from API

  PainterRegistrationResponse({
    required this.success,
    required this.message,
    this.influencerCode,
  });

  factory PainterRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return PainterRegistrationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      influencerCode: json['influencerCode']?.toString(),
    );
  }
}
