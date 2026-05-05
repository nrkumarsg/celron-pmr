import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/asset.dart';
import 'inspection_form_screen.dart';

class AssetListScreen extends StatelessWidget {
  final Site site;

  const AssetListScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    // Mock Assets for Micron Bendemeer
    final assets = [
      Asset(
        id: '1',
        siteId: site.id,
        name: 'Waste Water Transfer Pump -1',
        reference: 'PMP-1011-01',
        model: 'Lowara/66SV3/1AN/15KW/27.7A',
        type: 'Vertical Pump',
      ),
      Asset(
        id: '2',
        siteId: site.id,
        name: 'Waste Water Transfer Pump -2',
        reference: 'PMP-1011-02',
        model: 'Lowara/66SV3/1AN/15KW/27.7A',
        type: 'Vertical Pump',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              'Select System / Asset to Inspect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return ListTile(
                  title: Text(
                    asset.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(asset.name),
                  trailing: const Icon(Icons.add_chart, color: Colors.blue),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectionFormScreen(asset: asset),
                      ),
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
}
