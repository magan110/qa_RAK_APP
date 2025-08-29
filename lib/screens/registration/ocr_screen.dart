// Conditional export: pick the native implementation generally, and the web
// implementation when compiled for the browser. The platform files each export
// an `OcrScreen` widget.
export 'ocr_screen_native.dart' if (dart.library.html) 'ocr_screen_web.dart';
