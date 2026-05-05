import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/company.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/inspection.dart';

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
        build: (pw.Context context) {
          return [
            _buildHeader(company),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 20),
            _buildParameterTable('Motor Parameters:', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('Pump Parameters:', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('Pipes and Others Parameters:', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateMergedInspectionPdf({
    required Company company,
    required Site site,
    required List<Map<String, dynamic>> assetData,
  }) async {
    final pdf = pw.Document();
    for (var data in assetData) {
      final asset = data['asset'] as Asset;
      final inspection = data['inspection'] as Inspection;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(company),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 20),
            _buildParameterTable('Motor Parameters:', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('Pump Parameters:', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('Pipes and Others Parameters:', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ],
        ),
      );
    }
    return pdf.save();
  }

  static Future<Uint8List> generateVisitReport({
    required Company company,
    required Site site,
    required List<Map<String, dynamic>> assetData,
    required String ourRef,
    required String jobDescription,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(company),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Center(
              child: pw.Text(
                'SERVICE REPORT / WORK COMPLETION REPORT',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          _buildVisitInfoTable(site, ourRef, jobDescription),
          pw.SizedBox(height: 20),
          _buildSummaryTable(assetData),
          pw.SizedBox(height: 40),
          _buildSignatures(),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildHeader(Company company) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 2)),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                pw.Text('CEL-RON', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('ENTERPRISES', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue900)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 2))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(company.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  pw.Text(company.regOffice, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                  pw.Text('Tel: ${company.phone}  Fax: ${company.fax}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('Mobile: ${company.mobile}  Email: ${company.email}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('Web: ${company.web}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('BRN: ${company.brn} | GST Reg No: ${company.gstReg}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectInfo(Site site, Asset asset, Inspection inspection) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          color: PdfColors.blue900,
          child: pw.Center(
            child: pw.Text(
              'QUARTERLY CONDITION MONITORING REPORT', 
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)
            )
          ),
        ),
        _infoRow('Customer:', 'Customer Name: ${site.customerName}'),
        _infoRow('Site:', 'Site Name: ${site.name}'),
        _infoRow('Address:', 'Address: ${site.address}'),
        _infoRow('Project Ref:', 'Project Ref: ${inspection.projectRef}'),
        _infoRow('System Ref:', asset.reference),
        _infoRow('Model:', asset.model),
        _infoRow('Loc:', 'Asset Location: ${asset.location}'),
        _infoRow('RPM:', asset.rpm.toString()),
        _infoRow('Hz:', asset.hz.toString()),
        _infoRow('Frequency:', 'RPM/Hz: ${asset.hz != 0 ? (asset.rpm / asset.hz).toStringAsFixed(2) : '0.0'}'),
        _infoRow('Inspection Date:', DateFormat('dd MMM yyyy').format(inspection.date)),
        _infoRow('Overall Status:', 'Status: ${inspection.overallStatus}', isBoldValue: true),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value, {bool isBoldValue = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(5),
            color: PdfColors.grey100,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBoldValue ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParameterTable(String title, Map<String, dynamic> params) {
    if (params.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          color: PdfColors.blue900,
          child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Parameter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Remark', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
              ],
            ),
            ...params.entries.map((e) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.value['status'] ?? '', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: e.value['status'] == 'OK' ? PdfColors.green : PdfColors.red))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.value['remark'] ?? '', style: const pw.TextStyle(fontSize: 8))),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVisitInfoTable(Site site, String ourRef, String jobDesc) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Customer: Customer Name: ${site.customerName}', style: const pw.TextStyle(fontSize: 9))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Date: Inspection Date: ${DateFormat('dd/MM/yy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9))),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Site: Site Name: ${site.name}', style: const pw.TextStyle(fontSize: 9))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Our Ref: Project Ref: $ourRef', style: const pw.TextStyle(fontSize: 9))),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Address: Address: ${site.address}', style: const pw.TextStyle(fontSize: 9))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Job: Description: $jobDesc', style: const pw.TextStyle(fontSize: 9))),
        ]),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(List<Map<String, dynamic>> reports) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sl. No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Motor Ref', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          ],
        ),
        ...List.generate(reports.length, (i) {
          final asset = reports[i]['asset'] as Asset;
          final inspection = reports[i]['inspection'] as Inspection;
          return pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((i + 1).toString(), style: const pw.TextStyle(fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${asset.reference} (${asset.name})', style: const pw.TextStyle(fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(inspection.overallStatus == 'NORMAL' ? 'Test data / Report is attached.' : 'Issues observed. See report.', style: const pw.TextStyle(fontSize: 9))),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('For CEL-RON Enterprises Pte Ltd', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)))),
            pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('THE ABOVE COMPLETED IN GOOD ORDER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)))),
            pw.Text('SIGNATURE & STAMP', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 5),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Visit us at: www.celron.net', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue700)),
            ],
          ),
        ],
      ),
    );
  }
}
