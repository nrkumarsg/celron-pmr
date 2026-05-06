import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/company.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/inspection.dart';
import '../logic/health_logic.dart';

/// PDF Brand Colors — aligned with RuggedTheme
const _primaryBlue = PdfColor.fromInt(0xFF003366);
const _safetyRed = PdfColor.fromInt(0xFFCC0000);
const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
const _charcoal = PdfColor.fromInt(0xFF333333);

class PdfService {
  /// Load the CEL-RON logo from assets bundle.
  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/celronlogo.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (e) {
      // If logo load fails, return null — header will degrade gracefully.
      return null;
    }
  }

  static Future<Uint8List> generateInspectionPdf({
    required Company company,
    required Site site,
    required Asset asset,
    required Inspection inspection,
  }) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(company, logoImage: logoImage, reportNo: 'IR-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PIPES AND OTHERS', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site),
            pw.SizedBox(height: 20),
            _buildFooter(company),
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
    final logoImage = await _loadLogo();

    for (var data in assetData) {
      final asset = data['asset'] as Asset;
      final inspection = data['inspection'] as Inspection;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(company, logoImage: logoImage, reportNo: 'IR-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PIPES AND OTHERS', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site),
            pw.SizedBox(height: 20),
            _buildFooter(company),
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
    final logoImage = await _loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(company, logoImage: logoImage, title: 'SERVICE REPORT'),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            color: _lightGrey,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: pw.Center(
              child: pw.Text(
                'SERVICE REPORT / WORK COMPLETION REPORT',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: _primaryBlue),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          _buildVisitInfoTable(site, ourRef, jobDescription),
          pw.SizedBox(height: 20),
          _buildSummaryTable(assetData),
          pw.SizedBox(height: 40),
          _buildSignatures(site),
          pw.Spacer(),
          _buildFooter(company),
        ],
      ),
    );
    return pdf.save();
  }

  // ─── Private Builders ─────────────────────────────────────────────────────

  /// Professional letterhead with actual logo image and full company address block.
  static pw.Widget _buildHeader(
    Company company, {
    pw.ImageProvider? logoImage,
    String title = 'INSPECTION REPORT',
    String? reportNo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Top Band ─────────────────────────────────────────────────────────
        pw.Container(
          color: _primaryBlue,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              pw.Container(
                width: 70,
                height: 45,
                child: logoImage != null
                    ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'CEL-RON',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
              // Company Name in centre
              pw.Expanded(
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CEL-RON ENTERPRISES PTE LTD',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        'UEN: ${company.brn}  |  GST: ${company.gstReg}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
              // Right spacer to balance logo
              pw.SizedBox(width: 70),
            ],
          ),
        ),

        // ── Address Sub-band ─────────────────────────────────────────────────
        pw.Container(
          width: double.infinity,
          color: const PdfColor.fromInt(0xFF004080),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.regOffice,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
              ),
              pw.Row(
                children: [
                  pw.Text('Tel: ${company.phone}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                  pw.SizedBox(width: 12),
                  pw.Text('Fax: ${company.fax}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                  pw.SizedBox(width: 12),
                  pw.Text('Mobile: ${company.mobile}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                  pw.SizedBox(width: 12),
                  pw.Text('Email: ${company.email}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                  pw.SizedBox(width: 12),
                  pw.Text('Web: ${company.web}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                ],
              ),
            ],
          ),
        ),

        // ── Report Title Band ──────────────────────────────────────────────────
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Ref: ${reportNo ?? 'QTN-${DateFormat('yyMM').format(DateTime.now())}-0001'}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryBlue),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _safetyRed,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryBlue),
            ),
          ],
        ),
        pw.Container(height: 1.5, color: _primaryBlue, margin: const pw.EdgeInsets.only(top: 4)),
      ],
    );
  }

  static pw.Widget _buildProjectInfo(Site site, Asset asset, Inspection inspection) {
    final statusColor = inspection.overallStatus == 'CRITICAL'
        ? _safetyRed
        : inspection.overallStatus == 'MARGINAL'
            ? const PdfColor.fromInt(0xFFE65C00)
            : const PdfColor.fromInt(0xFF1A7A1A);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('SYSTEM & SITE INFORMATION'),
        _infoRow('Partner', site.partnerName),
        _infoRow('Site Name', site.name),
        _infoRow('Site Address', site.address),
        _infoRow('Project Ref', inspection.projectRef),
        _infoRow('Partner Ref', inspection.partnerRef),
        _infoRow('Inspection By', inspection.inspectionBy),
        _infoRow('Quarterly Cycle', inspection.quarterlyCycle),
        _infoRow('System Name', asset.name),
        _infoRow('System Ref', asset.reference),
        _infoRow('Model', asset.model),
        _infoRow('Location', asset.location),
        _infoRow('RPM', asset.rpm.toStringAsFixed(0)),
        _infoRow('Hz', asset.hz.toStringAsFixed(1)),
        _infoRow('Frequency (RPM/Hz)', asset.hz != 0 ? (asset.rpm / asset.hz).toStringAsFixed(2) : 'N/A'),
        _infoRow('Power (kW)', '${asset.powerKw} kW — Class: ${HealthLogic.getClass(asset.powerKw)}'),
        _infoRow('Vibration (g)', inspection.vibrationG.toStringAsFixed(3)),
        _infoRow('Temperature (°C)', inspection.temperatureC.toStringAsFixed(1)),
        _infoRow('Inspection Date', DateFormat('dd MMM yyyy').format(inspection.date)),
        // Status row with color
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            color: _lightGrey,
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 130,
                padding: const pw.EdgeInsets.all(5),
                color: _primaryBlue,
                child: pw.Text(
                  'OVERALL STATUS',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    inspection.overallStatus,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const pw.BoxDecoration(color: _primaryBlue),
      child: pw.Text(
        title,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
      child: pw.Row(
        children: [
          pw.Container(
            width: 130,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
            color: _lightGrey,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _charcoal)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9, color: _charcoal)),
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
        _sectionHeader(title),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FixedColumnWidth(55),
            2: const pw.FlexColumnWidth(3),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FE)),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Parameter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: _primaryBlue))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: _primaryBlue))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Reading / Remark', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: _primaryBlue))),
              ],
            ),
            ...params.entries.map((e) {
              final statusVal = e.value['status'] as String? ?? '';
              final isOk = statusVal == 'OK';
              final isNotOk = statusVal == 'NOT OK';
              final statusColor = isOk
                  ? const PdfColor.fromInt(0xFF1A7A1A)
                  : isNotOk
                      ? _safetyRed
                      : _charcoal;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8, color: _charcoal))),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      statusVal,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: statusColor),
                    ),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.value['remark'] as String? ?? '', style: const pw.TextStyle(fontSize: 8, color: _charcoal))),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVisitInfoTable(Site site, String ourRef, String jobDesc) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        _tableRow('Partner', site.partnerName, 'Date', DateFormat('dd MMM yyyy').format(DateTime.now())),
        _tableRow('Site', site.name, 'Our Ref', ourRef),
        _tableRow('Address', site.address, 'Job Description', jobDesc),
      ],
    );
  }

  static pw.TableRow _tableRow(String l1, String v1, String l2, String v2) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$l1: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue)),
              pw.TextSpan(text: v1, style: const pw.TextStyle(fontSize: 9, color: _charcoal)),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$l2: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue)),
              pw.TextSpan(text: v2, style: const pw.TextStyle(fontSize: 9, color: _charcoal)),
            ],
          ),
        ),
      ),
    ]);
  }

  static pw.Widget _buildSummaryTable(List<Map<String, dynamic>> reports) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('INSPECTION SUMMARY'),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FixedColumnWidth(60),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FE)),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('System Ref', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('System Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryBlue))),
              ],
            ),
            ...List.generate(reports.length, (i) {
              final asset = reports[i]['asset'] as Asset;
              final inspection = reports[i]['inspection'] as Inspection;
              final statusColor = inspection.overallStatus == 'CRITICAL'
                  ? _safetyRed
                  : inspection.overallStatus == 'MARGINAL'
                      ? const PdfColor.fromInt(0xFFE65C00)
                      : const PdfColor.fromInt(0xFF1A7A1A);
              return pw.TableRow(
                decoration: i.isEven ? const pw.BoxDecoration(color: _lightGrey) : null,
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(asset.reference, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(asset.name, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(inspection.overallStatus, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: statusColor))),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures(Site site) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBox('AUTHORIZED SIGNATURE', 'CEL-RON ENTERPRISES PTE LTD'),
        _signatureBox('CUSTOMER ACKNOWLEDGMENT', site.partnerName.toUpperCase()),
      ],
    );
  }

  static pw.Widget _signatureBox(String role, String entity) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _primaryBlue, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            // Signature space
            pw.Container(
              height: 60,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.bottomLeft,
              child: pw.Text('Signature:', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            ),
            pw.Container(height: 1, color: PdfColors.grey300),
            // Label
            pw.Container(
              width: double.infinity,
              color: _primaryBlue,
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Column(
                children: [
                  pw.Text(role, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Text(entity, style: const pw.TextStyle(fontSize: 7, color: PdfColors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(Company company) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _primaryBlue, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CEL-RON ENTERPRISES PTE LTD  |  ${company.regOffice}',
            style: const pw.TextStyle(fontSize: 6.5, color: _primaryBlue),
          ),
          pw.Text(
            company.web,
            style: pw.TextStyle(fontSize: 6.5, color: _safetyRed, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
