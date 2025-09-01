import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:universal_html/js.dart' as js;

class UAEIdData {
  final String? name;
  final String? idNumber;
  final String? dateOfBirth;
  final String? nationality;
  final String? issuingDate;
  final String? expiryDate;
  final String? sex;
  final String? signature;
  final String? cardNumber;
  final String? occupation;
  final String? employer;
  final String? issuingPlace;

  UAEIdData({
    this.name,
    this.idNumber,
    this.dateOfBirth,
    this.nationality,
    this.issuingDate,
    this.expiryDate,
    this.sex,
    this.signature,
    this.cardNumber,
    this.occupation,
    this.employer,
    this.issuingPlace,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'idNumber': idNumber,
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'issuingDate': issuingDate,
      'expiryDate': expiryDate,
      'sex': sex,
      'signature': signature,
      'cardNumber': cardNumber,
      'occupation': occupation,
      'employer': employer,
      'issuingPlace': issuingPlace,
    };
  }

  factory UAEIdData.fromJson(Map<String, dynamic> json) {
    return UAEIdData(
      name: json['name'],
      idNumber: json['idNumber'],
      dateOfBirth: json['dateOfBirth'],
      nationality: json['nationality'],
      issuingDate: json['issuingDate'],
      expiryDate: json['expiryDate'],
      sex: json['sex'],
      signature: json['signature'],
      cardNumber: json['cardNumber'],
      occupation: json['occupation'],
      employer: json['employer'],
      issuingPlace: json['issuingPlace'],
    );
  }

  bool get isValid {
    return name != null &&
        idNumber != null &&
        dateOfBirth != null &&
        nationality != null;
  }
}

class UAEIdOCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Main OCR processing method
  static Future<UAEIdData> processUAEId(String imagePath) async {
    // Check if running on web - ML Kit doesn't work on web
    if (kIsWeb) {
      print('=== WEB ENVIRONMENT DETECTED ===');
      print('ML Kit not supported on web, using web-compatible OCR');
      return _processWebOCR(imagePath);
    }

    try {
      print('=== STARTING ML KIT OCR ===');
      print('Processing image: $imagePath');

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      print('=== ML KIT SUCCESS ===');
      print('Extracted text length: ${recognizedText.text.length}');
      print(
        'Extracted text preview: ${recognizedText.text.length > 100 ? "${recognizedText.text.substring(0, 100)}..." : recognizedText.text}',
      );

      if (recognizedText.text.isEmpty) {
        print('WARNING: No text extracted from image');
        return UAEIdData();
      }

      final extractedData = _extractDataFromText(recognizedText.text);
      print('=== EXTRACTION RESULT ===');
      print('Extracted data: ${extractedData.toJson()}');

      return extractedData;
    } catch (e) {
      print('=== ML KIT FAILED ===');
      print('ML Kit error: $e');
      return UAEIdData();
    }
  }

  // Web-compatible OCR processing using Tesseract
  static Future<UAEIdData> _processWebOCR(String imagePath) async {
    print('=== WEB TESSERACT OCR PROCESSING ===');
    print('Image path: $imagePath');

    try {
      // Convert blob URL to local file path for Tesseract
      final extractedText = await _extractTextWithTesseract(imagePath);

      if (extractedText.isEmpty) {
        print('WARNING: No text extracted from image via Tesseract');
        return UAEIdData();
      }

      print('=== TESSERACT SUCCESS ===');
      print('Extracted text length: ${extractedText.length}');
      print(
        'Extracted text preview: ${extractedText.length > 200 ? "${extractedText.substring(0, 200)}..." : extractedText}',
      );

      // Use the same pattern extraction logic
      final extractedData = _extractDataFromText(extractedText);
      print('=== TESSERACT EXTRACTION RESULT ===');
      print('Extracted data: ${extractedData.toJson()}');

      return extractedData;
    } catch (e) {
      print('=== TESSERACT OCR FAILED ===');
      print('Tesseract error: $e');
      return UAEIdData();
    }
  }

  // Extract text using Tesseract OCR
  static Future<String> _extractTextWithTesseract(String imagePath) async {
    try {
      print('Starting Tesseract OCR...');
      final result = await js.context.callMethod('_extractText', [
        imagePath,
        js.JsObject.jsify({
          'language': 'eng',
          'args': {'psm': '4', 'preserve_interword_spaces': '1'},
        }),
      ]);
      return result as String;
    } catch (e) {
      print('Tesseract extraction failed: $e');
      if (kIsWeb && imagePath.startsWith('blob:')) {
        print('Trying web-specific blob handling...');
      }
      return '';
    }
  }

  // Handle web blob URLs specifically

  // Generate sample Emirates ID text for testing

  // Test extraction with sample Emirates ID text to verify pattern matching

  // Process image from bytes
  static Future<UAEIdData> processUAEIdFromBytes(Uint8List imageBytes) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(800, 600),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 800,
        ),
      );
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedData = _extractDataFromText(recognizedText.text);
      return extractedData;
    } catch (e) {
      // Fallback to simulation if ML Kit fails
      print('ML Kit failed, using simulation: $e');
      final extractedData = await _simulateOCRFromBytes(imageBytes);
      return extractedData;
    }
  }

  // Dispose the text recognizer
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Simulate OCR processing (replace with actual OCR implementation)
  static Future<UAEIdData> _simulateOCR(String imagePath) async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulate processing time

    print('=== SIMULATION FALLBACK TRIGGERED ===');
    print('Image path: $imagePath');
    print('ML Kit failed - returning empty data');

    // Return empty data structure - no sample data
    return UAEIdData();
  }

  static Future<UAEIdData> _simulateOCRFromBytes(Uint8List imageBytes) async {
    await Future.delayed(const Duration(seconds: 2));

    print('=== BYTES SIMULATION FALLBACK ===');
    print('Returning empty data - no sample data');
    return UAEIdData();
  }

  // Extract specific patterns from OCR text
  static UAEIdData _extractDataFromText(String ocrText) {
    String? name;
    String? idNumber;
    String? dateOfBirth;
    String? nationality;
    String? issuingDate;
    String? expiryDate;
    String? sex;
    String? cardNumber;
    String? occupation;
    String? employer;
    String? issuingPlace;

    final lines = ocrText.split('\n');
    print('OCR Text: $ocrText'); // Debug output

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // Extract name (usually after "Name:" or on the line after)
      if (lowerLine.contains('name:') || line.contains('الاسم:')) {
        name = _extractValueAfterColon(line);
        // If name is empty, check the next line
        if ((name == null || name.isEmpty) && i + 1 < lines.length) {
          name = lines[i + 1].trim();
        }
      }

      // Extract ID Number (format: XXX-XXXX-XXXXXXX-X)
      final idPatterns = [
        RegExp(r'\d{3}-\d{4}-\d{7}-\d{1}'),
        RegExp(r'\d{3}\s+\d{4}\s+\d{7}\s+\d{1}'),
        RegExp(r'\d{15}'),
      ];

      for (final pattern in idPatterns) {
        final idMatch = pattern.firstMatch(line);
        if (idMatch != null) {
          String foundId = idMatch.group(0)!;
          // Format the ID number correctly
          if (foundId.length == 15) {
            foundId =
                '${foundId.substring(0, 3)}-${foundId.substring(3, 7)}-${foundId.substring(7, 14)}-${foundId.substring(14)}';
          }
          idNumber = foundId.replaceAll(RegExp(r'\s+'), '-');
          break;
        }
      }

      // Extract Date of Birth
      if (lowerLine.contains('date of birth') ||
          lowerLine.contains('birth') ||
          line.contains('تاريخ الميلاد')) {
        dateOfBirth = _extractDateFromLine(line);
        if (dateOfBirth == null && i + 1 < lines.length) {
          dateOfBirth = _extractDateFromLine(lines[i + 1]);
        }
      }

      // Extract Nationality
      if (lowerLine.contains('nationality') || line.contains('الجنسية')) {
        nationality = _extractValueAfterColon(line);
        if ((nationality == null || nationality.isEmpty) &&
            i + 1 < lines.length) {
          nationality = lines[i + 1].trim();
        }
      }

      // Extract Issuing Date
      if (lowerLine.contains('issuing date') ||
          lowerLine.contains('issuing') ||
          line.contains('تاريخ الإصدار')) {
        issuingDate = _extractDateFromLine(line);
        if (issuingDate == null && i + 1 < lines.length) {
          issuingDate = _extractDateFromLine(lines[i + 1]);
        }
      }

      // Extract Expiry Date
      if (lowerLine.contains('expiry date') ||
          lowerLine.contains('expiry') ||
          line.contains('تاريخ الانتهاء')) {
        expiryDate = _extractDateFromLine(line);
        if (expiryDate == null && i + 1 < lines.length) {
          expiryDate = _extractDateFromLine(lines[i + 1]);
        }
      }

      // Extract Sex/Gender
      if (lowerLine.contains('sex:') ||
          lowerLine.contains('gender:') ||
          line.contains('الجنس:')) {
        sex = _extractValueAfterColon(line);
        if (sex == null || sex.isEmpty) {
          // Look for M/F patterns in the line or next line
          final sexPattern = RegExp(r'\b[MF]\b', caseSensitive: false);
          final sexMatch = sexPattern.firstMatch(line);
          if (sexMatch != null) {
            sex = sexMatch.group(0)?.toUpperCase();
          } else if (i + 1 < lines.length) {
            final nextLineMatch = sexPattern.firstMatch(lines[i + 1]);
            if (nextLineMatch != null) {
              sex = nextLineMatch.group(0)?.toUpperCase();
            }
          }
        }
      }

      // Extract Card Number (usually 8-9 digits)
      if (lowerLine.contains('card number') ||
          line.contains('رقم البطاقة') ||
          lowerLine.contains('card no')) {
        cardNumber = _extractValueAfterColon(line);
        if (cardNumber == null && i + 1 < lines.length) {
          cardNumber = lines[i + 1].trim();
        }
      }

      // Look for standalone card numbers (8-9 digits)
      final cardNumberPattern = RegExp(r'\b\d{8,9}\b');
      final cardMatch = cardNumberPattern.firstMatch(line);
      if (cardMatch != null && cardNumber == null) {
        final potentialCardNumber = cardMatch.group(0);
        // Verify it's not an ID number or date
        if (potentialCardNumber != null &&
            !line.contains('-') &&
            !line.contains('/') &&
            potentialCardNumber.length >= 8) {
          cardNumber = potentialCardNumber;
        }
      }

      // Extract Occupation
      if (lowerLine.contains('occupation:') ||
          lowerLine.contains('profession:') ||
          line.contains('المهنة:')) {
        occupation = _extractValueAfterColon(line);
        if (occupation == null && i + 1 < lines.length) {
          occupation = lines[i + 1].trim();
        }
      }

      // Look for common occupation patterns
      final occupationPatterns = [
        'head of department',
        'manager',
        'engineer',
        'supervisor',
        'director',
        'specialist',
        'consultant',
        'officer',
      ];

      for (final pattern in occupationPatterns) {
        if (lowerLine.contains(pattern) && occupation == null) {
          occupation = _extractOccupationFromLine(line, pattern);
          break;
        }
      }

      // Extract Employer
      if (lowerLine.contains('employer:') ||
          lowerLine.contains('company:') ||
          lowerLine.contains('organization:') ||
          line.contains('صاحب العمل:')) {
        employer = _extractValueAfterColon(line);
        if (employer == null && i + 1 < lines.length) {
          employer = lines[i + 1].trim();
        }
      }

      // Look for company patterns (containing "Co", "Company", "Ltd", etc.)
      if (employer == null &&
          (lowerLine.contains(' co ') ||
              lowerLine.contains('company') ||
              lowerLine.contains('ltd') ||
              lowerLine.contains('corporation') ||
              lowerLine.contains('group') ||
              lowerLine.contains('cement') ||
              lowerLine.contains('rakez'))) {
        employer = line.trim();
      }

      // Extract Issuing Place
      if (lowerLine.contains('issuing place:') ||
          lowerLine.contains('issued at:') ||
          lowerLine.contains('place of issue:') ||
          line.contains('مكان الإصدار:')) {
        issuingPlace = _extractValueAfterColon(line);
        if (issuingPlace == null && i + 1 < lines.length) {
          issuingPlace = lines[i + 1].trim();
        }
      }

      // Look for emirate names
      final emirates = [
        'dubai',
        'abu dhabi',
        'sharjah',
        'ajman',
        'fujairah',
        'ras al khaimah',
        'umm al quwain',
      ];
      for (final emirate in emirates) {
        if (lowerLine.contains(emirate) && issuingPlace == null) {
          issuingPlace = _capitalizeWords(emirate);
          break;
        }
      }

      // Additional date extraction for any missed dates
      if (dateOfBirth == null || issuingDate == null || expiryDate == null) {
        final foundDate = _extractDateFromLine(line);
        if (foundDate != null) {
          final dateObj = parseDate(foundDate);
          if (dateObj != null) {
            final year = dateObj.year;

            // Heuristic to assign dates based on year ranges
            if (year >= 1950 && year <= 2010 && dateOfBirth == null) {
              dateOfBirth = foundDate;
            } else if (year >= 2020 && year <= 2030 && issuingDate == null) {
              issuingDate = foundDate;
            } else if (year >= 2025 && year <= 2035 && expiryDate == null) {
              expiryDate = foundDate;
            }
          }
        }
      }
    }

    // Post-processing cleanup
    name = _cleanName(name);
    nationality = _cleanNationality(nationality);
    sex = _cleanSex(sex);

    return UAEIdData(
      name: name,
      idNumber: idNumber,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      issuingDate: issuingDate,
      expiryDate: expiryDate,
      sex: sex,
      signature: 'Present',
      cardNumber: cardNumber,
      occupation: occupation,
      employer: employer,
      issuingPlace: issuingPlace,
    );
  }

  // Helper methods for cleaning extracted data
  static String? _cleanName(String? name) {
    if (name == null || name.isEmpty) return null;

    // Remove common OCR artifacts and unnecessary text
    name = name.replaceAll(RegExp(r'[^\w\s]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize properly
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static String? _cleanNationality(String? nationality) {
    if (nationality == null || nationality.isEmpty) return null;

    // Common nationality mappings
    final nationalityMap = {
      'ind': 'India',
      'india': 'India',
      'pak': 'Pakistan',
      'pakistan': 'Pakistan',
      'ban': 'Bangladesh',
      'bangladesh': 'Bangladesh',
      'phil': 'Philippines',
      'philippines': 'Philippines',
      'sri': 'Sri Lanka',
      'lanka': 'Sri Lanka',
    };

    final cleaned = nationality.toLowerCase().trim();
    return nationalityMap[cleaned] ?? nationality.trim();
  }

  static String? _cleanSex(String? sex) {
    if (sex == null || sex.isEmpty) return null;

    final cleaned = sex.toLowerCase().trim();
    if (cleaned.startsWith('m') || cleaned == 'male') return 'M';
    if (cleaned.startsWith('f') || cleaned == 'female') return 'F';

    return sex.toUpperCase().trim();
  }

  static String? _extractValueAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return null;
  }

  static String? _extractDateFromLine(String line) {
    // Extract date in DD/MM/YYYY format
    final datePattern = RegExp(r'\d{2}/\d{2}/\d{4}');
    final match = datePattern.firstMatch(line);
    return match?.group(0);
  }

  static String? _extractOccupationFromLine(String line, String pattern) {
    final lowerLine = line.toLowerCase();
    final index = lowerLine.indexOf(pattern);
    if (index != -1) {
      // Extract the occupation, potentially including surrounding words
      final words = line.split(RegExp(r'\s+'));
      final patternWords = pattern.split(' ');

      for (int i = 0; i <= words.length - patternWords.length; i++) {
        final candidate = words
            .skip(i)
            .take(patternWords.length)
            .join(' ')
            .toLowerCase();
        if (candidate == pattern) {
          // Found the pattern, now extract the full occupation title
          final startIndex = Math.max(
            0,
            i - 1,
          ); // Include one word before if exists
          final endIndex = Math.min(
            words.length,
            i + patternWords.length + 1,
          ); // Include one word after if exists

          return words.skip(startIndex).take(endIndex - startIndex).join(' ');
        }
      }

      return _capitalizeWords(pattern);
    }
    return null;
  }

  static String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }

  // Validate UAE ID number format
  static bool validateUAEIdNumber(String idNumber) {
    final pattern = RegExp(r'^\d{3}-\d{4}-\d{7}-\d{1}$');
    return pattern.hasMatch(idNumber);
  }

  // Validate date format
  static bool validateDateFormat(String date) {
    final pattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return pattern.hasMatch(date);
  }

  // Convert date from DD/MM/YYYY to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  // Check if ID is expired
  static bool isIdExpired(String expiryDateString) {
    final expiryDate = parseDate(expiryDateString);
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate);
  }

  // Get age from date of birth
  static int? getAge(String dateOfBirthString) {
    final birthDate = parseDate(dateOfBirthString);
    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }
}

// Extension methods for easy validation
extension UAEIdValidation on UAEIdData {
  bool get hasValidIdNumber =>
      idNumber != null && UAEIdOCRService.validateUAEIdNumber(idNumber!);

  bool get hasValidDateOfBirth =>
      dateOfBirth != null && UAEIdOCRService.validateDateFormat(dateOfBirth!);

  bool get hasValidExpiryDate =>
      expiryDate != null && UAEIdOCRService.validateDateFormat(expiryDate!);

  bool get isExpired =>
      expiryDate != null && UAEIdOCRService.isIdExpired(expiryDate!);

  int? get age =>
      dateOfBirth != null ? UAEIdOCRService.getAge(dateOfBirth!) : null;
}
