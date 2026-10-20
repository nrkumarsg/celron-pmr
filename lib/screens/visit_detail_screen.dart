import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../models/company.dart';
import '../models/service_visit.dart';
import '../models/asset.dart';
import '../models/inspection.dart';
import '../domain/repositories/asset_repository.dart';
import '../domain/repositories/inspection_repository.dart';
import '../domain/repositories/service_visit_repository.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../injection_container.dart';
import 'asset_list_screen.dart';
import 'inspection_form_screen.dart';
import '../services/ai_service.dart';
import '../core/location_mapper.dart';

class VisitDetailScreen extends StatefulWidget {
  final ServiceVisit visit;
  final Site site;
  final Company company;

  const VisitDetailScreen({
    super.key,
    required this.visit,
    required this.site,
    required this.company,
  });

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final _assetRepo = sl<AssetRepository>();
  final _inspectionRepo = sl<InspectionRepository>();
  final _aiService = sl<AIService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job: ${widget.visit.celronRef}'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildJobHeader(),
          Expanded(
            child: StreamBuilder<List<Asset>>(
              stream: _assetRepo.getAssetsStream(widget.site.id),
              builder: (context, assetSnapshot) {
                if (assetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assets = assetSnapshot.data ?? [];
                
                return StreamBuilder<List<Inspection>>(
                  stream: _inspectionRepo.getInspectionsByVisit(widget.visit.id),
                  builder: (context, inspectionSnapshot) {
                    final inspections = inspectionSnapshot.data ?? [];

                    int fullyCount = 0;
                    int partialCount = 0;
                    int notUpdatedCount = 0;
                    for (var a in assets) {
                      Inspection? insp;
                      for (var i in inspections) {
                        if (i.assetId == a.id) {
                          insp = i;
                          break;
                        }
                      }
                      final status = insp != null ? insp.updateStatus : 'NOT_UPDATED';
                      if (status == 'FULLY_UPDATED') {
                        fullyCount++;
                      } else if (status == 'PARTIAL_UPDATED') {
                        partialCount++;
                      } else {
                        notUpdatedCount++;
                      }
                    }

                    return Column(
                      children: [
                        _buildProgressHeader(assets.length, fullyCount, partialCount, notUpdatedCount),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: assets.length,
                            itemBuilder: (context, index) {
                              final asset = assets[index];
                              Inspection? match;
                              for (var i in inspections) {
                                if (i.assetId == asset.id) {
                                  match = i;
                                  break;
                                }
                              }
                              final inspection = match ?? Inspection(
                                id: '', assetId: '', date: DateTime.now(),
                                projectRef: '', partnerRef: '', inspectionBy: '',
                                quarterlyCycle: '', vibrationG: 0, temperatureC: 0,
                                motorParameters: {}, pumpParameters: {}, pipeParameters: {},
                                otherParameters: {'update_status': 'NOT_UPDATED'}, overallStatus: 'PENDING'
                              );

                              return _buildAssetStatusCard(asset, inspection, match != null);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildJobHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366).withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.blueGrey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partner: ${widget.site.partnerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('PO Ref: ${widget.visit.customerRef}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Manage Assets',
                    icon: const Icon(Icons.settings, color: Color(0xFF003366), size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetListScreen(
                          site: widget.site,
                          company: widget.company,
                          visitId: widget.visit.id,
                          visitLabel: widget.visit.celronRef,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Duplicate Job',
                    icon: const Icon(Icons.copy, color: Colors.teal, size: 20),
                    onPressed: () => _duplicateJob(),
                  ),
                  IconButton(
                    tooltip: 'Edit Job',
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _editJob(),
                  ),
                  IconButton(
                    tooltip: 'Delete Job',
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _deleteJob(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.visit.jobType == 'CONTRACT' ? Colors.blue[800] : Colors.orange[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(widget.visit.jobType, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateContinuousPdf(),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Continuous Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateVisitReport(),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Visit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateContinuousAIReport(),
                  icon: const Icon(Icons.psychology),
                  label: const Text('AI Continuous (V2)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateAIVisitSummary(),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI Summary (V2)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _showSystemLocationSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: Color(0xFF003366), size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Select System / Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select the system and location scope for this report. The PDF will filter assets and label the cover sheet accordingly.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: const Text('PWS System (Loc. L3)'),
                  subtitle: const Text('RO High Pressure, Circulation, Ozone, Purified Water Pumps'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => Navigator.pop(context, 'Loc.L3 (PWS System)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                  title: const Text('WWTP (Outdoor) System (Loc. L1)'),
                  subtitle: const Text('EQ, Wash Water, Drain Pumps'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => Navigator.pop(context, 'Loc.L1 (WWTP(Outdoor) System)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, color: Colors.teal),
                  title: const Text('All Systems & Locations'),
                  subtitle: const Text('Generate combined report for all assets'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => Navigator.pop(context, 'ALL'),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _generateContinuousAIReport() async {
    final selectedLoc = await _showSystemLocationSelectionDialog();
    if (selectedLoc == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating AI-Enhanced Continuous Reports (V2)...')),
    );

    try {
      final assets = await _assetRepo.getAssets(widget.site.id);

      // Filter assets based on selection
      List<Asset> filteredAssets = assets;
      if (selectedLoc != 'ALL') {
        filteredAssets = assets.where((asset) {
          final loc = LocationMapper.getMappedLocation(asset.reference, asset.location);
          return loc == selectedLoc;
        }).toList();
      }

      if (filteredAssets.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No assets found for the selected system/location.')));
        return;
      }

      final inspections = await _inspectionRepo.getAllInspectionsForSite(widget.site.id);
      final visitInspections = inspections.where((i) => i.visitId == widget.visit.id).toList();

      final List<Map<String, dynamic>> assetData = [];
      for (var asset in filteredAssets) {
        final insp = visitInspections.firstWhere(
          (i) => i.assetId == asset.id,
          orElse: () => Inspection(
            id: 'PENDING', assetId: asset.id, date: DateTime.now(),
            projectRef: '', partnerRef: '', inspectionBy: '',
            quarterlyCycle: '', vibrationG: 0, temperatureC: 0,
            motorParameters: {}, pumpParameters: {}, pipeParameters: {},
            otherParameters: {}, overallStatus: 'PENDING'
          ),
        );
        if (insp.id != 'PENDING') {
          // Generate AI analysis for each asset
          final analysis = await _aiService.analyzeInspection(asset, insp);
          assetData.add({'asset': asset, 'inspection': insp, 'aiAnalysis': analysis});
        }
      }

      if (assetData.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspections completed for the selected system/location.')));
        return;
      }

      // Group assets: PWS System (Loc. L3) first, then WWTP (Loc. L1) next, sorted by System Ref (motor no.) alphabetically
      final pwsAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L3 (PWS System)').toList();
      final wwtpAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L1 (WWTP(Outdoor) System)').toList();
      final otherAssets = assetData.where((data) {
        final loc = LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location);
        return loc != 'Loc.L3 (PWS System)' && loc != 'Loc.L1 (WWTP(Outdoor) System)';
      }).toList();

      pwsAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      wwtpAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      otherAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));

      assetData.clear();
      assetData.addAll(pwsAssets);
      assetData.addAll(wwtpAssets);
      assetData.addAll(otherAssets);

      final pdfBytes = await PdfService.generateMergedAIInspectionPdf(
        company: widget.company,
        site: widget.site,
        assetData: assetData,
        systemLocation: selectedLoc == 'ALL' ? (widget.visit.systemLocation.isNotEmpty ? widget.visit.systemLocation : null) : selectedLoc,
        ourRef: widget.visit.celronRef,
        jobDescription: widget.visit.notes.isEmpty ? 'Quarterly Maintenance Inspection' : widget.visit.notes,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'AI_Continuous_Report_${widget.visit.celronRef}.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating AI PDF: $e')));
    }
  }

  void _generateAIVisitSummary() async {
     // For version 2 summary, we can do a high-level site-wide AI analysis
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Visit Summary (V2) feature coming soon. Using individual asset AI reports for now.')),
    );
    _generateContinuousAIReport();
  }

  void _generateContinuousPdf() async {
    final selectedLoc = await _showSystemLocationSelectionDialog();
    if (selectedLoc == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing Merged Inspection Reports...')),
    );

    try {
      final assets = await _assetRepo.getAssets(widget.site.id);
      
      // Filter assets based on selection
      List<Asset> filteredAssets = assets;
      if (selectedLoc != 'ALL') {
        filteredAssets = assets.where((asset) {
          final loc = LocationMapper.getMappedLocation(asset.reference, asset.location);
          return loc == selectedLoc;
        }).toList();
      }

      if (filteredAssets.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No assets found for the selected system/location.')));
        return;
      }

      final inspections = await _inspectionRepo.getAllInspectionsForSite(widget.site.id);
      final visitInspections = inspections.where((i) => i.visitId == widget.visit.id).toList();

      final List<Map<String, dynamic>> assetData = [];
      for (var asset in filteredAssets) {
        final insp = visitInspections.firstWhere(
          (i) => i.assetId == asset.id,
          orElse: () => Inspection(
            id: 'PENDING', assetId: asset.id, date: DateTime.now(),
            projectRef: '', partnerRef: '', inspectionBy: '',
            quarterlyCycle: '', vibrationG: 0, temperatureC: 0,
            motorParameters: {}, pumpParameters: {}, pipeParameters: {},
            otherParameters: {}, overallStatus: 'PENDING'
          ),
        );
        if (insp.id != 'PENDING') {
          assetData.add({'asset': asset, 'inspection': insp});
        }
      }

      if (assetData.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No inspections completed for the selected system/location.')));
        return;
      }

      // Group assets: PWS System (Loc. L3) first, then WWTP (Loc. L1) next, sorted by System Ref (motor no.) alphabetically
      final pwsAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L3 (PWS System)').toList();
      final wwtpAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L1 (WWTP(Outdoor) System)').toList();
      final otherAssets = assetData.where((data) {
        final loc = LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location);
        return loc != 'Loc.L3 (PWS System)' && loc != 'Loc.L1 (WWTP(Outdoor) System)';
      }).toList();

      pwsAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      wwtpAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      otherAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));

      assetData.clear();
      assetData.addAll(pwsAssets);
      assetData.addAll(wwtpAssets);
      assetData.addAll(otherAssets);

      final pdfBytes = await PdfService.generateMergedInspectionPdf(
        company: widget.company,
        site: widget.site,
        assetData: assetData,
        systemLocation: selectedLoc == 'ALL' ? (widget.visit.systemLocation.isNotEmpty ? widget.visit.systemLocation : null) : selectedLoc,
        ourRef: widget.visit.celronRef,
        jobDescription: widget.visit.notes.isEmpty ? 'Quarterly Maintenance Inspection' : widget.visit.notes,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'Continuous_Report_${widget.visit.celronRef}.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  void _generateVisitReport() async {
    final selectedLoc = await _showSystemLocationSelectionDialog();
    if (selectedLoc == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing Visit Summary Report...')),
    );

    try {
      final assets = await _assetRepo.getAssets(widget.site.id);
      
      // Filter assets based on selection
      List<Asset> filteredAssets = assets;
      if (selectedLoc != 'ALL') {
        filteredAssets = assets.where((asset) {
          final loc = LocationMapper.getMappedLocation(asset.reference, asset.location);
          return loc == selectedLoc;
        }).toList();
      }

      if (filteredAssets.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No assets found for the selected system/location.')));
        return;
      }

      final inspections = await _inspectionRepo.getAllInspectionsForSite(widget.site.id);
      final visitInspections = inspections.where((i) => i.visitId == widget.visit.id).toList();

      final List<Map<String, dynamic>> assetData = [];
      for (var asset in filteredAssets) {
        final insp = visitInspections.firstWhere(
          (i) => i.assetId == asset.id,
          orElse: () => Inspection(
            id: 'PENDING', assetId: asset.id, date: DateTime.now(),
            projectRef: '', partnerRef: '', inspectionBy: '',
            quarterlyCycle: '', vibrationG: 0, temperatureC: 0,
            motorParameters: {}, pumpParameters: {}, pipeParameters: {},
            otherParameters: {}, overallStatus: 'PENDING'
          ),
        );
        assetData.add({'asset': asset, 'inspection': insp});
      }

      // Group assets: PWS System (Loc. L3) first, then WWTP (Loc. L1) next, sorted by System Ref (motor no.) alphabetically
      final pwsAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L3 (PWS System)').toList();
      final wwtpAssets = assetData.where((data) => LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location) == 'Loc.L1 (WWTP(Outdoor) System)').toList();
      final otherAssets = assetData.where((data) {
        final loc = LocationMapper.getMappedLocation(data['asset'].reference, data['asset'].location);
        return loc != 'Loc.L3 (PWS System)' && loc != 'Loc.L1 (WWTP(Outdoor) System)';
      }).toList();

      pwsAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      wwtpAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));
      otherAssets.sort((a, b) => (a['asset'].reference as String).compareTo(b['asset'].reference as String));

      assetData.clear();
      assetData.addAll(pwsAssets);
      assetData.addAll(wwtpAssets);
      assetData.addAll(otherAssets);

      final pdfBytes = await PdfService.generateVisitReport(
        company: widget.company,
        site: widget.site,
        assetData: assetData,
        ourRef: widget.visit.celronRef,
        jobDescription: widget.visit.notes.isEmpty ? 'Quarterly Maintenance Inspection' : widget.visit.notes,
        systemLocation: selectedLoc == 'ALL' ? (widget.visit.systemLocation.isNotEmpty ? widget.visit.systemLocation : null) : selectedLoc,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'Visit_Report_${widget.visit.celronRef}.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating Visit Report: $e')));
    }
  }

  void _editJob() {
    // This will be handled by navigating back or showing a dialog
    // For now, we'll implement a local edit dialog similar to VisitListScreen
  }

  void _deleteJob() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Delete "${widget.visit.celronRef}"? This will remove all linked data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await sl<ServiceVisitRepository>().deleteVisit(widget.visit.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateJob() async {
    final newRef = '${widget.visit.celronRef}-COPY';
    final newVisit = ServiceVisit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      siteId: widget.visit.siteId,
      celronRef: newRef,
      customerRef: widget.visit.customerRef,
      visitDate: DateTime.now(),
      notes: widget.visit.notes,
      jobType: widget.visit.jobType,
      contractEnds: widget.visit.contractEnds,
      createdAt: DateTime.now(),
      status: 'OPEN',
      systemLocation: widget.visit.systemLocation,
    );

    await sl<ServiceVisitRepository>().saveVisit(newVisit);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job Duplicated: $newRef')),
      );
      Navigator.pop(context); // Go back to list to see the new job
    }
  }


  Widget _buildProgressHeader(int total, int fully, int partial, int notUpdated) {
    if (total == 0) return const SizedBox.shrink();

    final pct = total > 0 ? (fully / total) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job Progress: $fully / $total Complete',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003366)),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMiniCounter('Not Updated', notUpdated, const Color(0xFF64748B), const Color(0xFFF1F5F9)),
                const SizedBox(width: 8),
                _buildMiniCounter('Partial', partial, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                const SizedBox(width: 8),
                _buildMiniCounter('Fully Updated', fully, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetStatusCard(Asset asset, Inspection inspection, bool isInspected) {
    final updateStatus = isInspected ? inspection.updateStatus : 'NOT_UPDATED';

    Color cardBorderColor;
    if (updateStatus == 'FULLY_UPDATED') {
      cardBorderColor = const Color(0xFF86EFAC);
    } else if (updateStatus == 'PARTIAL_UPDATED') {
      cardBorderColor = const Color(0xFFFDE68A);
    } else {
      cardBorderColor = const Color(0xFFE2E8F0);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: updateStatus != 'NOT_UPDATED' ? 1.5 : 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionFormScreen(
              asset: asset,
              site: widget.site,
              visitId: widget.visit.id,
              existingInspection: isInspected ? inspection : null,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${asset.reference}${asset.location.isNotEmpty ? '  •  Loc: ${asset.location}' : ''}',
                          style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isInspected && inspection.overallStatus != 'PENDING') ...[
                    _buildStatusBadge(inspection.overallStatus),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.chevron_right, color: Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildStatusChip(
                          label: 'Not Updated',
                          icon: Icons.radio_button_unchecked,
                          isSelected: updateStatus == 'NOT_UPDATED',
                          activeColor: const Color(0xFF475569),
                          activeBg: const Color(0xFFF1F5F9),
                          onTap: () => _setAssetUpdateStatus(asset, inspection, isInspected, 'NOT_UPDATED'),
                        ),
                        _buildStatusChip(
                          label: 'Partial Updated',
                          icon: Icons.timelapse,
                          isSelected: updateStatus == 'PARTIAL_UPDATED',
                          activeColor: const Color(0xFFD97706),
                          activeBg: const Color(0xFFFEF3C7),
                          onTap: () => _setAssetUpdateStatus(asset, inspection, isInspected, 'PARTIAL_UPDATED'),
                        ),
                        _buildStatusChip(
                          label: 'Fully Updated',
                          icon: Icons.check_circle,
                          isSelected: updateStatus == 'FULLY_UPDATED',
                          activeColor: const Color(0xFF16A34A),
                          activeBg: const Color(0xFFDCFCE7),
                          onTap: () => _setAssetUpdateStatus(asset, inspection, isInspected, 'FULLY_UPDATED'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.35),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (icon == Icons.radio_button_unchecked ? Icons.radio_button_checked : icon) : Icons.circle_outlined,
              size: 14,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAssetUpdateStatus(Asset asset, Inspection inspection, bool isInspected, String newStatus) async {
    try {
      final otherParams = isInspected
          ? Map<String, dynamic>.from(inspection.otherParameters)
          : <String, dynamic>{};
      otherParams['update_status'] = newStatus;

      final now = DateTime.now();
      final updatedInspection = isInspected && inspection.id.isNotEmpty
          ? Inspection(
              id: inspection.id,
              assetId: asset.id,
              date: inspection.date,
              projectRef: inspection.projectRef.isNotEmpty ? inspection.projectRef : widget.visit.celronRef,
              partnerRef: inspection.partnerRef.isNotEmpty ? inspection.partnerRef : widget.visit.customerRef,
              inspectionBy: inspection.inspectionBy.isNotEmpty ? inspection.inspectionBy : 'N.R.Kumar',
              quarterlyCycle: inspection.quarterlyCycle.isNotEmpty ? inspection.quarterlyCycle : 'Q1-2026',
              vibrationG: inspection.vibrationG,
              temperatureC: inspection.temperatureC,
              vibrationImgUrl: inspection.vibrationImgUrl,
              tempImgUrl: inspection.tempImgUrl,
              motorParameters: inspection.motorParameters,
              pumpParameters: inspection.pumpParameters,
              pipeParameters: inspection.pipeParameters,
              otherParameters: otherParams,
              overallStatus: newStatus == 'NOT_UPDATED' && inspection.overallStatus == 'PENDING'
                  ? 'PENDING'
                  : (inspection.overallStatus == 'PENDING' ? 'NORMAL' : inspection.overallStatus),
              visitId: widget.visit.id,
              aiConclusion: inspection.aiConclusion,
            )
          : Inspection(
              id: '${widget.visit.id}_${asset.id}_${now.millisecondsSinceEpoch}',
              assetId: asset.id,
              date: now,
              projectRef: widget.visit.celronRef,
              partnerRef: widget.visit.customerRef,
              inspectionBy: 'N.R.Kumar',
              quarterlyCycle: 'Q1-2026',
              vibrationG: 0.0,
              temperatureC: 0.0,
              vibrationImgUrl: null,
              tempImgUrl: null,
              motorParameters: {},
              pumpParameters: {},
              pipeParameters: {},
              otherParameters: otherParams,
              overallStatus: newStatus == 'NOT_UPDATED' ? 'PENDING' : 'NORMAL',
              visitId: widget.visit.id,
              aiConclusion: null,
            );

      await _inspectionRepo.saveInspection(updatedInspection);

      if (mounted) {
        final label = newStatus == 'NOT_UPDATED'
            ? 'Not Updated'
            : (newStatus == 'PARTIAL_UPDATED' ? 'Partial Updated' : 'Fully Updated');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${asset.name}: $label'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'NORMAL': color = Colors.green; break;
      case 'WARNING': color = Colors.orange; break;
      case 'CRITICAL': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
