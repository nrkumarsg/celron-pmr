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
        title: const Text('Report Preview'),
      ),
      body: PdfPreview(
        build: (format) => pdfData,
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
