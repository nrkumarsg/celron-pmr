import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;

  const PdfPreviewScreen({super.key, required this.pdfData, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: $fileName'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.draw),
            tooltip: 'Sign & Annotate',
            onPressed: () => _handleSignAndAnnotate(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share via WhatsApp / Other',
            onPressed: () async {
              await Printing.sharePdf(bytes: pdfData, filename: fileName);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        onPrinted: (context) => _showSuccess(context, 'Printed'),
        onShared: (context) => _showSuccess(context, 'Shared'),
      ),
    );
  }

  Future<void> _handleSignAndAnnotate(BuildContext context) async {
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      final blob = html.Blob([pdfData], 'application/pdf');
      // ignore: undefined_prefixed_name
      final url = html.Url.createObjectUrlFromBlob(blob);
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfData);
      
      final uri = Uri.file(tempFile.path);
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF editor: $e')),
      );
    }
  }

  void _showSuccess(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document $action successfully')),
    );
  }
}
