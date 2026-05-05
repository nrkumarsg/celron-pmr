import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/company.dart';
import '../models/inspection.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'inspection_form_screen.dart';
import 'edit_asset_screen.dart';
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  final Site site;
  final Company company;

  const AssetListScreen({super.key, required this.site, required this.company});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _importAssets() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final rows = csv.decode(content);

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
            await _db.saveAsset(asset);
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

      String csvData = csv.encode(rows);
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
        final inspection = await _db.getLatestInspection(asset.id);
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
        final inspection = await _db.getLatestInspection(asset.id);
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
        title: Text(widget.site.name),
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
            stream: _db.getAssets(widget.site.id),
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
              stream: _db.getAssets(widget.site.id),
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
      color: const Color(0xFF003366).withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer: Customer Name: ${widget.site.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 4),
          Text('Site: Site Name: ${widget.site.name}'),
          const SizedBox(height: 4),
          Text('Address: Address: ${widget.site.address}'),
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
                final assets = await _db.getAssets(widget.site.id).first;
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
                final assets = await _db.getAssets(widget.site.id).first;
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
            title: Text('System: System Name: ${asset.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Ref: System Reference: ${asset.reference} | Loc: Asset Location: ${asset.location}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InspectionFormScreen(asset: asset, site: widget.site))),
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
                  _rowButton(Icons.visibility, 'View', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset, site: widget.site, company: widget.company)))),
                  _rowButton(Icons.print, 'Print', Colors.indigo, () => _printSingle(asset)),
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
  void _showAddAssetDialog() {
    final nameController = TextEditingController();
    final refController = TextEditingController();
    final modelController = TextEditingController();
    final typeController = TextEditingController();
    final locationController = TextEditingController();
    final rpmController = TextEditingController();
    final hzController = TextEditingController();
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Asset Name')),
                  TextField(controller: refController, decoration: const InputDecoration(labelText: 'Reference')),
                  TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model')),
                  TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type')),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location (e.g. L3)')),
                  const Divider(),
                  TextField(
                    controller: rpmController,
                    decoration: const InputDecoration(labelText: 'RPM'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateFreq(),
                  ),
                  TextField(
                    controller: hzController,
                    decoration: const InputDecoration(labelText: 'Hz'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateFreq(),
                  ),
                  const SizedBox(height: 8),
                  Text('Frequency (RPM/Hz): $frequency', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
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
                    );
                    await _db.saveAsset(asset);
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Asset Name')),
                  TextField(controller: refController, decoration: const InputDecoration(labelText: 'Reference')),
                  TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model')),
                  TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type')),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                  const Divider(),
                  TextField(
                    controller: rpmController,
                    decoration: const InputDecoration(labelText: 'RPM'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateFreq(),
                  ),
                  TextField(
                    controller: hzController,
                    decoration: const InputDecoration(labelText: 'Hz'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateFreq(),
                  ),
                  const SizedBox(height: 8),
                  Text('Frequency (RPM/Hz): $frequency', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
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
                  );
                  await _db.saveAsset(updatedAsset);
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

  Future<void> _printSingle(Asset asset) async {
    final inspection = await _db.getLatestInspection(asset.id);
    if (inspection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspection data found.')));
      return;
    }
    final bytes = await PdfService.generateInspectionPdf(company: widget.company, site: widget.site, asset: asset, inspection: inspection);
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _downloadSingle(Asset asset) async {
    final inspection = await _db.getLatestInspection(asset.id);
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
            await _db.deleteAsset(asset.id);
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
