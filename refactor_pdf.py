import re

with open('lib/services/pdf_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace _loadLogo with _loadImage
content = content.replace("""  /// Load the CEL-RON logo from assets bundle.
  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/celronlogo.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (e) {
      // If logo load fails, return null — header will degrade gracefully.
      return null;
    }
  }""", """  static Future<pw.ImageProvider?> _loadImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }""")

# 2. Replace load calls
content = content.replace("final logoImage = await _loadLogo();", """final logoImage = await _loadImage('assets/celronlogo.jpg');
    final isoLogo = await _loadImage('assets/iso_logo.png');
    final bizsafeLogo = await _loadImage('assets/bizsafe_logo.png');
    final signatureImage = await _loadImage('assets/signature.png');""")

# 3. Update _buildHeader signature
content = content.replace("""  static pw.Widget _buildHeader(
    Company company, {
    pw.ImageProvider? logoImage,""", """  static pw.Widget _buildHeader(
    Company company, {
    pw.ImageProvider? logoImage,
    pw.ImageProvider? isoLogo,
    pw.ImageProvider? bizsafeLogo,""")

# 4. Insert ISO/Bizsafe logos in header
logo_block = """              // Logo
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
              ),"""
new_logo_block = logo_block + """
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
                ),"""
content = content.replace(logo_block, new_logo_block)

# 5. Remove footer and add parameters to functions
# Remove all _buildFooter lines
content = re.sub(r'\s*pw\.SizedBox\(height: 20\),\n\s*_buildFooter\(company\),', '', content)
content = re.sub(r'\s*_buildFooter\(company\),', '', content)

# 6. Update _buildSignatures signature and call
content = content.replace("static pw.Widget _buildSignatures(Site site)", "static pw.Widget _buildSignatures(Site site, {pw.ImageProvider? signatureImage})")
content = content.replace("_buildSignatures(site)", "_buildSignatures(site, signatureImage: signatureImage)")

# 7. Update _signatureBox call inside _buildSignatures
content = content.replace("_signatureBox('AUTHORIZED SIGNATURE', 'CEL-RON ENTERPRISES PTE LTD')", "_signatureBox('AUTHORIZED SIGNATURE', 'CEL-RON ENTERPRISES PTE LTD', signatureImage: signatureImage)")
content = content.replace("static pw.Widget _signatureBox(String role, String entity) {", "static pw.Widget _signatureBox(String role, String entity, {pw.ImageProvider? signatureImage}) {")

# 8. Update _signatureBox to show image
sig_space = """            // Signature space
            pw.Container(
              height: 60,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.bottomLeft,
              child: pw.Text('Signature:', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            ),"""
new_sig_space = """            // Signature space
            pw.Container(
              height: 60,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.bottomLeft,
              child: role == 'AUTHORIZED SIGNATURE' && signatureImage != null
                  ? pw.Image(signatureImage, height: 45, fit: pw.BoxFit.contain)
                  : pw.Text('Signature:', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            ),"""
content = content.replace(sig_space, new_sig_space)

# 9. Update headers in multi pages
content = content.replace("_buildHeader(company, logoImage: logoImage,", "_buildHeader(company, logoImage: logoImage, isoLogo: isoLogo, bizsafeLogo: bizsafeLogo,")
content = content.replace("_buildCoverPage(company, site, logoImage)", "_buildCoverPage(company, site, logoImage, isoLogo, bizsafeLogo)")

content = content.replace("""static pw.Widget _buildCoverPage(Company company, Site site, pw.ImageProvider? logoImage) {""", """static pw.Widget _buildCoverPage(Company company, Site site, pw.ImageProvider? logoImage, pw.ImageProvider? isoLogo, pw.ImageProvider? bizsafeLogo) {""")


# 10. Generate Visit Report overhaul
visit_report_old = """    pdf.addPage(
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
    return pdf.save();"""

visit_report_new = """    // Summary Page
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

    // Individual Certificates Appended
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
    return pdf.save();"""

content = content.replace(visit_report_old, visit_report_new)

with open('lib/services/pdf_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Refactored pdf_service.dart successfully.")
