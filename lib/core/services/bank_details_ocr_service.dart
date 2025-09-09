import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/js.dart' as js;
import 'package:pdfx/pdfx.dart';

class BankDetailsData {
  final String? accountHolderName;
  final String? accountNumber;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;
  final String? routingNumber;
  final String? swiftCode;
  final String? accountType;
  final String? currency;

  BankDetailsData({
    this.accountHolderName,
    this.accountNumber,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
    this.routingNumber,
    this.swiftCode,
    this.accountType,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ibanNumber': ibanNumber,
      'bankName': bankName,
      'branchName': branchName,
      'bankAddress': bankAddress,
      'routingNumber': routingNumber,
      'swiftCode': swiftCode,
      'accountType': accountType,
      'currency': currency,
    };
  }

  factory BankDetailsData.fromJson(Map<String, dynamic> json) {
    return BankDetailsData(
      accountHolderName: json['accountHolderName'],
      accountNumber: json['accountNumber'],
      ibanNumber: json['ibanNumber'],
      bankName: json['bankName'],
      branchName: json['branchName'],
      bankAddress: json['bankAddress'],
      routingNumber: json['routingNumber'],
      swiftCode: json['swiftCode'],
      accountType: json['accountType'],
      currency: json['currency'],
    );
  }

  bool get isValid {
    return accountHolderName != null &&
        (accountNumber != null || ibanNumber != null) &&
        bankName != null;
  }
}

class BankDetailsOCRService {
  // Main OCR processing method for bank documents
  static Future<BankDetailsData> processBankDocument(String imagePath) async {
    if (kIsWeb) {
      print('=== WEB BANK DOCUMENT OCR START ===');
      return _processWebBankDocument(imagePath);
    }

    // Check if file is a PDF
    if (imagePath.toLowerCase().endsWith('.pdf') ||
        imagePath.startsWith('data:application/pdf')) {
      print('=== BANK PDF PROCESSING DETECTED ===');
      return _processBankPdfFile(imagePath);
    }

    try {
      print('=== STARTING BANK DOCUMENT TESSERACT OCR ===');
      return _processBankTesseractMobile(imagePath);
    } catch (e) {
      print('Bank document Tesseract error: $e');
      return BankDetailsData();
    }
  }

  // PDF processing method for bank documents
  static Future<BankDetailsData> _processBankPdfFile(String pdfPath) async {
    try {
      print('=== BANK PDF PROCESSING START ===');
      print('Processing bank PDF: $pdfPath');

      PdfDocument? document;

      // Handle different PDF path types
      if (pdfPath.startsWith('data:application/pdf')) {
        final parts = pdfPath.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          document = await PdfDocument.openData(bytes);
        }
      } else if (pdfPath.startsWith('http')) {
        document = await PdfDocument.openFile(pdfPath);
      } else if (!kIsWeb) {
        document = await PdfDocument.openFile(pdfPath);
      }

      if (document == null) {
        print('Failed to load bank PDF document');
        return BankDetailsData();
      }

      String combinedText = '';

      // Process each page of the PDF (bank statements usually have multiple pages)
      for (
        int pageNum = 1;
        pageNum <= document.pagesCount && pageNum <= 3;
        pageNum++
      ) {
        try {
          final page = await document.getPage(pageNum);

          // Render page as high-quality image for better OCR
          final pageImage = await page.render(
            width: (page.width * 3).toDouble(),
            height: (page.height * 3).toDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          if (pageImage != null) {
            final processedBytes = await _preprocessBankImageForOCR(
              pageImage.bytes,
            );
            final pageText = await _processBankTesseractFromBytes(
              processedBytes,
            );
            combinedText += '$pageText\n';

            print(
              'Bank PDF Page $pageNum text extracted (${pageText.length} chars)',
            );
          }

          await page.close();
        } catch (pageError) {
          print('Error processing bank PDF page $pageNum: $pageError');
          continue;
        }
      }

      await document.close();

      if (combinedText.isEmpty) {
        print('No text extracted from bank PDF');
        return BankDetailsData();
      }

      print('Combined bank PDF text length: ${combinedText.length}');
      final extractedData = _extractBankDataFromText(combinedText);

      print('=== BANK PDF EXTRACTION RESULTS ===');
      print('Account Holder: ${extractedData.accountHolderName}');
      print('Account Number: ${extractedData.accountNumber}');
      print('IBAN: ${extractedData.ibanNumber}');
      print('Bank Name: ${extractedData.bankName}');
      print('Branch: ${extractedData.branchName}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END BANK PDF EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Bank PDF processing error: $e');
      return BankDetailsData();
    }
  }

  // Web-compatible bank document processing
  static Future<BankDetailsData> _processWebBankDocument(
    String imagePath,
  ) async {
    try {
      print('=== WEB BANK DOCUMENT OCR PROCESSING START ===');
      print('Processing bank document: $imagePath');

      // Check if it's a PDF in web environment
      if (imagePath.startsWith('data:application/pdf') ||
          imagePath.toLowerCase().endsWith('.pdf')) {
        return _processWebBankPdf(imagePath);
      }

      final extractedText = await _extractBankTextWithTesseract(imagePath);

      if (extractedText.isEmpty) {
        print('No text extracted from bank document');
        return BankDetailsData();
      }

      print('Extracted bank text length: ${extractedText.length}');
      final extractedData = _extractBankDataFromText(extractedText);

      print('=== BANK DOCUMENT EXTRACTION RESULTS ===');
      print('Account Holder: ${extractedData.accountHolderName}');
      print('Account Number: ${extractedData.accountNumber}');
      print('IBAN: ${extractedData.ibanNumber}');
      print('Bank Name: ${extractedData.bankName}');
      print('Branch: ${extractedData.branchName}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END BANK DOCUMENT EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Web bank document OCR error: $e');
      return BankDetailsData();
    }
  }

  // Web PDF processing method for bank documents
  static Future<BankDetailsData> _processWebBankPdf(String pdfPath) async {
    try {
      print('=== WEB BANK PDF PROCESSING START ===');
      print('Processing bank PDF in web: $pdfPath');

      PdfDocument? document;

      if (pdfPath.startsWith('data:application/pdf')) {
        final parts = pdfPath.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          document = await PdfDocument.openData(bytes);
        }
      } else {
        document = await PdfDocument.openFile(pdfPath);
      }

      if (document == null) {
        print('Failed to load bank PDF document in web');
        return BankDetailsData();
      }

      String combinedText = '';

      // Process first 3 pages maximum for bank documents
      for (
        int pageNum = 1;
        pageNum <= document.pagesCount && pageNum <= 3;
        pageNum++
      ) {
        try {
          final page = await document.getPage(pageNum);

          final pageImage = await page.render(
            width: (page.width * 3).toDouble(),
            height: (page.height * 3).toDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          if (pageImage != null) {
            final processedBytes = await _preprocessBankImageForOCR(
              pageImage.bytes,
            );
            final base64Image =
                'data:image/png;base64,${base64Encode(processedBytes)}';

            final pageText = await _extractBankTextWithTesseract(base64Image);
            combinedText += '$pageText\n';

            print(
              'Web Bank PDF Page $pageNum text extracted (${pageText.length} chars)',
            );
          }

          await page.close();
        } catch (pageError) {
          print('Error processing web bank PDF page $pageNum: $pageError');
          continue;
        }
      }

      await document.close();

      if (combinedText.isEmpty) {
        print('No text extracted from web bank PDF');
        return BankDetailsData();
      }

      print('Combined web bank PDF text length: ${combinedText.length}');
      final extractedData = _extractBankDataFromText(combinedText);

      print('=== WEB BANK PDF EXTRACTION RESULTS ===');
      print('Account Holder: ${extractedData.accountHolderName}');
      print('Account Number: ${extractedData.accountNumber}');
      print('IBAN: ${extractedData.ibanNumber}');
      print('Bank Name: ${extractedData.bankName}');
      print('Branch: ${extractedData.branchName}');
      print('Is Valid: ${extractedData.isValid}');
      print('=== END WEB BANK PDF EXTRACTION RESULTS ===');

      return extractedData;
    } catch (e) {
      print('Web bank PDF processing error: $e');
      return BankDetailsData();
    }
  }

  // Extract text using Tesseract for bank documents
  static Future<String> _extractBankTextWithTesseract(String imagePath) async {
    try {
      print('Calling Tesseract OCR for bank document...');
      print('Image path: $imagePath');

      final completer = Completer<String>();

      js.context['dartBankTesseractCallback'] = js.allowInterop((
        String result,
      ) {
        if (!completer.isCompleted) {
          print('Bank document Tesseract OCR result received');
          print('Bank OCR result length: ${result.length}');
          completer.complete(result);
        }
      });

      js.context['dartBankTesseractErrorCallback'] = js.allowInterop((
        dynamic error,
      ) {
        if (!completer.isCompleted) {
          print('Bank document Tesseract OCR error: $error');
          completer.complete('');
        }
      });

      // Call the specialized bank document OCR JavaScript function
      js.context.callMethod('eval', [
        '''
        processBankDocumentWithOCR("$imagePath")
          .then(function(result) {
            if (window.dartBankTesseractCallback) {
              window.dartBankTesseractCallback(result || '');
            }
          })
          .catch(function(error) {
            if (window.dartBankTesseractErrorCallback) {
              window.dartBankTesseractErrorCallback(error);
            }
          });
      ''',
      ]);

      final result = await completer.future;

      // Clean up callbacks
      js.context['dartBankTesseractCallback'] = null;
      js.context['dartBankTesseractErrorCallback'] = null;

      return result;
    } catch (e) {
      print('Bank document Tesseract OCR failed: $e');
      return '';
    }
  }

  // Mobile bank document processing
  static Future<BankDetailsData> _processBankTesseractMobile(
    String imagePath,
  ) async {
    try {
      print('=== MOBILE BANK DOCUMENT TESSERACT OCR START ===');
      print('Processing bank document: $imagePath');

      if (kIsWeb) {
        final extractedText = await _extractBankTextWithTesseract(imagePath);
        if (extractedText.isEmpty) {
          return BankDetailsData();
        }
        return _extractBankDataFromText(extractedText);
      } else {
        print('Native mobile bank document Tesseract not implemented');
        return BankDetailsData();
      }
    } catch (e) {
      print('Mobile bank document Tesseract error: $e');
      return BankDetailsData();
    }
  }

  // Process bank document from bytes using Tesseract
  static Future<String> _processBankTesseractFromBytes(
    Uint8List imageBytes,
  ) async {
    try {
      print('=== BANK DOCUMENT TESSERACT FROM BYTES ===');

      final base64Image = 'data:image/png;base64,${base64Encode(imageBytes)}';
      return await _extractBankTextWithTesseract(base64Image);
    } catch (e) {
      print('Bank document Tesseract from bytes error: $e');
      return '';
    }
  }

  // Process bank document from bytes (public method)
  static Future<BankDetailsData> processBankDetailsFromBytes(
    Uint8List imageBytes,
  ) async {
    try {
      final extractedText = await _processBankTesseractFromBytes(imageBytes);
      if (extractedText.isEmpty) {
        return BankDetailsData();
      }
      return _extractBankDataFromText(extractedText);
    } catch (e) {
      print('Process bank details from bytes failed: $e');
      return BankDetailsData();
    }
  }

  // Bank document image preprocessing for better OCR results
  static Future<Uint8List> _preprocessBankImageForOCR(
    Uint8List imageBytes,
  ) async {
    try {
      if (kIsWeb) {
        return await _preprocessBankImageWeb(imageBytes);
      } else {
        return imageBytes;
      }
    } catch (e) {
      print('Bank document image preprocessing failed: $e');
      return imageBytes;
    }
  }

  // Web-based bank document image preprocessing
  static Future<Uint8List> _preprocessBankImageWeb(Uint8List imageBytes) async {
    try {
      print('=== WEB BANK DOCUMENT IMAGE PREPROCESSING ===');

      final completer = Completer<Uint8List>();

      js.context['dartBankImageProcessCallback'] = js.allowInterop((
        List<int> result,
      ) {
        if (!completer.isCompleted) {
          print('Bank document image preprocessing completed');
          completer.complete(Uint8List.fromList(result.cast<int>()));
        }
      });

      js.context['dartBankImageProcessErrorCallback'] = js.allowInterop((
        dynamic error,
      ) {
        if (!completer.isCompleted) {
          print('Bank document image preprocessing error: $error');
          completer.complete(imageBytes);
        }
      });

      final base64Image = base64Encode(imageBytes);

      js.context.callMethod('eval', [
        '''
        preprocessBankImageForOCR("data:image/png;base64,$base64Image")
          .then(function(result) {
            if (window.dartBankImageProcessCallback) {
              window.dartBankImageProcessCallback(result || []);
            }
          })
          .catch(function(error) {
            if (window.dartBankImageProcessErrorCallback) {
              window.dartBankImageProcessErrorCallback(error);
            }
          });
      ''',
      ]);

      final result = await completer.future;

      js.context['dartBankImageProcessCallback'] = null;
      js.context['dartBankImageProcessErrorCallback'] = null;

      return result;
    } catch (e) {
      print('Web bank document image preprocessing failed: $e');
      return imageBytes;
    }
  }

  // Extract bank details from OCR text
  static BankDetailsData _extractBankDataFromText(String ocrText) {
    String? accountHolderName;
    String? accountNumber;
    String? ibanNumber;
    String? bankName;
    String? branchName;
    String? bankAddress;
    String? routingNumber;
    String? swiftCode;
    String? accountType;
    String? currency;

    final lines = ocrText.split('\n');
    print('=== RAW BANK DOCUMENT OCR TEXT ===');
    print(ocrText);
    print('=== END RAW BANK TEXT ===');
    print('Lines count: ${lines.length}');

    final fullText = ocrText.toLowerCase();

    // Extract account holder name patterns
    final accountHolderPatterns = [
      RegExp(r'account\s+holder[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
      RegExp(r'beneficiary[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
      RegExp(r'name[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
      RegExp(r'customer[:\s]*([a-zA-Z\s]{3,50})', caseSensitive: false),
    ];

    for (final pattern in accountHolderPatterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null &&
          match.group(1) != null &&
          accountHolderName == null) {
        var extractedName = match.group(1)!.trim();
        extractedName = extractedName
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (extractedName.length >= 3) {
          accountHolderName = _cleanAccountHolderName(extractedName);
          break;
        }
      }
    }

    // Extract IBAN number (UAE format: AE00 0000 0000 0000 0000 000)
    final ibanPatterns = [
      RegExp(
        r'AE\d{2}\s*\d{4}\s*\d{4}\s*\d{4}\s*\d{4}\s*\d{3}',
        caseSensitive: false,
      ),
      RegExp(
        r'IBAN[:\s]*AE\d{2}\s*\d{4}\s*\d{4}\s*\d{4}\s*\d{4}\s*\d{3}',
        caseSensitive: false,
      ),
      RegExp(r'AE\d{21}', caseSensitive: false),
    ];

    for (final pattern in ibanPatterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null && ibanNumber == null) {
        ibanNumber = match
            .group(0)!
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
        break;
      }
    }

    // Extract account number patterns
    final accountNumberPatterns = [
      RegExp(r'account\s+number[:\s]*(\d{8,20})', caseSensitive: false),
      RegExp(r'account[:\s]*(\d{8,20})', caseSensitive: false),
      RegExp(r'acc\.?\s*no\.?[:\s]*(\d{8,20})', caseSensitive: false),
      RegExp(r'(\d{10,20})'), // Generic long number pattern
    ];

    for (final pattern in accountNumberPatterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null && match.group(1) != null && accountNumber == null) {
        final extractedNumber = match.group(1)!;
        if (extractedNumber.length >= 8) {
          accountNumber = extractedNumber;
          break;
        }
      }
    }

    // Extract UAE bank names
    final uaeBanks = [
      'emirates nbd',
      'enbd',
      'emirates national bank',
      'adcb',
      'abu dhabi commercial bank',
      'fab',
      'first abu dhabi bank',
      'mashreq',
      'mashreq bank',
      'cbd',
      'commercial bank of dubai',
      'noor bank',
      'hsbc',
      'hsbc bank middle east',
      'standard chartered',
      'citibank',
      'rak bank',
      'ajman bank',
      'union national bank',
      'unb',
      'invest bank',
      'sharjah islamic bank',
      'dubai islamic bank',
      'dib',
      'abu dhabi islamic bank',
      'adib',
    ];

    for (final bank in uaeBanks) {
      if (fullText.contains(bank.toLowerCase()) && bankName == null) {
        bankName = _formatBankName(bank);
        break;
      }
    }

    // Extract branch information with enhanced patterns
    final branchPatterns = [
      // Standard branch patterns
      RegExp(r'branch[:\s]*([a-zA-Z\s\-&]{3,40})', caseSensitive: false),
      RegExp(r'branch\s+name[:\s]*([a-zA-Z\s\-&]{3,40})', caseSensitive: false),
      RegExp(r'location[:\s]*([a-zA-Z\s\-&]{3,40})', caseSensitive: false),
      // UAE specific patterns
      RegExp(
        r'dubai\s+branch[:\s]*([a-zA-Z\s\-&]{3,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'abu\s+dhabi\s+branch[:\s]*([a-zA-Z\s\-&]{3,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'sharjah\s+branch[:\s]*([a-zA-Z\s\-&]{3,40})',
        caseSensitive: false,
      ),
      // Common branch naming patterns
      RegExp(r'br\.[:\s]*([a-zA-Z\s\-&]{3,40})', caseSensitive: false),
      RegExp(
        r'branch\s*code[:\s]*\d+[,\s]*([a-zA-Z\s\-&]{3,40})',
        caseSensitive: false,
      ),
      // Geographic patterns
      RegExp(
        r'(?:at|in)\s+([a-zA-Z\s\-&]{3,40})\s+branch',
        caseSensitive: false,
      ),
    ];

    // Try each pattern to extract branch name
    for (final pattern in branchPatterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null && match.group(1) != null && branchName == null) {
        String? extractedBranch = match.group(1)!.trim();
        extractedBranch = _cleanBranchName(extractedBranch);
        if (extractedBranch != null && extractedBranch.length >= 3) {
          branchName = extractedBranch;
          break;
        }
      }
    }

    // If no branch found with patterns, try UAE location-based extraction
    if (branchName == null) {
      final uaeLocations = [
        'Dubai',
        'Abu Dhabi',
        'Sharjah',
        'Ajman',
        'Ras Al Khaimah',
        'RAK',
        'Fujairah',
        'Umm Al Quwain',
        'Al Ain',
        'ADCB',
        'ENBD',
        'FAB',
        'Downtown',
        'Marina',
        'JLT',
        'DIFC',
        'Business Bay',
        'Deira',
        'Bur Dubai',
        'Sheikh Zayed Road',
        'Mall of Emirates',
        'Dubai Mall',
        'Ibn Battuta',
        'Dragon Mart',
        'Karama',
        'Satwa',
        'Jumeirah',
        'Al Barsha',
        'Motor City',
        'International City',
        'Discovery Gardens',
        'Silicon Oasis',
        'Academic City',
        'Healthcare City',
        'Sports City',
        'Al Wasl',
        'Al Qusais',
        'Al Nahda',
        'Mirdif',
        'Festival City',
      ];

      for (final location in uaeLocations) {
        if (fullText.contains(location.toLowerCase()) && branchName == null) {
          // Extract surrounding context for better branch name
          final locationIndex = fullText.indexOf(location.toLowerCase());
          final contextStart = (locationIndex - 20).clamp(0, fullText.length);
          final contextEnd = (locationIndex + location.length + 20).clamp(
            0,
            fullText.length,
          );
          final context = ocrText.substring(contextStart, contextEnd);

          // Try to extract a more complete branch name from context
          final contextPattern = RegExp(
            r'([a-zA-Z\s\-&]*' + RegExp.escape(location) + r'[a-zA-Z\s\-&]*)',
            caseSensitive: false,
          );
          final contextMatch = contextPattern.firstMatch(context);
          if (contextMatch != null) {
            final candidateBranch = _cleanBranchName(contextMatch.group(1)!);
            if (candidateBranch != null && candidateBranch.length >= 3) {
              branchName = candidateBranch;
              break;
            }
          }

          // Fallback to just the location name
          if (branchName == null) {
            branchName = location;
          }
          break;
        }
      }
    }

    // Extract SWIFT code
    final swiftPattern = RegExp(
      r'swift[:\s]*([A-Z]{8}|[A-Z]{11})',
      caseSensitive: false,
    );
    final swiftMatch = swiftPattern.firstMatch(ocrText);
    if (swiftMatch != null && swiftMatch.group(1) != null) {
      swiftCode = swiftMatch.group(1)!.toUpperCase();
    }

    // Extract currency (UAE Dirham patterns)
    final currencyPatterns = [
      RegExp(r'\bAED\b', caseSensitive: false),
      RegExp(r'\bDHS?\b', caseSensitive: false),
      RegExp(r'dirham', caseSensitive: false),
    ];

    for (final pattern in currencyPatterns) {
      if (pattern.hasMatch(ocrText) && currency == null) {
        currency = 'AED';
        break;
      }
    }

    // Extract account type
    final accountTypePatterns = [
      RegExp(r'savings\s+account', caseSensitive: false),
      RegExp(r'current\s+account', caseSensitive: false),
      RegExp(r'checking\s+account', caseSensitive: false),
      RegExp(r'salary\s+account', caseSensitive: false),
    ];

    for (final pattern in accountTypePatterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null && accountType == null) {
        accountType = _cleanAccountType(match.group(0)!);
        break;
      }
    }

    // Line-by-line processing for additional patterns
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // Extract bank address
      if (lowerLine.contains('address') && bankAddress == null) {
        bankAddress = _extractValueAfterColon(line);
        if (bankAddress == null && i + 1 < lines.length) {
          bankAddress = lines[i + 1].trim();
        }
      }

      // Extract routing number
      if (lowerLine.contains('routing') && routingNumber == null) {
        final routingMatch = RegExp(
          r'routing[:\s]*(\d{9})',
          caseSensitive: false,
        ).firstMatch(line);
        if (routingMatch != null) {
          routingNumber = routingMatch.group(1);
        }
      }

      // Additional fallback patterns for branch name
      if (branchName == null) {
        // Look for lines that might contain branch information
        final fallbackBranchPatterns = [
          // Address-based patterns (branches often mentioned in addresses)
          RegExp(r'([A-Za-z\s\-&]{3,30})\s+branch', caseSensitive: false),
          RegExp(r'branch\s+([A-Za-z\s\-&]{3,30})', caseSensitive: false),
          // Phone/contact patterns (branch contact info)
          RegExp(
            r'phone[:\s]*\+971[^,]*,?\s*([A-Za-z\s\-&]{3,30})',
            caseSensitive: false,
          ),
          // PO Box patterns (branch postal info)
          RegExp(
            r'p\.?o\.?\s*box[:\s]*\d+[,\s]*([A-Za-z\s\-&]{3,30})',
            caseSensitive: false,
          ),
          // Service center patterns
          RegExp(
            r'service\s+center[:\s]*([A-Za-z\s\-&]{3,30})',
            caseSensitive: false,
          ),
          // Regional office patterns
          RegExp(
            r'regional\s+office[:\s]*([A-Za-z\s\-&]{3,30})',
            caseSensitive: false,
          ),
        ];

        for (final pattern in fallbackBranchPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null && match.group(1) != null) {
            final candidateBranch = _cleanBranchName(match.group(1)!);
            if (candidateBranch != null && candidateBranch.length >= 3) {
              branchName = candidateBranch;
              break;
            }
          }
        }
      }
    }

    // Final fallback: Extract branch from address or context if still not found
    if (branchName == null && bankAddress != null) {
      // Try to extract location from bank address
      final addressWords = bankAddress!.split(' ');
      for (final word in addressWords) {
        if (word.length > 2) {
          final candidateBranch = _cleanBranchName(word);
          if (candidateBranch != null && candidateBranch.length >= 3) {
            // Validate it's not just a common address word
            final commonAddressWords = [
              'street',
              'road',
              'avenue',
              'building',
              'tower',
              'floor',
              'office',
              'suite',
              'unit',
            ];
            if (!commonAddressWords.contains(candidateBranch.toLowerCase())) {
              branchName = candidateBranch;
              break;
            }
          }
        }
      }
    }

    return BankDetailsData(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ibanNumber: ibanNumber,
      bankName: bankName,
      branchName: branchName,
      bankAddress: bankAddress,
      routingNumber: routingNumber,
      swiftCode: swiftCode,
      accountType: accountType,
      currency: currency,
    );
  }

  // Helper methods for cleaning extracted bank data
  static String? _cleanAccountHolderName(String? name) {
    if (name == null || name.isEmpty) return null;

    name = name.replaceAll(RegExp(r'[^\w\s]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static String? _cleanBranchName(String? branch) {
    if (branch == null || branch.isEmpty) return null;

    // Remove common OCR artifacts and unwanted characters
    branch = branch
        .replaceAll(
          RegExp(r'[^\w\s\-&]'),
          ' ',
        ) // Keep alphanumeric, spaces, hyphens, and ampersands
        .replaceAll(
          RegExp(r'\b(branch|br|location|loc)\b', caseSensitive: false),
          '',
        ) // Remove redundant words
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();

    if (branch.length < 2) return null;

    // Filter out common OCR noise words
    final noiseWords = [
      'the',
      'at',
      'in',
      'and',
      'or',
      'of',
      'to',
      'for',
      'with',
    ];
    final words = branch.split(' ');
    final cleanWords = words
        .where(
          (word) => word.length > 1 && !noiseWords.contains(word.toLowerCase()),
        )
        .toList();

    if (cleanWords.isEmpty) return null;

    final cleanedBranch = cleanWords.join(' ');
    if (cleanedBranch.length < 2) return null;

    // Validate that it looks like a real branch name (not just numbers or single letters)
    if (RegExp(r'^[\d\s]+$').hasMatch(cleanedBranch))
      return null; // Only digits
    if (RegExp(r'^[A-Za-z]{1,2}$').hasMatch(cleanedBranch))
      return null; // Single/double letter

    return _capitalizeWords(cleanedBranch);
  }

  static String? _cleanAccountType(String? type) {
    if (type == null || type.isEmpty) return null;

    return _capitalizeWords(type.trim());
  }

  static String _formatBankName(String bank) {
    return bank
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static String? _extractValueAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length > 1) {
      return parts[1].trim();
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

  // Validation methods
  static bool validateIBANFormat(String iban) {
    final pattern = RegExp(r'^AE\d{21}$');
    return pattern.hasMatch(iban.replaceAll(' ', ''));
  }

  static bool validateAccountNumber(String accountNumber) {
    return accountNumber.length >= 8 && accountNumber.length <= 20;
  }

  // Auto-fill form fields mapping for bank details
  static Map<String, String> getBankFormFieldMapping(BankDetailsData data) {
    final mapping = <String, String>{};

    if (data.accountHolderName != null) {
      mapping['accountHolderName'] = data.accountHolderName!;
    }
    if (data.accountNumber != null) {
      mapping['accountNumber'] = data.accountNumber!;
    }
    if (data.ibanNumber != null) {
      mapping['ibanNumber'] = data.ibanNumber!;
    }
    if (data.bankName != null) {
      mapping['bankName'] = data.bankName!;
    }
    if (data.branchName != null) {
      mapping['branchName'] = data.branchName!;
    }
    if (data.bankAddress != null) {
      mapping['bankAddress'] = data.bankAddress!;
    }
    if (data.swiftCode != null) {
      mapping['swiftCode'] = data.swiftCode!;
    }
    if (data.routingNumber != null) {
      mapping['routingNumber'] = data.routingNumber!;
    }

    return mapping;
  }
}

// Extension methods for easy bank data validation
extension BankDetailsValidation on BankDetailsData {
  bool get hasValidIBAN =>
      ibanNumber != null &&
      BankDetailsOCRService.validateIBANFormat(ibanNumber!);

  bool get hasValidAccountNumber =>
      accountNumber != null &&
      BankDetailsOCRService.validateAccountNumber(accountNumber!);
}
