import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/site.dart';
import '../models/company.dart';
import '../models/inspection.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class AssetDetailScreen extends StatelessWidget {
  final Asset asset;
  final Site site;
  final Company company;

  const AssetDetailScreen({
    super.key,
    required this.asset,
    required this.site,
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    final db = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('System: ${asset.name}'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Inspection>>(
        stream: db.getInspections(asset.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final inspections = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildInfoCard(),
                if (inspections.isNotEmpty) _buildTrendGraph(inspections),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Inspection History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                ),
                if (inspections.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No inspections recorded yet.'),
                  ))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inspections.length,
                    itemBuilder: (context, index) {
                      final insp = inspections[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(insp.overallStatus),
                            child: const Icon(Icons.assignment, color: Colors.white),
                          ),
                          title: Text('Date: ${DateFormat('dd MMM yyyy').format(insp.date)}'),
                          subtitle: Text('Status: ${insp.overallStatus}\nBy: ${insp.inspectionBy}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: () async {
                              final bytes = await PdfService.generateInspectionPdf(
                                company: company,
                                site: site,
                                asset: asset,
                                inspection: insp,
                              );
                              await Printing.layoutPdf(onLayout: (format) async => bytes);
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('System Name', asset.name),
          _infoRow('Reference', asset.reference),
          _infoRow('Location', asset.location),
          _infoRow('Model', asset.model),
          _infoRow('Type', asset.type),
          const Divider(),
          _infoRow('RPM', asset.rpm.toString()),
          _infoRow('Hz', asset.hz.toString()),
          _infoRow('Frequency (RPM/Hz)', (asset.hz != 0 ? (asset.rpm / asset.hz).toStringAsFixed(2) : '0.0')),
          const Divider(),
          _infoRow('Partner', site.partnerName),
          _infoRow('Site', site.name),
          _infoRow('Address', site.address),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTrendGraph(List<Inspection> inspections) {
    if (inspections.length < 2) return const SizedBox.shrink();

    // Sort by date ascending for trend
    final sorted = List<Inspection>.from(inspections)..sort((a, b) => a.date.compareTo(b.date));
    final dataPoints = sorted.map((e) => e.vibrationG).toList();
    final maxVal = dataPoints.isEmpty ? 1.0 : dataPoints.reduce((curr, next) => curr > next ? curr : next);

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vibration Trend (g Peak)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dataPoints.map((val) {
                final height = (val / (maxVal > 0 ? maxVal : 1)) * 50;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: height + 5,
                    decoration: BoxDecoration(
                      color: val > 1.5 ? Colors.red : (val > 0.8 ? Colors.orange : Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Colors.green;
      case 'MARGINAL':
        return Colors.orange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
