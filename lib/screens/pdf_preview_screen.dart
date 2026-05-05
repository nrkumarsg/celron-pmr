import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

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

  void _showSuccess(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document $action successfully')),
    );
  }
}
