import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Gedefinieerd in web/pdf_extract.js (pdf.js, lokaal gebundeld).
@JS('swipeSpendPdfToText')
external JSPromise<JSString> _pdfToText(JSUint8Array bytes);

bool get pdfImportSupported => true;

/// Haalt de tekst uit een pdf, volledig in de browser.
Future<String> extractPdfText(Uint8List bytes) async {
  if (!globalContext.has('swipeSpendPdfToText')) {
    throw StateError('Pdf-lezer is nog niet geladen, probeer zo meteen opnieuw.');
  }
  final text = await _pdfToText(bytes.toJS).toDart;
  return text.toDart;
}
