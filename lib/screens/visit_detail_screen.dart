import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../models/company.dart';
import '../models/service_visit.dart';
import '../models/asset.dart';
import '../models/inspection.dart';
import '../domain/repositories/asset_repository.dart';
import '../domain/repositories/inspection_repository.dart';
import '../injection_container.dart';
import 'asset_list_screen.dart';
import 'inspection_form_screen.dart';

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
                    final inspectedAssetIds = inspections.map((i) => i.assetId).toSet();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        final inspection = inspections.firstWhere(
                          (i) => i.assetId == asset.id,
                          orElse: () => Inspection(
                            id: '', assetId: '', date: DateTime.now(),
                            projectRef: '', partnerRef: '', inspectionBy: '',
                            quarterlyCycle: '', vibrationG: 0, temperatureC: 0,
                            motorParameters: {}, pumpParameters: {}, pipeParameters: {},
                            otherParameters: {}, overallStatus: 'PENDING'
                          ),
                        );

                        return _buildAssetStatusCard(asset, inspection, inspectedAssetIds.contains(asset.id));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        label: const Text('Manage Assets'),
        icon: const Icon(Icons.settings),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
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
              Text('Partner: ${widget.site.partnerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 4),
          Text('PO Ref: ${widget.visit.customerRef}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          if (widget.visit.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.visit.notes, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildAssetStatusCard(Asset asset, Inspection inspection, bool isInspected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Ref: ${asset.reference}'),
        trailing: _buildStatusBadge(isInspected ? inspection.overallStatus : 'PENDING'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionFormScreen(
              asset: asset,
              site: widget.site,
              visitId: widget.visit.id,
            ),
          ),
        ),
      ),
    );
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
