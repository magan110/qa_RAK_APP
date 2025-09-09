import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/js.dart' as js;
import 'package:pdfx/pdfx.dart';

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
  // Main OCR processing method
  static Future<UAEIdData> processUAEId(String imagePath) async {
    if (kIsWeb) {
      print('=== WEB ENVIRONMENT DETECTED ===');
      return _processWebTesseract(imagePath);
    }

    // Check if file is a PDF
    if (imagePath.toLowerCase().endsWith('.pdf') ||
        imagePath.startsWith('data:application/pdf')) {
      print('=== PDF PROCESSING DETECTED ===');
      return _processPdfFile(imagePath);
    }

    try {
      print('=== STARTING TESSERACT OCR ===');
      return _processTesseractMobile(imagePath);
    } catch (e) {
      print('Tesseract error: $e');
      return UAEIdData();
    }
  }

  // PDF processing method
  static Future<UAEIdData> _processPdfFile(String pdfPath) async {
    try {
      print('=== PDF PROCESSING START ===');
      print('Processing PDF: $pdfPath');

      PdfDocument? document;

      // Handle different PDF path types
      if (pdfPath.startsWith('data:application/pdf')) {
        // Handle base64 PDF data
        final parts = pdfPath.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          document = await PdfDocument.openData(bytes);
        }
      } else if (pdfPath.startsWith('http')) {
        // Handle PDF URL
        document = await PdfDocument.openFile(pdfPath);
      } else if (!kIsWeb) {
        // Handle local file path
        document = await PdfDocument.openFile(pdfPath);
      }

      if (document == null) {
        print('Failed to load PDF document');
        return UAEIdData();
      }

      String combinedText = '';

      // Process each page of the PDF
      for (
        int pageNum = 1;
        pageNum <= document.pagesCount && pageNum <= 5;
        pageNum++
      ) {
        try {
          final page = await document.getPage(pageNum);

          // Render page as high-quality image for better OCR
          final pageImage = await page.render(
            width: (page.width * 3).toDouble(), // Higher resolution
            height: (page.height * 3).toDouble(), // Higher resolution
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF', // White background
          );

          if (pageImage != null) {
            // Process the rendered page image with enhanced preprocessing
            final processedBytes = await _preprocessImageForOCR(
              pageImage.bytes,
            );
            final pageText = await _processTesseractFromBytes(processedBytes);
            combinedText += '$pageText\n';

            print('Page $pageNum text extracted (${pageText.length} chars)');
          }

          await page.close();
        } catch (pageError) {
          print('Error processing page $pageNum: $pageError');
          continue;
        }
      }

      await document.close();

      if (combinedText.isEmpty) {
        print('No text extracted from PDF');
        return UAEIdData();
      }

      print('Combined PDF text length: ${combinedText.length}');
      final extractedData = _extractDataFromText(combinedText);

      print('=== PDF EXTRACTION RESULTS ===');
      print('Name: ${extractedData.name}');
      print('ID Number: ${extractedData.idNumber}');
      print('Date of Birth: ${extractedData.dateOfBirth}');
      print('Nationality: ${extractedData.nationality}');
      print('Occupation: ${extractedData.occupation}');
      print('Employer: ${extractedData.employer}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END PDF EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('PDF processing error: $e');
      return UAEIdData();
    }
  }

  // Web-compatible Tesseract processing
  static Future<UAEIdData> _processWebTesseract(String imagePath) async {
    try {
      print('=== WEB TESSERACT OCR PROCESSING START ===');
      print('Processing image: $imagePath');

      // Check if it's a PDF in web environment
      if (imagePath.startsWith('data:application/pdf') ||
          imagePath.toLowerCase().endsWith('.pdf')) {
        return _processWebPdf(imagePath);
      }

      final extractedText = await _extractTextWithTesseract(imagePath);

      if (extractedText.isEmpty) {
        print('No text extracted from Tesseract OCR');
        return UAEIdData();
      }

      print('Extracted text length: ${extractedText.length}');
      final extractedData = _extractDataFromText(extractedText);

      print('=== TESSERACT EXTRACTION RESULTS ===');
      print('Name: ${extractedData.name}');
      print('ID Number: ${extractedData.idNumber}');
      print('Date of Birth: ${extractedData.dateOfBirth}');
      print('Nationality: ${extractedData.nationality}');
      print('Occupation: ${extractedData.occupation}');
      print('Employer: ${extractedData.employer}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END TESSERACT EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Web Tesseract OCR error: $e');
      return UAEIdData();
    }
  }

  // Web PDF processing method
  static Future<UAEIdData> _processWebPdf(String pdfPath) async {
    try {
      print('=== WEB PDF PROCESSING START ===');
      print('Processing PDF in web: $pdfPath');

      PdfDocument? document;

      if (pdfPath.startsWith('data:application/pdf')) {
        // Handle base64 PDF data
        final parts = pdfPath.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          document = await PdfDocument.openData(bytes);
        }
      } else {
        // Handle PDF URL
        document = await PdfDocument.openFile(pdfPath);
      }

      if (document == null) {
        print('Failed to load PDF document in web');
        return UAEIdData();
      }

      String combinedText = '';

      // Process first 5 pages maximum
      for (
        int pageNum = 1;
        pageNum <= document.pagesCount && pageNum <= 5;
        pageNum++
      ) {
        try {
          final page = await document.getPage(pageNum);

          // Render page as high-quality image for web OCR
          final pageImage = await page.render(
            width: (page.width * 3).toDouble(), // Higher resolution
            height: (page.height * 3).toDouble(), // Higher resolution
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF', // White background
          );

          if (pageImage != null) {
            // Process with enhanced preprocessing for web
            final processedBytes = await _preprocessImageForOCR(
              pageImage.bytes,
            );
            final base64Image =
                'data:image/png;base64,${base64Encode(processedBytes)}';

            // Use web Tesseract for text extraction
            final pageText = await _extractTextWithTesseract(base64Image);
            combinedText += '$pageText\n';

            print(
              'Web PDF Page $pageNum text extracted (${pageText.length} chars)',
            );
          }

          await page.close();
        } catch (pageError) {
          print('Error processing web PDF page $pageNum: $pageError');
          continue;
        }
      }

      await document.close();

      if (combinedText.isEmpty) {
        print('No text extracted from web PDF');
        return UAEIdData();
      }

      print('Combined web PDF text length: ${combinedText.length}');
      final extractedData = _extractDataFromText(combinedText);

      print('=== WEB PDF EXTRACTION RESULTS ===');
      print('Name: ${extractedData.name}');
      print('ID Number: ${extractedData.idNumber}');
      print('Date of Birth: ${extractedData.dateOfBirth}');
      print('Nationality: ${extractedData.nationality}');
      print('Occupation: ${extractedData.occupation}');
      print('Employer: ${extractedData.employer}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END WEB PDF EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Web PDF processing error: $e');
      return UAEIdData();
    }
  }

  // Extract text using Tesseract for webview
  static Future<String> _extractTextWithTesseract(String imagePath) async {
    try {
      print('Calling Tesseract OCR function...');
      print('Image path: $imagePath');

      // Create a completer to handle the Promise
      final completer = Completer<String>();

      // Set up callbacks for the Promise
      js.context['dartTesseractCallback'] = js.allowInterop((String result) {
        if (!completer.isCompleted) {
          print('Tesseract OCR result received');
          print('OCR result length: ${result.length}');
          completer.complete(result);
        }
      });

      js.context['dartTesseractErrorCallback'] = js.allowInterop((
        dynamic error,
      ) {
        if (!completer.isCompleted) {
          print('Tesseract OCR error: $error');
          completer.complete('');
        }
      });

      // Call the Tesseract JavaScript function
      js.context.callMethod('eval', [
        '''
        processImageWithTesseract("$imagePath")
          .then(function(result) {
            if (window.dartTesseractCallback) {
              window.dartTesseractCallback(result || '');
            }
          })
          .catch(function(error) {
            if (window.dartTesseractErrorCallback) {
              window.dartTesseractErrorCallback(error);
            }
          });
      ''',
      ]);

      final result = await completer.future;

      // Clean up callbacks
      js.context['dartTesseractCallback'] = null;
      js.context['dartTesseractErrorCallback'] = null;

      return result;
    } catch (e) {
      print('Tesseract OCR failed: $e');
      return '';
    }
  }

  // Mobile Tesseract processing
  static Future<UAEIdData> _processTesseractMobile(String imagePath) async {
    try {
      print('=== MOBILE TESSERACT OCR START ===');
      print('Processing image: $imagePath');

      // Use Tesseract via JS bridge for mobile web view or direct API for native
      if (kIsWeb) {
        final extractedText = await _extractTextWithTesseract(imagePath);
        if (extractedText.isEmpty) {
          return UAEIdData();
        }
        return _extractDataFromText(extractedText);
      } else {
        // For native mobile, use Tesseract package if available
        // For now, fallback to simulation since Tesseract native setup is complex
        print('Native mobile Tesseract not implemented');
        return UAEIdData();
      }
    } catch (e) {
      print('Mobile Tesseract error: $e');
      return UAEIdData();
    }
  }

  // Process image from bytes using Tesseract
  static Future<String> _processTesseractFromBytes(Uint8List imageBytes) async {
    try {
      print('=== TESSERACT FROM BYTES ===');

      // Convert bytes to base64 for web processing
      final base64Image = 'data:image/png;base64,${base64Encode(imageBytes)}';
      return await _extractTextWithTesseract(base64Image);
    } catch (e) {
      print('Tesseract from bytes error: $e');
      return '';
    }
  }

  // Process image from bytes (public method)
  static Future<UAEIdData> processUAEIdFromBytes(Uint8List imageBytes) async {
    try {
      final extractedText = await _processTesseractFromBytes(imageBytes);
      if (extractedText.isEmpty) {
        return UAEIdData();
      }
      return _extractDataFromText(extractedText);
    } catch (e) {
      print('Process from bytes failed: $e');
      return UAEIdData();
    }
  }

  // Image preprocessing for better OCR results
  static Future<Uint8List> _preprocessImageForOCR(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // Use web-based image processing
        return await _preprocessImageWeb(imageBytes);
      } else {
        // For mobile, return original bytes (can add native preprocessing later)
        return imageBytes;
      }
    } catch (e) {
      print('Image preprocessing failed: $e');
      return imageBytes;
    }
  }

  // Web-based image preprocessing using Canvas
  static Future<Uint8List> _preprocessImageWeb(Uint8List imageBytes) async {
    try {
      print('=== WEB IMAGE PREPROCESSING ===');

      // Create a completer for the Promise
      final completer = Completer<Uint8List>();

      // Set up callbacks
      js.context['dartImageProcessCallback'] = js.allowInterop((
        List<int> result,
      ) {
        if (!completer.isCompleted) {
          print('Image preprocessing completed');
          completer.complete(Uint8List.fromList(result.cast<int>()));
        }
      });

      js.context['dartImageProcessErrorCallback'] = js.allowInterop((
        dynamic error,
      ) {
        if (!completer.isCompleted) {
          print('Image preprocessing error: $error');
          completer.complete(imageBytes); // Return original on error
        }
      });

      // Convert to base64 for web processing
      final base64Image = base64Encode(imageBytes);

      // Call JavaScript image processing function
      js.context.callMethod('eval', [
        '''
        preprocessImageForOCR("data:image/png;base64,$base64Image")
          .then(function(result) {
            if (window.dartImageProcessCallback) {
              window.dartImageProcessCallback(result || []);
            }
          })
          .catch(function(error) {
            if (window.dartImageProcessErrorCallback) {
              window.dartImageProcessErrorCallback(error);
            }
          });
      ''',
      ]);

      final result = await completer.future;

      // Clean up callbacks
      js.context['dartImageProcessCallback'] = null;
      js.context['dartImageProcessErrorCallback'] = null;

      return result;
    } catch (e) {
      print('Web image preprocessing failed: $e');
      return imageBytes;
    }
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

    // Enhanced name extraction with multiple patterns
    final namePatterns = [
      RegExp(r'name[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
      RegExp(r'holder[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
      RegExp(
        r'^([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)',
        multiLine: true,
      ),
      RegExp(r'([A-Z][A-Z\s]+[A-Z])'), // All caps names
    ];

    for (final pattern in namePatterns) {
      final nameMatch = pattern.firstMatch(ocrText);
      if (nameMatch != null && nameMatch.group(1) != null) {
        var extractedName = nameMatch.group(1)!.trim();
        // Clean and validate name
        extractedName = extractedName
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (extractedName.length >= 3 && name == null) {
          name = _cleanName(extractedName);
          break;
        }
      }
    }

    // Extract occupation from "Occupation: Head Of Department" pattern
    final occupationMatch = RegExp(
      r'occupation:\s*([a-z\s]+)',
      caseSensitive: false,
    ).firstMatch(ocrText);
    if (occupationMatch != null) {
      occupation = occupationMatch.group(1)?.trim();
    }

    // Extract employer from "Employer: Company Name" pattern
    final employerMatch = RegExp(
      r'employer:\s*([a-z0-9\s/&-]+)',
      caseSensitive: false,
    ).firstMatch(ocrText);
    if (employerMatch != null) {
      employer = employerMatch.group(1)?.trim();
    }

    // Enhanced ID number extraction with more flexible patterns
    final idPatterns = [
      RegExp(r'784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)'),
      RegExp(
        r'id[:\s]*784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)',
        caseSensitive: false,
      ),
      RegExp(r'(\d{3})[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)'),
      RegExp(
        r'emirates\s*id[:\s]*(\d{3})[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in idPatterns) {
      final idMatch = pattern.firstMatch(ocrText);
      if (idMatch != null && idNumber == null) {
        if (idMatch.groupCount >= 4) {
          final prefix = idMatch.group(1) == '784'
              ? '784'
              : (idMatch.group(1) ?? '784');
          idNumber =
              '$prefix-${idMatch.group(2)}-${idMatch.group(3)}-${idMatch.group(4)}';
        } else if (idMatch.groupCount >= 3) {
          idNumber =
              '784-${idMatch.group(1)}-${idMatch.group(2)}-${idMatch.group(3)}';
        }
        break;
      }
    }

    // Enhanced date extraction with context awareness
    final datePattern = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})');
    final allDates = datePattern.allMatches(ocrText);
    final foundDates = <Map<String, dynamic>>[];

    for (final match in allDates) {
      final date = match.group(0)!;
      final year = int.parse(match.group(3)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(1)!);

      // Validate date
      if (year >= 1950 &&
          year <= 2035 &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        final startIndex = match.start;
        final contextStart = startIndex > 20 ? startIndex - 20 : 0;
        final contextEnd = startIndex + 20 < ocrText.length
            ? startIndex + 20
            : ocrText.length;
        final context = ocrText
            .substring(contextStart, contextEnd)
            .toLowerCase();

        foundDates.add({'date': date, 'year': year, 'context': context});
      }
    }

    // Categorize dates by context and year ranges
    for (final dateObj in foundDates) {
      final date = dateObj['date'] as String;
      final year = dateObj['year'] as int;
      final context = dateObj['context'] as String;

      // Birth date patterns
      if ((context.contains('birth') ||
              context.contains('born') ||
              (year >= 1950 && year <= 2010)) &&
          dateOfBirth == null) {
        dateOfBirth = date;
      }
      // Expiry date patterns
      else if ((context.contains('expiry') ||
              context.contains('expires') ||
              context.contains('valid') ||
              (year >= 2020 && year <= 2035)) &&
          expiryDate == null) {
        expiryDate = date;
      }
      // Issue date patterns
      else if ((context.contains('issue') ||
              context.contains('issued') ||
              (year >= 2010 && year <= 2025)) &&
          issuingDate == null) {
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

      // Enhanced nationality extraction with comprehensive patterns
      if (nationality == null) {
        final nationalityPatterns = [
          RegExp(r'nationality[:\s]*([a-z]+)', caseSensitive: false),
          RegExp(
            r'\b(indian|pakistani|bangladeshi|filipino|egyptian|syrian|jordanian|lebanese|british|american|canadian|emirati|saudi|kuwaiti|qatari|bahraini|omani|yemeni|iranian|iraqi|afghan|nepali|sri lankan|thai|indonesian|malaysian|singaporean|chinese|korean|japanese)\b',
            caseSensitive: false,
          ),
          RegExp(r'جنسية[:\s]*([a-z\s]+)', caseSensitive: false),
        ];

        for (final pattern in nationalityPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null && match.group(1) != null) {
            nationality = _cleanNationality(match.group(1));
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

      // Enhanced occupation extraction with comprehensive patterns
      if (occupation == null) {
        final occupationPatterns = [
          RegExp(r'occupation[:\s]*([a-z\s]{3,40})', caseSensitive: false),
          RegExp(r'job[:\s]*([a-z\s]{3,40})', caseSensitive: false),
          RegExp(r'profession[:\s]*([a-z\s]{3,40})', caseSensitive: false),
          RegExp(r'work[:\s]*([a-z\s]{3,40})', caseSensitive: false),
          RegExp(r'مهنة[:\s]*([a-z\s]{3,40})', caseSensitive: false),
        ];

        for (final pattern in occupationPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null && match.group(1) != null) {
            final extractedOccupation = match.group(1)!.trim();
            if (extractedOccupation.length > 2) {
              occupation = _cleanOccupation(extractedOccupation);
              break;
            }
          }
        }
      }

      // Enhanced employer extraction with comprehensive patterns
      if (employer == null) {
        final employerPatterns = [
          RegExp(
            r'employer[:\s]*([a-z0-9\s&\-\.]{5,50})',
            caseSensitive: false,
          ),
          RegExp(r'company[:\s]*([a-z0-9\s&\-\.]{5,50})', caseSensitive: false),
          RegExp(
            r'organization[:\s]*([a-z0-9\s&\-\.]{5,50})',
            caseSensitive: false,
          ),
          RegExp(r'شركة[:\s]*([a-z0-9\s&\-\.]{5,50})', caseSensitive: false),
        ];

        for (final pattern in employerPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null && match.group(1) != null) {
            final extractedEmployer = match.group(1)!.trim();
            if (extractedEmployer.length > 4) {
              employer = _cleanEmployer(extractedEmployer);
              break;
            }
          }
        }
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

      // Extract dates by pattern matching
      final dateMatches = RegExp(
        r'(\d{1,2})/(\d{1,2})/(\d{4})',
      ).allMatches(line);
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
        mapping['middleName'] = nameParts
            .skip(1)
            .take(nameParts.length - 2)
            .join(' ');
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
