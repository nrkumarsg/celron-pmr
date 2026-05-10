import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:csv/csv.dart'; // Temporarily disabled due to package-level conflict
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/company.dart';
import '../models/inspection.dart';
import '../domain/repositories/asset_repository.dart';
import '../domain/repositories/inspection_repository.dart';
import 'package:get_it/get_it.dart';
import '../services/pdf_service.dart';
import 'inspection_form_screen.dart';
import 'edit_asset_screen.dart';
import 'asset_detail_screen.dart';
import '../services/ai_service.dart';

class AssetListScreen extends StatefulWidget {
  final Site site;
  final Company company;
  final String? visitId;
  final String? visitLabel;

  const AssetListScreen({
    super.key, 
    required this.site, 
    required this.company,
    this.visitId,
    this.visitLabel,
  });

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final AssetRepository _assetRepo = GetIt.instance<AssetRepository>();
  final InspectionRepository _inspectionRepo = GetIt.instance<InspectionRepository>();
  final AIService _aiService = GetIt.instance<AIService>();

  Future<void> _importAssets() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        // Robust manual CSV parsing to bypass library conflicts
        final rows = content.split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.split(RegExp(r'[,;]')))
            .map((row) => row.map((cell) => cell.trim().replaceAll('"', '')).toList())
            .toList();

        // Skip header row
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length >= 5) {
            final asset = Asset(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
              siteId: widget.site.id,
              name: row[0].toString(),
              reference: row[1].toString(),
              model: row[2].toString(),
              type: row[3].toString(),
              location: row[4].toString(),
            );
            await _assetRepo.saveAsset(asset);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assets imported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing CSV: $e')),
        );
      }
    }
  }

  Future<void> _exportAssets(List<Asset> assets) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(['Name', 'Reference', 'Model', 'Type', 'Location']);
      for (var asset in assets) {
        rows.add([asset.name, asset.reference, asset.model, asset.type, asset.location]);
      }

      // Manual CSV encoding for export stability
      String csvData = rows.map((row) => row.join(',')).join('\n');
      final bytes = utf8.encode(csvData);
      
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'assets_${widget.site.name}.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  Future<void> _printContinuous(List<Asset> assets) async {
    try {
      List<Map<String, dynamic>> assetData = [];
      for (var asset in assets) {
        final inspection = await _inspectionRepo.getLatestInspection(asset.id);
        if (inspection != null) {
          assetData.add({'asset': asset, 'inspection': inspection});
        }
      }

      if (assetData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspection reports found to print.')));
        return;
      }

      final pdfBytes = await PdfService.generateMergedInspectionPdf(
        company: widget.company,
        site: widget.site,
        assetData: assetData,
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing: $e')));
    }
  }

  Future<void> _printVisitReport(List<Asset> assets) async {
    try {
      List<Map<String, dynamic>> assetData = [];
      for (var asset in assets) {
        final inspection = await _inspectionRepo.getLatestInspection(asset.id);
        if (inspection != null) {
          assetData.add({'asset': asset, 'inspection': inspection});
        }
      }

      final pdfBytes = await PdfService.generateVisitReport(
        company: widget.company,
        site: widget.site,
        assetData: assetData,
        ourRef: 'CR/${DateFormat('yy').format(DateTime.now())}/${widget.site.name.split(' ').first}',
        jobDescription: 'Preventive Maintenance Service',
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visitLabel ?? widget.site.name),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showImportInstructions(),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: () => _importAssets(),
          ),
          StreamBuilder<List<Asset>>(
            stream: _assetRepo.getAssetsStream(widget.site.id),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export CSV',
                onPressed: snapshot.hasData ? () => _exportAssets(snapshot.data!) : null,
              );
            }
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderInfo(),
          _buildActionButtons(),
          Expanded(
            child: StreamBuilder<List<Asset>>(
              stream: _assetRepo.getAssetsStream(widget.site.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No assets found.'));
                }

                final assets = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: assets.length,
                  itemBuilder: (context, index) => _buildAssetCard(assets[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssetDialog(),
        label: const Text('Add Asset'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF003366).withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partner: ${widget.site.partnerName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 4),
          Text('Site: ${widget.site.name}'),
          const SizedBox(height: 4),
          Text('Address: ${widget.site.address}'),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final assets = await _assetRepo.getAssets(widget.site.id);
                _printContinuous(assets);
              },
              icon: const Icon(Icons.print),
              label: const Text('Continuous Print'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final assets = await _assetRepo.getAssets(widget.site.id);
                _printVisitReport(assets);
              },
              icon: const Icon(Icons.description),
              label: const Text('Visit Report'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text('System: ${asset.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Ref: ${asset.reference} | Loc: ${asset.location}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => InspectionFormScreen(
                  asset: asset, 
                  site: widget.site,
                  visitId: widget.visitId,
                )
              )
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _rowButton(Icons.edit, 'Edit', Colors.blue, () => _showEditAssetDialog(asset)),
                  _rowButton(Icons.delete, 'Delete', Colors.red, () => _confirmDelete(asset)),
                  _rowButton(Icons.content_copy, 'Duplicate', Colors.teal, () => _duplicateAsset(asset)),
                  _rowButton(Icons.visibility, 'View', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset, site: widget.site, company: widget.company)))),
                  _rowButton(Icons.print, 'Print', Colors.indigo, () => _printSingle(asset)),
                  _rowButton(Icons.auto_awesome, 'AI (V2)', Colors.deepPurple, () => _printSingleAI(asset)),
                  _rowButton(Icons.download, 'Download', Colors.green, () => _downloadSingle(asset)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
  Future<void> _duplicateAsset(Asset asset) async {
    final newAsset = Asset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      siteId: asset.siteId,
      name: '${asset.name} (Copy)',
      reference: asset.reference,
      model: asset.model,
      type: asset.type,
      location: asset.location,
      rpm: asset.rpm,
      hz: asset.hz,
      powerKw: asset.powerKw,
    );
    
    await _assetRepo.saveAsset(newAsset);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicated ${asset.name} successfully')),
      );
    }
  }

  void _showAddAssetDialog() {
    final nameController = TextEditingController();
    final refController = TextEditingController();
    final modelController = TextEditingController();
    final typeController = TextEditingController();
    final locationController = TextEditingController();
    final rpmController = TextEditingController();
    final hzController = TextEditingController();
    final kwController = TextEditingController();
    String frequency = '0.0';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateFreq() {
            final rpm = double.tryParse(rpmController.text) ?? 0.0;
            final hz = double.tryParse(hzController.text) ?? 1.0;
            setState(() {
              frequency = (hz != 0) ? (rpm / hz).toStringAsFixed(2) : '0.0';
            });
          }

          return AlertDialog(
            title: const Text('Add New Asset / System'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, 'Asset Name'),
                    _buildTextField(refController, 'Reference'),
                    _buildTextField(modelController, 'Model'),
                    _buildTextField(typeController, 'Type'),
                    _buildTextField(locationController, 'Location (e.g. L3)'),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.engineering, 'MOTOR / DRIVE PARAMETERS'),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField(rpmController, 'RPM', suffix: 'rpm', isNumeric: true, onChanged: (_) => updateFreq())),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(hzController, 'Hz', suffix: 'Hz', isNumeric: true, onChanged: (_) => updateFreq())),
                      ],
                    ),
                    
                    _buildTextField(
                      kwController, 
                      'Power (kW)', 
                      suffix: 'kW', 
                      isNumeric: true, 
                      isHighlighted: true,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildFrequencyResult(frequency),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final asset = Asset(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      siteId: widget.site.id,
                      name: nameController.text,
                      reference: refController.text,
                      model: modelController.text,
                      type: typeController.text,
                      location: locationController.text,
                      rpm: double.tryParse(rpmController.text) ?? 0.0,
                      hz: double.tryParse(hzController.text) ?? 0.0,
                      powerKw: double.tryParse(kwController.text) ?? 0.0,
                    );
                    await _assetRepo.saveAsset(asset);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAssetDialog(Asset asset) {
    final nameController = TextEditingController(text: asset.name);
    final refController = TextEditingController(text: asset.reference);
    final modelController = TextEditingController(text: asset.model);
    final typeController = TextEditingController(text: asset.type);
    final locationController = TextEditingController(text: asset.location);
    final rpmController = TextEditingController(text: asset.rpm.toString());
    final hzController = TextEditingController(text: asset.hz.toString());
    final kwController = TextEditingController(
      text: asset.powerKw > 0 ? asset.powerKw.toString() : '',
    );
    String frequency = (asset.hz != 0) ? (asset.rpm / asset.hz).toStringAsFixed(2) : '0.0';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateFreq() {
            final rpm = double.tryParse(rpmController.text) ?? 0.0;
            final hz = double.tryParse(hzController.text) ?? 1.0;
            setState(() {
              frequency = (hz != 0) ? (rpm / hz).toStringAsFixed(2) : '0.0';
            });
          }

          return AlertDialog(
            title: const Text('Edit Asset'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, 'Asset Name'),
                    _buildTextField(refController, 'Reference'),
                    _buildTextField(modelController, 'Model'),
                    _buildTextField(typeController, 'Type'),
                    _buildTextField(locationController, 'Location'),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.engineering, 'MOTOR / DRIVE PARAMETERS'),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField(rpmController, 'RPM', suffix: 'rpm', isNumeric: true, onChanged: (_) => updateFreq())),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(hzController, 'Hz', suffix: 'Hz', isNumeric: true, onChanged: (_) => updateFreq())),
                      ],
                    ),
                    
                    _buildTextField(
                      kwController, 
                      'Power (kW)', 
                      suffix: 'kW', 
                      isNumeric: true, 
                      isHighlighted: true,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildFrequencyResult(frequency),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white),
                onPressed: () async {
                  final updatedAsset = Asset(
                    id: asset.id,
                    siteId: asset.siteId,
                    name: nameController.text,
                    reference: refController.text,
                    model: modelController.text,
                    type: typeController.text,
                    location: locationController.text,
                    rpm: double.tryParse(rpmController.text) ?? 0.0,
                    hz: double.tryParse(hzController.text) ?? 0.0,
                    powerKw: double.tryParse(kwController.text) ?? 0.0,
                  );
                  await _assetRepo.saveAsset(updatedAsset);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Premium UI Helpers ---

  Widget _buildTextField(
    TextEditingController controller, 
    String label, {
    String? suffix, 
    bool isNumeric = false, 
    bool isHighlighted = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: isHighlighted,
          fillColor: isHighlighted ? const Color(0xFFE8F0FE) : Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isHighlighted ? const Color(0xFF1565C0) : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isHighlighted ? const Color(0xFF0D47A1) : const Color(0xFF003366), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF003366)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildFrequencyResult(String frequency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Frequency (RPM / Hz): $frequency',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _printSingle(Asset asset) async {
    final inspection = await _inspectionRepo.getLatestInspection(asset.id);
    if (inspection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspection data found.')));
      return;
    }
    final bytes = await PdfService.generateInspectionPdf(company: widget.company, site: widget.site, asset: asset, inspection: inspection);
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _printSingleAI(Asset asset) async {
    final inspection = await _inspectionRepo.getLatestInspection(asset.id);
    if (inspection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspection data found.')));
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating AI Diagnostic Assessment (V2)...')));
    
    final aiAnalysis = await _aiService.analyzeInspection(asset, inspection);
    
    final bytes = await PdfService.generateAIInspectionPdf(
      company: widget.company, 
      site: widget.site, 
      asset: asset, 
      inspection: inspection,
      aiAnalysis: aiAnalysis,
    );
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _downloadSingle(Asset asset) async {
    final inspection = await _inspectionRepo.getLatestInspection(asset.id);
    if (inspection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspection data found.')));
      return;
    }
    final bytes = await PdfService.generateInspectionPdf(company: widget.company, site: widget.site, asset: asset, inspection: inspection);
    await Printing.sharePdf(bytes: bytes, filename: 'Report_${asset.reference}.pdf');
  }

  void _confirmDelete(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: Text('Confirm delete ${asset.name}? This will also delete all related inspections.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            await _assetRepo.deleteAsset(asset.id);
            Navigator.pop(context);
          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showImportInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Import Instructions'),
        content: const Text(
          'Your CSV file should have the following columns in order:\n\n'
          '1. Name\n'
          '2. Reference\n'
          '3. Model\n'
          '4. Type\n'
          '5. Location\n\n'
          'The first row is skipped as a header.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }
}
