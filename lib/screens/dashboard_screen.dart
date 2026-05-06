import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/site.dart';
import '../domain/repositories/site_repository.dart';
import 'asset_list_screen.dart';
import '../core/celron_company.dart';

class DashboardScreen extends StatelessWidget {
  final SiteRepository _siteRepository = GetIt.instance<SiteRepository>();
  DashboardScreen({super.key});

  void _showAddSiteDialog(BuildContext context, {Site? site}) {
    final nameController = TextEditingController(text: site?.name);
    final partnerController = TextEditingController(text: site?.partnerName);
    final addressController = TextEditingController(text: site?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site == null ? 'Add New Partner & Site' : 'Edit Partner / Site'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: partnerController.text),
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return await _siteRepository.getPartnerSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  partnerController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Sync initial value and manual changes
                  if (controller.text != partnerController.text && partnerController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = partnerController.text;
                  }
                  controller.addListener(() {
                    partnerController.text = controller.text;
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Partner Name (e.g. Veolia Water)',
                      hintText: 'Type to search partners...',
                    ),
                  );
                },
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
                partnerName: partnerController.text,
                address: addressController.text,
              );
              await _siteRepository.saveSite(newSite);
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
    // Use the single, authoritative company data
    final company = CelRonCompany.instance;

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
            tooltip: 'Add New Site/Partner',
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
                stream: _siteRepository.getSitesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
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
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF003366),
                            child: Icon(Icons.location_on, color: Colors.white),
                          ),
                          title: Text(
                            site.partnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF003366),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Site: ${site.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text('Address: ${site.address}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddSiteDialog(context, site: site),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(context, site),
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
        label: const Text('Add New Partner / Site'),
        icon: const Icon(Icons.add_business),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site?'),
        content: Text('Are you sure you want to delete "${site.partnerName} - ${site.name}"? This will also delete all associated assets and inspection records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _siteRepository.deleteSite(site.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Site "${site.name}" deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
