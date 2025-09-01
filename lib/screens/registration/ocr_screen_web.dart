// Web-specific OCR implementation (uses ocr.js bridge)
import 'dart:async';
import 'dart:html' as html; // web-only file picker
import 'dart:js_util' as js_util show promiseToFuture, callMethod;

import 'package:flutter/material.dart';
import '../../widgets/custom_back_button.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String _extractedText = '';
  String? _imageDataUrl;
  bool _isProcessing = false;
  Map<String, String> _mapping = {};

  // No development dummy data here — only real OCR results will be shown.

  Future<void> _pickImageAndRunOcr() async {
    await _showImageSourceDialog();
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ListTile(
            //   leading: const Icon(Icons.camera_alt),
            //   title: const Text('Camera'),
            //   subtitle: const Text('Take a photo'),
            //   onTap: () => Navigator.pop(context, 'camera'),
            // ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from files'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'camera') {
      await _pickFromCamera();
    } else {
      await _pickFromGallery();
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Accessing camera...'),
              ],
            ),
          ),
        );
      }

      // Use getUserMedia API for camera access
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment'}, // Use back camera if available
        'audio': false,
      });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Create video element and capture
      final video = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true;

      // Show camera preview dialog
      if (mounted) {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera'),
            content: SizedBox(
              width: 300,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: HtmlElementView(
                      viewType:
                          'video-${DateTime.now().millisecondsSinceEpoch}',
                      creationParams: video,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'capture'),
                        child: const Text('Capture'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (result == 'capture') {
          await _captureFromVideo(video);
        }

        // Stop camera stream
        stream.getTracks().forEach((track) => track.stop());
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      String errorMessage = 'Camera access failed';
      if (e.toString().contains('NotAllowedError')) {
        errorMessage =
            'Camera permission denied. Please allow camera access and try again.';
      } else if (e.toString().contains('NotFoundError')) {
        errorMessage = 'No camera found on this device.';
      } else if (e.toString().contains('NotSupportedError')) {
        errorMessage = 'Camera not supported in this browser.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _captureFromVideo(html.VideoElement video) async {
    try {
      final canvas = html.CanvasElement(
        width: video.videoWidth,
        height: video.videoHeight,
      );
      final ctx = canvas.context2D;
      ctx.drawImage(video, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);
      await _processImageFromDataUrl(dataUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return;

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final dataUrl = reader.result as String?;
    if (dataUrl == null) return;

    await _processImageFromDataUrl(dataUrl);
  }

  Future<void> _processImageFromDataUrl(String dataUrl) async {
    setState(() {
      _imageDataUrl = dataUrl;
      _extractedText = '';
      _isProcessing = true;
    });

    try {
      final jsPromise = js_util.callMethod(html.window, 'runTesseract', [
        dataUrl,
      ]);
      final result = await js_util.promiseToFuture(jsPromise);
      final text = result?.toString() ?? '';
      setState(() {
        _extractedText = text;
        _mapping = _parseAadhaarFields(_extractedText);
      });
    } catch (e) {
      setState(() {
        _extractedText = 'OCR failed: $e';
      });
    } finally {
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

    // filter out very noisy single-char or symbol-only lines but keep lines
    // that contain either letters or digits and have some length
    final candidateLines = lines.where((l) {
      final alnum = l.replaceAll(RegExp(r"[^A-Za-z0-9\s]"), '');
      if (alnum.replaceAll(RegExp(r"\s+"), '').length <= 1) return false;
      if (!RegExp(r"[A-Za-z0-9]").hasMatch(alnum)) return false;
      return true;
    }).toList();

    String government = '';
    String name = '';
    String dob = '';
    String aadhaar = '';
    String vid = '';

    for (final l in candidateLines) {
      final low = l.toLowerCase();
      if (low.contains('government') ||
          low.contains('भारत') ||
          low.contains('india') ||
          low.contains('भारतीय')) {
        government = l;
        break;
      }
    }

    // Prefer per-line grouped Aadhaar matches first (4-4-4 with optional spaces)
    for (final l in candidateLines) {
      final m = RegExp(r"(\d{4}\s?\d{4}\s?\d{4})").firstMatch(l);
      if (m != null) {
        aadhaar = m.group(1)!.replaceAll(RegExp(r"\s+"), '');
        break;
      }
    }
    // Fallback: contiguous 12-digit anywhere but prefer lines that look like numbers
    if (aadhaar.isEmpty) {
      for (final l in lines) {
        final m = RegExp(
          r"(\d{12})",
        ).firstMatch(l.replaceAll(RegExp(r"[^0-9]"), ''));
        if (m != null) {
          aadhaar = m.group(1)!;
          break;
        }
      }
    }

    // VID: prefer per-line 4x4 groups
    for (final l in candidateLines) {
      final m = RegExp(r"(\d{4}\s?\d{4}\s?\d{4}\s?\d{4})").firstMatch(l);
      if (m != null) {
        vid = m.group(1)!.replaceAll(RegExp(r"\s+"), '');
        break;
      }
    }

    // DOB detection (common formats)
    final dobRegex = RegExp(r"(\d{2}[\/\-]\d{2}[\/\-]\d{4})");
    final mDob = dobRegex.firstMatch(text);
    if (mDob != null) {
      dob = mDob.group(1)!;
    } else {
      final mDob2 = RegExp(r"(\d{4}[\/\-]\d{2}[\/\-]\d{2})").firstMatch(text);
      if (mDob2 != null) dob = mDob2.group(1)!;
    }

    // Name heuristics: line before Aadhaar or DOB, otherwise a short-alpha-only candidate
    if (aadhaar.isNotEmpty) {
      final idx = lines.indexWhere(
        (l) => l.replaceAll(RegExp(r"\s+"), '').contains(aadhaar),
      );
      if (idx > 0) {
        // Walk backwards to find a previous line that looks like a name (contains at least two letters)
        for (var j = idx - 1; j >= 0; j--) {
          final cand = lines[j];
          if (RegExp(r"[A-Za-z].*[A-Za-z]").hasMatch(cand)) {
            // compute alphabetic proportion and word quality
            final alphaOnly = cand.replaceAll(RegExp(r"[^A-Za-z]"), '');
            final alphaRatio =
                alphaOnly.length /
                (cand.replaceAll(RegExp(r"\s+"), '').length + 1);
            final words = cand
                .split(RegExp(r"\s+"))
                .where((w) => w.trim().isNotEmpty)
                .toList();
            final goodWords = words
                .where(
                  (w) => w.replaceAll(RegExp(r"[^A-Za-z]"), '').length >= 2,
                )
                .length;
            // reject lines that contain explicit gender labels
            if (cand.toLowerCase().contains('male') ||
                cand.toLowerCase().contains('female')) {
              continue;
            }

            // require at least two decent words after removing short/dirty tokens
            final wordsClean = words.where((w) {
              final wc = w.replaceAll(RegExp(r"[^A-Za-z]"), '');
              if (wc.length < 2) return false;
              if (RegExp(r"\d").hasMatch(w)) return false;
              // drop short all-uppercase tokens (likely codes)
              if (wc.length <= 3 && wc.toUpperCase() == wc) return false;
              return true;
            }).toList();
            if (alphaOnly.length >= 4 &&
                (alphaRatio > 0.45 || goodWords >= 2) &&
                wordsClean.isNotEmpty) {
              name = cand;
              break;
            }
          }
        }
      }
    }
    if (name.isEmpty && dob.isNotEmpty) {
      final idx = lines.indexWhere((l) => l.contains(dob));
      if (idx > 0) {
        for (var j = idx - 1; j >= 0; j--) {
          final cand = lines[j];
          if (RegExp(r"[A-Za-z].*[A-Za-z]").hasMatch(cand)) {
            name = cand;
            break;
          }
        }
      }
    }
    if (name.isEmpty) {
      for (final l in candidateLines) {
        if (l.length > 3 &&
            RegExp(r"[A-Za-z]").hasMatch(l) &&
            !RegExp(r"\d").hasMatch(l)) {
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

    // Cleanup noisy OCR artifacts: remove stray symbols at ends, keep letters/spaces for names
    String cleanTextName(String s) {
      final cleaned = s.replaceAll(RegExp(r"[^A-Za-z\s\.-]"), '');
      return cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();
    }

    government = cleanTextName(government);
    name = cleanTextName(name);

    // Remove single-letter prefixes/suffixes and noisy tokens
    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r"\s+"))
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (parts.length > 1 && parts.first.length == 1) parts.removeAt(0);
      if (parts.length > 1 && parts.last.length == 1) parts.removeLast();
      parts.removeWhere((p) {
        final low = p.toLowerCase();
        if (low == 'male' || low == 'female') return true;
        final onlyAlpha = p.replaceAll(RegExp(r"[^A-Za-z]"), '');
        if (onlyAlpha.length <= 2) return true;
        if (RegExp(r"\d").hasMatch(p)) return true;
        if (onlyAlpha.length <= 3 && onlyAlpha.toUpperCase() == onlyAlpha) {
          return true;
        }
        return false;
      });
      name = parts.join(' ').trim();
      // Title-case the name
      name = name
          .split(RegExp(r"\s+"))
          .map(
            (w) => w.isEmpty
                ? w
                : (w[0].toUpperCase() + w.substring(1).toLowerCase()),
          )
          .join(' ');
    }

    // Ensure numeric-only Aadhaar/VID
    aadhaar = aadhaar.replaceAll(RegExp(r"[^0-9]"), '');
    vid = vid.replaceAll(RegExp(r"[^0-9]"), '');

    // Final normalization for DOB
    dob = dob.trim();

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
      appBar: AppBar(
        title: const Text('OCR'),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomBackButton(animated: false, size: 36),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImageAndRunOcr,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo or Pick Image'),
            ),
            const SizedBox(height: 12),
            if (_imageDataUrl != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: Image.network(_imageDataUrl!)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
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
                        child: SingleChildScrollView(
                          child: _mapping.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final e in _mapping.entries)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
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
                                            Expanded(
                                              child: SelectableText(e.value),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Raw OCR output:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(_extractedText),
                                  ],
                                )
                              : SelectableText(
                                  _extractedText.isEmpty
                                      ? 'No text extracted yet. Pick an image to run OCR.'
                                      : _extractedText,
                                ),
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
                        : () {
                            html.window.navigator.clipboard?.writeText(
                              _extractedText,
                            );
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
                        _imageDataUrl = null;
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
