import 'dart:typed_data';

/// Pdf-import werkt (voorlopig) enkel in de web-versie (via pdf.js).
bool get pdfImportSupported => false;

Future<String> extractPdfText(Uint8List bytes) =>
    throw UnsupportedError('Pdf-import is enkel beschikbaar in de web-versie.');
