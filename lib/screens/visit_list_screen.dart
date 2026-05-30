import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../models/company.dart';
import '../models/service_visit.dart';
import '../domain/repositories/inspection_repository.dart';
import '../domain/repositories/service_visit_repository.dart';
import '../injection_container.dart';
import '../models/inspection.dart';
import 'asset_list_screen.dart';
import 'visit_detail_screen.dart';

class VisitListScreen extends StatefulWidget {
  final Site site;
  final Company company;

  const VisitListScreen({super.key, required this.site, required this.company});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  final _visitRepo = sl<ServiceVisitRepository>();
  final _inspectionRepo = sl<InspectionRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.site.name} - Maintenance History'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Start New Inspection Services',
            icon: const Icon(Icons.add_task),
            onPressed: () => _showAddVisitDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSiteHeader(),
          Expanded(
            child: StreamBuilder<List<ServiceVisit>>(
              stream: _visitRepo.getVisitsStream(widget.site.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visits = snapshot.data ?? [];
                if (visits.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    return _buildVisitCard(visits[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildSiteHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF003366).withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partner: ${widget.site.partnerName}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          const SizedBox(height: 4),
          Text('Location: ${widget.site.address}', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No maintenance visits recorded yet.', 
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Start a new quarterly visit to begin inspections.'),
        ],
      ),
    );
  }

  Widget _buildVisitCard(ServiceVisit visit) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              visit.celronRef,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366)),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy, color: Colors.teal, size: 18),
                  tooltip: 'Duplicate Job',
                  onPressed: () => _duplicateVisit(visit),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                  tooltip: 'Edit Job',
                  onPressed: () => _showAddVisitDialog(visit: visit),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  tooltip: 'Delete Job',
                  onPressed: () => _showDeleteVisitDialog(visit),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(visit.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getStatusColor(visit.status)),
              ),
              child: Text(
                visit.status,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(visit.status)),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('PO Reference: ${visit.customerRef}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (visit.systemLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text('System / Location: ${visit.systemLocation}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(visit.visitDate)} • ${visit.jobType}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey[600],
                    fontWeight: visit.jobType == 'CONTRACT' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (visit.jobType == 'CONTRACT' && visit.contractEnds != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Expires: ${DateFormat('dd MMM yyyy').format(visit.contractEnds!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            if (visit.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                visit.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitDetailScreen(
                visit: visit,
                site: widget.site,
                company: widget.company,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'ARCHIVED': return Colors.grey;
      default: return Colors.orange;
    }
  }



  void _showAddVisitDialog({ServiceVisit? visit}) {
    final celronRefController = TextEditingController(text: visit?.celronRef ?? 'CRN-PM-${DateFormat('yyyyMMdd').format(DateTime.now())}');
    final customerRefController = TextEditingController(text: visit?.customerRef ?? '');
    final systemLocationController = TextEditingController(text: visit?.systemLocation ?? '');
    final notesController = TextEditingController(text: visit?.notes ?? '');
    DateTime selectedDate = visit?.visitDate ?? DateTime.now();
    String selectedJobType = visit?.jobType ?? 'AD_HOC';
    DateTime? contractEndsDate = visit?.contractEnds;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(visit == null ? 'New Maintenance Visit' : 'Edit Maintenance Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(celronRefController, 'Celron Job Reference', Icons.tag),
                _buildDialogField(customerRefController, 'Customer PO Reference', Icons.shopping_bag),
                _buildDialogField(systemLocationController, 'System / Location (e.g. Loc.L3 (PWS System))', Icons.location_on),
                ListTile(
                  leading: const Icon(Icons.date_range, color: Color(0xFF003366)),
                  title: Text('Visit Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedJobType,
                  decoration: const InputDecoration(
                    labelText: 'Job Type',
                    prefixIcon: Icon(Icons.assignment_ind_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'AD_HOC', child: Text('Ad-Hoc Job')),
                    DropdownMenuItem(value: 'CONTRACT', child: Text('Contract Job')),
                  ],
                  onChanged: (val) => setState(() => selectedJobType = val!),
                ),
                if (selectedJobType == 'CONTRACT') ...[
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    leading: const Icon(Icons.event_busy, color: Colors.redAccent),
                    title: Text(contractEndsDate == null 
                        ? 'Set Contract End Date *' 
                        : 'Contract Ends: ${DateFormat('dd MMM yyyy').format(contractEndsDate!)}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: contractEndsDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => contractEndsDate = picked);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Rich Text Notes / Summary',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
              onPressed: () async {
                if (celronRefController.text.isNotEmpty) {
                  final newVisit = ServiceVisit(
                    id: visit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    siteId: widget.site.id,
                    celronRef: celronRefController.text,
                    customerRef: customerRefController.text,
                    visitDate: selectedDate,
                    notes: notesController.text,
                    jobType: selectedJobType,
                    contractEnds: contractEndsDate,
                    createdAt: visit?.createdAt ?? DateTime.now(),
                    status: visit?.status ?? 'OPEN',
                    systemLocation: systemLocationController.text,
                  );
                  await _visitRepo.saveVisit(newVisit);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(visit == null ? 'Create Job' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteVisitDialog(ServiceVisit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Are you sure you want to delete "${visit.celronRef}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _visitRepo.deleteVisit(visit.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateVisit(ServiceVisit visit) async {
    // Show a loading indicator since this might take a moment if there are many inspections
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final newRef = '${visit.celronRef}-COPY';
      final newVisitId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final newVisit = ServiceVisit(
        id: newVisitId,
        siteId: visit.siteId,
        celronRef: newRef,
        customerRef: visit.customerRef,
        visitDate: DateTime.now(),
        notes: visit.notes,
        jobType: visit.jobType,
        contractEnds: visit.contractEnds,
        createdAt: DateTime.now(),
        status: 'OPEN',
        systemLocation: visit.systemLocation,
      );

      // 1. Save the new visit
      await _visitRepo.saveVisit(newVisit);

      // 2. Fetch all inspections from the source visit
      final oldInspections = await _inspectionRepo.getInspectionsByVisitAsync(visit.id);

      // 3. Create copies of all inspections for the new visit
      for (final oldInsp in oldInspections) {
        final newInsp = Inspection(
          id: DateTime.now().millisecondsSinceEpoch.toString() + oldInsp.assetId.substring(0, 3), // Unique ID
          assetId: oldInsp.assetId,
          date: DateTime.now(),
          projectRef: oldInsp.projectRef,
          partnerRef: oldInsp.partnerRef,
          inspectionBy: oldInsp.inspectionBy,
          quarterlyCycle: oldInsp.quarterlyCycle,
          vibrationG: oldInsp.vibrationG,
          temperatureC: oldInsp.temperatureC,
          motorParameters: Map<String, dynamic>.from(oldInsp.motorParameters),
          pumpParameters: Map<String, dynamic>.from(oldInsp.pumpParameters),
          pipeParameters: Map<String, dynamic>.from(oldInsp.pipeParameters),
          otherParameters: Map<String, dynamic>.from(oldInsp.otherParameters),
          overallStatus: oldInsp.overallStatus,
          visitId: newVisitId, // Link to the new visit
          aiConclusion: oldInsp.aiConclusion,
        );
        await _inspectionRepo.saveInspection(newInsp);
        // Small delay to ensure unique IDs if timestamp is used
        await Future.delayed(const Duration(milliseconds: 1));
      }

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job Duplicated with ${oldInspections.length} inspections!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating job: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
