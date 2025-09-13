class SampleLeadRequest {
  final String? area;
  final String? cityDistrict;
  final String? pinCode;
  final String? customerName;
  final String? contractorName;
  final String? mobileNumber;
  final String? address;
  final String? siteType;
  final String? sampleLocalReceivedPerson;
  final String? targetDateOfConversion;
  final String? remarks;
  final String? regionOfConstruction;
  final String? latitude;
  final String? longitude;
  final String? samplingDate;
  final String? product;
  final String? siteMaterialExpectedOrder;
  final String? sampleType;

  SampleLeadRequest({
    this.area,
    this.cityDistrict,
    this.pinCode,
    this.customerName,
    this.contractorName,
    this.mobileNumber,
    this.address,
    this.siteType,
    this.sampleLocalReceivedPerson,
    this.targetDateOfConversion,
    this.remarks,
    this.regionOfConstruction,
    this.latitude,
    this.longitude,
    this.samplingDate,
    this.product,
    this.siteMaterialExpectedOrder,
    this.sampleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'cityDistrict': cityDistrict,
      'pinCode': pinCode,
      'customerName': customerName,
      'contractorName': contractorName,
      'mobileNumber': mobileNumber,
      'address': address,
      'siteType': siteType,
      'sampleLocalReceivedPerson': sampleLocalReceivedPerson,
      'targetDateOfConversion': targetDateOfConversion,
      'remarks': remarks,
      'regionOfConstruction': regionOfConstruction,
      'latitude': latitude,
      'longitude': longitude,
      'samplingDate': samplingDate,
      'product': product,
      'siteMaterialExpectedOrder': siteMaterialExpectedOrder,
      'sampleType': sampleType,
    };
  }
}

class SampleLeadResponse {
  final bool success;
  final String message;
  final String? documentNumber;
  final String? error;
  final DateTime timestamp;

  SampleLeadResponse({
    required this.success,
    required this.message,
    this.documentNumber,
    this.error,
    required this.timestamp,
  });

  factory SampleLeadResponse.fromJson(Map<String, dynamic> json) {
    return SampleLeadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      documentNumber: json['documentNumber'],
      error: json['error'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
    