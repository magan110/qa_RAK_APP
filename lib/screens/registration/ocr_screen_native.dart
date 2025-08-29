import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  String _extractedText = '';
  XFile? _pickedFile;
  bool _isProcessing = false;
  Map<String, String> _mapping = {};

  Future<void> _pickImageAndRunOcr() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _pickedFile = file;
      _extractedText = '';
      _isProcessing = true;
      _mapping = {};
    });

    final inputImage = InputImage.fromFilePath(file.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final result = await recognizer.processImage(inputImage);
      final buffer = StringBuffer();
      for (final block in result.blocks) {
        buffer.writeln(block.text);
      }
      setState(() {
        _extractedText = buffer.toString();
        _mapping = _parseAadhaarFields(_extractedText);
      });
    } catch (e) {
      setState(() {
        _extractedText = 'OCR failed: $e';
      });
    } finally {
      recognizer.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Map<String, String> _parseAadhaarFields(String text) {
    final lines = text
        .split(RegExp(r"\r?\n"))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String government = '';
    String name = '';
    String dob = '';
    String aadhaar = '';
    String vid = '';

    // government line heuristic
    for (final l in lines) {
      final low = l.toLowerCase();
      if (low.contains('government') ||
          low.contains('भारत') ||
          low.contains('india') ||
          low.contains('भारतीय')) {
        government = l;
        break;
      }
    }

    // Prefer Aadhaar near keywords
    final aadhaarContext = RegExp(
      r"(?:aadhaar|aadhar|uid)[^\d]{0,40}(\d{4}\s?\d{4}\s?\d{4})",
      caseSensitive: false,
    );
    final mA = aadhaarContext.firstMatch(text);
    if (mA != null) {
      aadhaar = mA.group(1)!.replaceAll(RegExp(r"\s+"), '');
    } else {
      // fallback: find any 12-digit sequence in all digits
      final digitsOnly = text.replaceAll(RegExp(r"[^0-9]"), '');
      for (var i = 0; i + 12 <= digitsOnly.length; i++) {
        final cand = digitsOnly.substring(i, i + 12);
        if (!RegExp(r"^0+").hasMatch(cand)) {
          aadhaar = cand;
          break;
        }
      }
    }

    // VID: try context then digit scan for 16 digits
    final vidContext = RegExp(
      r"(?:vid|virtual id)[^\d]{0,40}(\d{4}\s?\d{4}\s?\d{4}\s?\d{4})",
      caseSensitive: false,
    );
    final mV = vidContext.firstMatch(text);
    if (mV != null) {
      vid = mV.group(1)!.replaceAll(RegExp(r"\s+"), '');
    } else {
      final digitsOnly = text.replaceAll(RegExp(r"[^0-9]"), '');
      for (var i = 0; i + 16 <= digitsOnly.length; i++) {
        final cand = digitsOnly.substring(i, i + 16);
        if (!RegExp(r"^0+").hasMatch(cand)) {
          vid = cand;
          break;
        }
      }
    }

    // DOB: match common formats
    final dobRegex = RegExp(r"(\d{2}[\/\-]\d{2}[\/\-]\d{4})");
    final mDob = dobRegex.firstMatch(text);
    if (mDob != null) {
      dob = mDob.group(1)!;
    } else {
      final mDob2 = RegExp(r"(\d{4}[\/\-]\d{2}[\/\-]\d{2})").firstMatch(text);
      if (mDob2 != null) dob = mDob2.group(1)!;
    }

    // Name: prefer line above Aadhaar or DOB, else heuristic
    if (aadhaar.isNotEmpty) {
      final idx = lines.indexWhere(
        (l) => l.replaceAll(RegExp(r"\s+"), '').contains(aadhaar),
      );
      if (idx > 0) name = lines[idx - 1];
    }
    if (name.isEmpty && dob.isNotEmpty) {
      final idx = lines.indexWhere((l) => l.contains(dob));
      if (idx > 0) name = lines[idx - 1];
    }
    if (name.isEmpty) {
      for (final l in lines) {
        if (l.length > 2 &&
            RegExp(r"[A-Za-z]").hasMatch(l) &&
            !RegExp(r"\d").hasMatch(l) &&
            l.split(' ').length <= 4) {
          final low = l.toLowerCase();
          if (!low.contains('dob') &&
              !low.contains('year') &&
              !low.contains('age') &&
              !low.contains('male') &&
              !low.contains('female') &&
              !low.contains('government')) {
            name = l;
            break;
          }
        }
      }
    }

    return {
      'government': government,
      'name': name,
      'dob': dob,
      'aadhaar': aadhaar,
      'vid': vid,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImageAndRunOcr,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick Image & Run OCR'),
            ),
            const SizedBox(height: 12),
            if (_pickedFile != null) ...[
              Expanded(child: Image.file(File(_pickedFile!.path))),
              const SizedBox(height: 8),
            ],
            if (_isProcessing) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _extractedText.isEmpty
                              ? 'No text extracted yet. Pick an image to run OCR.'
                              : _extractedText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_mapping.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _mapping.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${e.key.toUpperCase()}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: SelectableText(e.value)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // return mapping to caller
                        Navigator.pop(context, _mapping);
                      },
                      child: const Text('Apply mapping (use these values)'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _extractedText.isEmpty
                        ? null
                        : () async {
                            if (!kIsWeb) {
                              await Clipboard.setData(
                                ClipboardData(text: _extractedText),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Text'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _extractedText = '';
                        _pickedFile = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
