import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/database_service.dart';
import 'asset_list_screen.dart';
import '../models/company.dart';

class DashboardScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();
  DashboardScreen({super.key});

  void _showAddSiteDialog(BuildContext context, {Site? site}) {
    final nameController = TextEditingController(text: site?.name);
    final customerController = TextEditingController(text: site?.customerName);
    final addressController = TextEditingController(text: site?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site == null ? 'Add New Customer & Site' : 'Edit Customer / Site'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: customerController,
                decoration: const InputDecoration(labelText: 'Customer Name (e.g. Veolia Water)'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Site / Plant Name (e.g. Plant 1)'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Site Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSite = Site(
                id: site?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                companyId: 'celron',
                name: nameController.text,
                customerName: customerController.text,
                address: addressController.text,
              );
              await _databaseService.saveSite(newSite);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Company?>(
      future: DatabaseService().getCompany('celron'),
      builder: (context, companySnapshot) {
        final company = companySnapshot.data ?? Company(
          id: 'celron',
          name: 'CelRon Preventive Maintenance',
          regOffice: 'Singapore',
          phone: '+65 1234 5678',
          fax: '+65 1234 5679',
          mobile: '+65 9876 5432',
          email: 'info@celron.com',
          web: 'www.celron.com',
          brn: 'BRN123456',
          gstReg: 'GST123456',
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: () => Navigator.pushNamed(context, '/knowledge'),
                tooltip: 'Vibration Knowledge Base',
              ),
              IconButton(
                icon: const Icon(Icons.add_business),
                onPressed: () => _showAddSiteDialog(context),
                tooltip: 'Add New Site/Customer',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF003366).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const Text(
                        'Select a Service Site',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Site>>(
                    stream: DatabaseService().getSites(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('No sites found. Add your first site!'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showAddSiteDialog(context),
                                child: const Text('Add Site'),
                              ),
                            ],
                          ),
                        );
                      }

                      final sites = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sites.length,
                        itemBuilder: (context, index) {
                          final site = sites[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF003366),
                                child: const Icon(Icons.location_on, color: Colors.white),
                              ),
                              title: Text(
                                'Customer: Customer Name: ${site.customerName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Site: Site Name: ${site.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Address: Address: ${site.address}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddSiteDialog(context, site: site),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AssetListScreen(site: site, company: company),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSiteDialog(context),
            label: const Text('Add New Customer / Site'),
            icon: const Icon(Icons.add_business),
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
