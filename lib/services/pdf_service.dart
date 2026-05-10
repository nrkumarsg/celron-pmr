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
  static Future<pw.ImageProvider?> _loadImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
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
    final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, reportNo: 'IR-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PIPES AND OTHERS', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site, signatureImage: signatureImage),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateAIInspectionPdf({
    required Company company,
    required Site site,
    required Asset asset,
    required Inspection inspection,
    required String aiAnalysis,
  }) async {
    final pdf = pw.Document();
    final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, title: 'AI-ENHANCED REPORT (V2)', reportNo: 'AI-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildAIAnalysis(aiAnalysis),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site, signatureImage: signatureImage),
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
    final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');

    // 1. Add Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => _buildCoverPage(company, site, logoImage, isoLogo, bizsafeLogo),
      ),
    );

    // 2. Add Continuous Inspection Pages
    for (var data in assetData) {
      final asset = data['asset'] as Asset;
      final inspection = data['inspection'] as Inspection;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, reportNo: 'IR-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PIPES AND OTHERS', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site, signatureImage: signatureImage),
          ],
        ),
      );
    }
    return pdf.save();
  }

  static Future<Uint8List> generateMergedAIInspectionPdf({
    required Company company,
    required Site site,
    required List<Map<String, dynamic>> assetData,
  }) async {
    final pdf = pw.Document();
    final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');

    // 1. Add Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => _buildCoverPage(company, site, logoImage, isoLogo, bizsafeLogo),
      ),
    );

    // 2. Add Continuous AI Pages
    for (var data in assetData) {
      final asset = data['asset'] as Asset;
      final inspection = data['inspection'] as Inspection;
      final aiAnalysis = data['aiAnalysis'] as String? ?? 'Analysis pending...';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, title: 'AI-ENHANCED REPORT (V2)', reportNo: 'AI-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildAIAnalysis(aiAnalysis),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site, signatureImage: signatureImage),
          ],
        ),
      );
    }
    return pdf.save();
  }

  static pw.Widget _buildCoverPage(Company company, Site site, pw.ImageProvider? logoImage, pw.ImageProvider? isoLogo, pw.ImageProvider? bizsafeLogo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, title: 'INSPECTION REPORT'),
        pw.Spacer(flex: 1),
        pw.Text(
          'CONTINUOUS INSPECTION RECORD',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primaryBlue),
        ),
        pw.SizedBox(height: 40),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _primaryBlue, width: 2),
            color: _lightGrey,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Customer / Partner', site.partnerName),
              _infoRow('Service Site', site.name),
              _infoRow('Site Address', site.address),
              _infoRow('HQ Address', site.hqAddress),
              _infoRow('Report Date', DateFormat('dd MMM yyyy').format(DateTime.now())),
            ],
          ),
        ),
        pw.Spacer(flex: 2),
        pw.Text(
          'CEL-RON ENTERPRISES PTE LTD',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primaryBlue),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static Future<Uint8List> generateVisitReport({
    required Company company,
    required Site site,
    required List<Map<String, dynamic>> assetData,
    required String ourRef,
    required String jobDescription,
  }) async {
    final pdf = pw.Document();
    final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');

    // 1. Summary Page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, title: 'SERVICE REPORT'),
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
          _buildSignatures(site, signatureImage: signatureImage),
          pw.Spacer(),
        ],
      ),
    );

    // 2. Individual Certificates
    for (var data in assetData) {
      final asset = data['asset'] as Asset;
      final inspection = data['inspection'] as Inspection;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo, reportNo: 'IR-${inspection.id.substring(inspection.id.length > 4 ? inspection.id.length - 4 : 0)}'),
            pw.SizedBox(height: 20),
            _buildProjectInfo(site, asset, inspection),
            pw.SizedBox(height: 16),
            _buildParameterTable('MOTOR PARAMETERS', inspection.motorParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PUMP PARAMETERS', inspection.pumpParameters),
            pw.SizedBox(height: 10),
            _buildParameterTable('PIPES AND OTHERS', inspection.pipeParameters),
            pw.SizedBox(height: 30),
            _buildSignatures(site, signatureImage: signatureImage),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ─── Private Builders ─────────────────────────────────────────────────────

  /// Professional letterhead with actual logo image and full company address block.
  static pw.Widget _buildHeader(
    Company company, {
    pw.ImageProvider? logoImage,
    pw.ImageProvider? isoLogo,
    pw.ImageProvider? bizsafeLogo,
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
              if (isoLogo != null)
                pw.Container(
                  width: 45,
                  height: 45,
                  margin: const pw.EdgeInsets.only(left: 10),
                  child: pw.Image(isoLogo, fit: pw.BoxFit.contain),
                ),
              if (bizsafeLogo != null)
                pw.Container(
                  width: 45,
                  height: 45,
                  margin: const pw.EdgeInsets.only(left: 10),
                  child: pw.Image(bizsafeLogo, fit: pw.BoxFit.contain),
                ),
              // Company Name - Right Aligned
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
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
            ],
          ),
        ),

        // ── Address Sub-band (Right Aligned) ─────────────────────────────────────────────────
        pw.Container(
          width: double.infinity,
          color: const PdfColor.fromInt(0xFF004080),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                company.regOffice,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
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
              'Ref: ${reportNo ?? 'IR-${DateFormat('yyMM').format(DateTime.now())}-0001'}',
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

  static pw.Widget _buildAIAnalysis(String analysis) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('AI DIAGNOSTIC ASSESSMENT (VER 2.0)'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _primaryBlue, width: 0.5),
            color: const PdfColor.fromInt(0xFFF0F7FF),
          ),
          child: pw.Text(
            analysis,
            style: const pw.TextStyle(fontSize: 8.5, color: _charcoal),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProjectInfo(Site site, Asset asset, Inspection inspection) {
    String frequency = (asset.hz != 0) ? (asset.rpm / asset.hz).toStringAsFixed(2) : 'N/A';
    
    final statusColor = inspection.overallStatus == 'CRITICAL'
        ? _safetyRed
        : inspection.overallStatus == 'MARGINAL'
            ? const PdfColor.fromInt(0xFFE65C00)
            : const PdfColor.fromInt(0xFF1A7A1A);

    // Group fields into pairs for 2-column layout
    final leftFields = [
      ['Partner', site.partnerName],
      ['Site Name', site.name],
      ['Project Ref', inspection.projectRef],
      ['Partner Ref', inspection.partnerRef],
      ['Inspection By', inspection.inspectionBy],
      ['Quarterly Cycle', inspection.quarterlyCycle],
      ['System Name', asset.name],
      ['System Ref', asset.reference],
      ['Model', asset.model],
    ];

    final rightFields = [
      ['Location', asset.location],
      ['RPM', asset.rpm.toString()],
      ['Hz', asset.hz.toString()],
      ['Frequency (RPM/Hz)', frequency],
      ['Power (kW)', '${asset.powerKw} kW'],
      ['Vibration (g)', inspection.vibrationG.toString()],
      ['Temperature (°C)', inspection.temperatureC.toString()],
      ['Inspection Date', DateFormat('dd MMM yyyy').format(inspection.date)],
      ['Status', inspection.overallStatus],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('SYSTEM & SITE INFORMATION'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: leftFields.map((f) => _infoRow(f[0], f[1])).toList(),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                children: rightFields.map((f) => _infoRow(f[0], f[1], 
                  valueColor: f[0] == 'Status' ? statusColor : null
                )).toList(),
              ),
            ),
          ],
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

  static pw.Widget _infoRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _charcoal)),
          pw.Flexible(
            child: pw.Text(
              value, 
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 8.5, color: valueColor ?? _charcoal, fontWeight: valueColor != null ? pw.FontWeight.bold : pw.FontWeight.normal)
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
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((e.value['remark'] as String? ?? '').replaceAll('Ω', 'Ohm'), style: const pw.TextStyle(fontSize: 8, color: _charcoal))),
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

  static pw.Widget _buildSignatures(Site site, {pw.ImageProvider? signatureImage}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBox('AUTHORIZED SIGNATURE', 'CEL-RON ENTERPRISES PTE LTD', signatureImage: signatureImage),
        _signatureBox('CUSTOMER ACKNOWLEDGMENT', site.partnerName.toUpperCase()),
      ],
    );
  }

  static pw.Widget _signatureBox(String role, String entity, {pw.ImageProvider? signatureImage}) {
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
              child: role == 'AUTHORIZED SIGNATURE' && signatureImage != null
                  ? pw.Image(signatureImage, height: 45, fit: pw.BoxFit.contain)
                  : pw.Text('Signature:', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
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
}
