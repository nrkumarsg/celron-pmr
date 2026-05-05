import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../models/asset.dart';
import '../models/site.dart';
import '../models/company.dart';

class PdfService {
  static Future<Uint8List> generateInspectionPdf({
    required Company company,
    required Site site,
    required Asset asset,
    required Inspection inspection,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(company),
          pw.SizedBox(height: 10),
          _buildTitle(),
          pw.SizedBox(height: 10),
          _buildInfoTable(site, asset, inspection),
          pw.SizedBox(height: 20),
          _buildParameterTable('Motor Parameters', inspection.motorParameters),
          pw.SizedBox(height: 10),
          _buildParameterTable('Pump Parameters', inspection.pumpParameters),
          pw.SizedBox(height: 10),
          _buildParameterTable('Other Parameters', inspection.otherParameters),
          pw.SizedBox(height: 20),
          _buildFooter(company),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Company company) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          width: 100,
          height: 50,
          child: pw.Center(child: pw.Text('CEL-RON LOGO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(company.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red900)),
            pw.Text('Reg Office: ${company.regOffice}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Tel: ${company.phone} Web: ${company.web}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('BRN: ${company.brn} GST: ${company.gstReg}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Center(
        child: pw.Text(
          'QUARTERLY INSPECTION REPORT',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  static pw.Widget _buildInfoTable(Site site, Asset asset, Inspection inspection) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        _buildTableRow('PROJECT/ CUSTOMER', site.name),
        _buildTableRow('INSPECTION DATE / CYCLE', '${DateFormat('dd/MM/yyyy').format(inspection.date)} - ${inspection.cycle}'),
        _buildTableRow('Pump Model', asset.model),
        _buildTableRow('S/N / System', asset.reference),
        _buildTableRow('Pump Type', asset.type),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  static pw.Widget _buildParameterTable(String title, Map<String, String> params) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(2),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Reading / Remark', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
              ],
            ),
            ...params.entries.map((e) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('OK', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 8))),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(Company company) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ISO 9001:2015 CERTIFIED COMPANY', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
