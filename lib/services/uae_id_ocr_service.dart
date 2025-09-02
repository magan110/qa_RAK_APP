import 'dart:async';
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
    if (kIsWeb) {
      print('=== WEB ENVIRONMENT DETECTED ===');
      return _processWebMLKit(imagePath);
    }

    try {
      print('=== STARTING ML KIT OCR ===');
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return UAEIdData();
      }

      return _extractDataFromText(recognizedText.text);
    } catch (e) {
      print('ML Kit error: $e');
      return UAEIdData();
    }
  }

  // Web-compatible ML Kit processing
  static Future<UAEIdData> _processWebMLKit(String imagePath) async {
    try {
      print('=== WEB ML KIT OCR PROCESSING START ===');
      print('Processing image: $imagePath');

      final extractedText = await _extractTextWithGoogleMLKit(imagePath);

      if (extractedText.isEmpty) {
        print('No text extracted from Google ML Kit OCR');
        return UAEIdData();
      }

      print('Extracted text length: ${extractedText.length}');
      final extractedData = _extractDataFromText(extractedText);

      print('=== ML KIT EXTRACTION RESULTS ===');
      print('Name: ${extractedData.name}');
      print('ID Number: ${extractedData.idNumber}');
      print('Date of Birth: ${extractedData.dateOfBirth}');
      print('Nationality: ${extractedData.nationality}');
      print('Occupation: ${extractedData.occupation}');
      print('Employer: ${extractedData.employer}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END ML KIT EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Web ML Kit OCR error: $e');
      return UAEIdData();
    }
  }

  // Extract text using Google ML Kit for webview
  static Future<String> _extractTextWithGoogleMLKit(String imagePath) async {
    try {
      print('Calling Google ML Kit OCR function...');
      print('Image path: $imagePath');

      // Create a completer to handle the Promise
      final completer = Completer<String>();

      // Set up callbacks for the Promise
      js.context['dartMLKitCallback'] = js.allowInterop((String result) {
        if (!completer.isCompleted) {
          print('Google ML Kit OCR result received');
          print('OCR result length: ${result.length}');
          completer.complete(result);
        }
      });

      js.context['dartMLKitErrorCallback'] = js.allowInterop((dynamic error) {
        if (!completer.isCompleted) {
          print('Google ML Kit OCR error: $error');
          completer.complete('');
        }
      });

      // Call the Google ML Kit JavaScript function
      js.context.callMethod('eval', [
        '''
        processImageWithGoogleMLKit("$imagePath")
          .then(function(result) {
            if (window.dartMLKitCallback) {
              window.dartMLKitCallback(result || '');
            }
          })
          .catch(function(error) {
            if (window.dartMLKitErrorCallback) {
              window.dartMLKitErrorCallback(error);
            }
          });
      ''',
      ]);

      final result = await completer.future;

      // Clean up callbacks
      js.context['dartMLKitCallback'] = null;
      js.context['dartMLKitErrorCallback'] = null;

      return result;
    } catch (e) {
      print('Google ML Kit OCR failed: $e');
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
    print('=== RAW OCR TEXT FROM DART ===');
    print(ocrText);
    print('=== END RAW TEXT ===');
    print('Lines count: ${lines.length}');

    // First pass - extract from the full text using better patterns
    final fullText = ocrText.toLowerCase();
    
    // Extract name from "Name: Mohammad Azhar Hussain" pattern
    final nameMatch = RegExp(r'name:\s*([a-z\s]+)', caseSensitive: false).firstMatch(ocrText);
    if (nameMatch != null) {
      name = nameMatch.group(1)?.trim();
    }
    
    // Extract occupation from "Occupation: Head Of Department" pattern  
    final occupationMatch = RegExp(r'occupation:\s*([a-z\s]+)', caseSensitive: false).firstMatch(ocrText);
    if (occupationMatch != null) {
      occupation = occupationMatch.group(1)?.trim();
    }
    
    // Extract employer from "Employer: Company Name" pattern
    final employerMatch = RegExp(r'employer:\s*([a-z0-9\s/&-]+)', caseSensitive: false).firstMatch(ocrText);
    if (employerMatch != null) {
      employer = employerMatch.group(1)?.trim();
    }
    
    // Extract all dates and categorize them
    final allDates = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').allMatches(ocrText);
    final foundDates = <String>[];
    for (final match in allDates) {
      final date = match.group(0)!;
      final year = int.parse(match.group(3)!);
      foundDates.add(date);
      
      // Categorize dates by year ranges
      if (year >= 1950 && year <= 2010 && dateOfBirth == null) {
        dateOfBirth = date;
      } else if (year >= 2020 && year <= 2035 && expiryDate == null) {
        expiryDate = date;
      } else if (year >= 2010 && year <= 2025 && issuingDate == null) {
        issuingDate = date;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // Skip name extraction in line-by-line loop since we did it above

      // Extract ID Number - look for 784-XXXX-XXXXXXX-X pattern
      final idMatch = RegExp(
        r'784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)',
      ).firstMatch(line);
      if (idMatch != null) {
        idNumber =
            '784-${idMatch.group(1)}-${idMatch.group(2)}-${idMatch.group(3)}';
      }

      // Extract Date of Birth - look for "Date of Birth:" pattern
      if (lowerLine.contains('date of birth:')) {
        dateOfBirth = _extractDateFromLine(line);
      }

      // Extract Nationality
      if (lowerLine.contains('nationality') || line.contains('الجنسية')) {
        nationality = _extractValueAfterColon(line);
        if ((nationality == null || nationality.isEmpty) &&
            i + 1 < lines.length) {
          nationality = lines[i + 1].trim();
        }
      }

      // Extract nationality from text patterns
      if (nationality == null) {
        // Look for nationality patterns in the line
        final nationalityPattern = RegExp(r'\b([A-Z][a-z]{2,})\b');
        final matches = nationalityPattern.allMatches(line);
        for (final match in matches) {
          final word = match.group(1);
          if (word != null && word.length > 3) {
            nationality = word;
            break;
          }
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

      // Extract Card Number - look for "Card Number" pattern
      if (lowerLine.contains('card number')) {
        final cardMatch = RegExp(
          r'card number[\s\/]*(\d{7,8})',
          caseSensitive: false,
        ).firstMatch(line);
        if (cardMatch != null) {
          cardNumber = cardMatch.group(1);
        }
      }

      // Skip occupation extraction in line-by-line loop since we did it above

      // Skip employer extraction in line-by-line loop since we did it above

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

      // Extract dates by pattern matching
      final dateMatches = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').allMatches(line);
      for (final dateMatch in dateMatches) {
        final foundDate = dateMatch.group(0)!;
        final year = int.parse(dateMatch.group(3)!);
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);

        // Birth date: typically 1950-2010
        if (year >= 1950 && year <= 2010 && dateOfBirth == null) {
          dateOfBirth = foundDate;
        }
        // Expiry date: typically 2020-2035 
        else if (year >= 2020 && year <= 2035 && expiryDate == null) {
          expiryDate = foundDate;
        }
        // Issue date: typically 2010-2025, and should be before expiry date
        else if (year >= 2010 && year <= 2025 && issuingDate == null) {
          // Additional validation: issue date should be reasonable
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            issuingDate = foundDate;
          }
        }
      }
    }

    // Post-processing cleanup
    name = _cleanName(name);
    occupation = _cleanOccupation(occupation);
    employer = _cleanEmployer(employer);
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

    // Clean up nationality text
    nationality = nationality.replaceAll(RegExp(r'[^A-Za-z\s]'), ' ');
    nationality = nationality.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Reject if too short
    if (nationality.length < 3) return null;
    
    return _capitalizeWords(nationality);
  }

  static String? _cleanSex(String? sex) {
    if (sex == null || sex.isEmpty) return null;

    final cleaned = sex.toLowerCase().trim();
    if (cleaned.startsWith('m') || cleaned == 'male') return 'M';
    if (cleaned.startsWith('f') || cleaned == 'female') return 'F';

    return sex.toUpperCase().trim();
  }

  static String? _cleanOccupation(String? occupation) {
    if (occupation == null || occupation.isEmpty) return null;
    
    // Remove OCR artifacts and clean up
    occupation = occupation.replaceAll(RegExp(r'[^A-Za-z\s]'), ' ');
    occupation = occupation.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Reject if too short or contains artifacts
    if (occupation.length < 3) return null;
    
    return _capitalizeWords(occupation);
  }

  static String? _cleanEmployer(String? employer) {
    if (employer == null || employer.isEmpty) return null;
    
    // Remove OCR artifacts but keep valid company characters
    employer = employer.replaceAll(RegExp(r'[^A-Za-z0-9\s/&-]'), ' ');
    employer = employer.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Reject if too short or contains artifacts
    if (employer.length < 5) return null;
    
    return _capitalizeWords(employer);
  }

  static String? _extractValueAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return null;
  }

  static String? _extractDateFromLine(String line) {
    // Extract date in various formats
    final datePatterns = [
      RegExp(r'\d{2}/\d{2}/\d{4}'), // DD/MM/YYYY
      RegExp(r'\d{1,2}/\d{1,2}/\d{4}'), // D/M/YYYY or DD/M/YYYY
      RegExp(r'\d{2}-\d{2}-\d{4}'), // DD-MM-YYYY
      RegExp(r'\d{4}/\d{2}/\d{2}'), // YYYY/MM/DD
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
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
  
  // Auto-fill form fields with enhanced mapping
  static Map<String, String> getFormFieldMapping(UAEIdData data) {
    final mapping = <String, String>{};
    
    if (data.name != null) {
      final nameParts = data.name!.split(' ');
      if (nameParts.isNotEmpty) {
        mapping['firstName'] = nameParts.first;
        mapping['idName'] = data.name!;
      }
      if (nameParts.length > 1) {
        mapping['lastName'] = nameParts.last;
      }
      if (nameParts.length > 2) {
        mapping['middleName'] = nameParts.skip(1).take(nameParts.length - 2).join(' ');
      }
    }
    
    if (data.idNumber != null) mapping['emiratesId'] = data.idNumber!;
    if (data.dateOfBirth != null) mapping['dateOfBirth'] = data.dateOfBirth!;
    if (data.nationality != null) mapping['nationality'] = data.nationality!;
    if (data.issuingDate != null) mapping['issueDate'] = data.issuingDate!;
    if (data.expiryDate != null) mapping['expiryDate'] = data.expiryDate!;
    if (data.occupation != null) mapping['occupation'] = data.occupation!;
    if (data.employer != null) mapping['employer'] = data.employer!;
    if (data.issuingPlace != null) mapping['issuingPlace'] = data.issuingPlace!;
    
    return mapping;
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
