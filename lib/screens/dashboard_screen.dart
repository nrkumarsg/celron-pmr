import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/site.dart';
import '../domain/repositories/site_repository.dart';
import 'visit_list_screen.dart';
import 'asset_list_screen.dart';
import '../core/celron_company.dart';
import '../models/company.dart';

// ─────────────────────────────────────────────────────────────
// Dashboard Screen
// ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SiteRepository _siteRepository = GetIt.instance<SiteRepository>();


  void _showAddSiteDialog(BuildContext context, List<Site> allSites, {Site? site}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddEditSiteDialog(
        existingSites: allSites,
        siteToEdit: site,
        onSave: (newSite) async {
          await _siteRepository.saveSite(newSite);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site?'),
        content: Text(
          'Are you sure you want to delete "${site.partnerName} — ${site.name}"?\n\n'
          'This will also delete all associated assets and inspection records.',
        ),
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

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF003366).withValues(alpha: 0.05),
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
                  Text('Welcome back,', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
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

                  final sites = snapshot.data ?? [];

                  if (sites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No sites found. Add your first site!'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showAddSiteDialog(context, sites),
                            child: const Text('Add Site'),
                          ),
                        ],
                      ),
                    );
                  }

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
                            site.partnerName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color(0xFF003366),
                              letterSpacing: 0.5,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003366).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF003366).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_center, size: 14, color: Color(0xFF003366)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        site.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (site.hqAddress.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.business_outlined, size: 12, color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'HQ: ${site.hqAddress}',
                                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  const Icon(Icons.pin_drop, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      site.address,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showAddSiteDialog(context, sites, site: site),
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
                                builder: (context) => VisitListScreen(
                                  site: site,
                                  company: company,
                                ),
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
      floatingActionButton: StreamBuilder<List<Site>>(
        stream: _siteRepository.getSitesStream(),
        builder: (context, snapshot) {
          final sites = snapshot.data ?? [];
          return FloatingActionButton.extended(
            onPressed: () => _showAddSiteDialog(context, sites),
            label: const Text('Add New Partner / Site'),
            icon: const Icon(Icons.add_business),
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add / Edit Site Dialog — Two-Section Form
// ─────────────────────────────────────────────────────────────
class _AddEditSiteDialog extends StatefulWidget {
  final List<Site> existingSites;
  final Site? siteToEdit;
  final Future<void> Function(Site) onSave;

  const _AddEditSiteDialog({
    required this.existingSites,
    required this.onSave,
    this.siteToEdit,
  });

  @override
  State<_AddEditSiteDialog> createState() => _AddEditSiteDialogState();
}

class _AddEditSiteDialogState extends State<_AddEditSiteDialog> {
  final _formKey = GlobalKey<FormState>();

  // Customer section
  String? _selectedCustomer;         // chosen from dropdown
  final _newCustomerController = TextEditingController();
  final _customerAddressController = TextEditingController();
  bool _isNewCustomer = false;       // true when user types a brand-new name

  // Site section
  final _siteNameController = TextEditingController();
  final _siteAddressController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.siteToEdit;
    if (s != null) {
      // Editing existing: pre-populate fields
      _selectedCustomer = s.partnerName.isNotEmpty ? s.partnerName : null;
      _customerAddressController.text = s.hqAddress;
      _siteNameController.text = s.name;
      _siteAddressController.text = s.address;
    }
  }

  @override
  void dispose() {
    _newCustomerController.dispose();
    _customerAddressController.dispose();
    _siteNameController.dispose();
    _siteAddressController.dispose();
    super.dispose();
  }

  /// Unique customer names derived from existing sites
  List<String> get _customerOptions {
    return widget.existingSites
        .map((s) => s.partnerName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String get _effectiveCustomerName =>
      _isNewCustomer ? _newCustomerController.text.trim() : (_selectedCustomer ?? '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final site = Site(
      id: widget.siteToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: 'celron',
      partnerName: _effectiveCustomerName,
      hqAddress: _customerAddressController.text.trim(),
      name: _siteNameController.text.trim(),
      address: _siteAddressController.text.trim(),
    );

    await widget.onSave(site);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.siteToEdit != null;
    final options = _customerOptions;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Partner / Site' : 'Add New Partner & Site'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── CUSTOMER SECTION ──────────────────────────
                _SectionHeader(icon: Icons.business, label: 'Customer'),
                const SizedBox(height: 10),

                // Customer dropdown
                if (!_isNewCustomer) ...[
                  DropdownButtonFormField<String>(
                    value: options.contains(_selectedCustomer) ? _selectedCustomer : null,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.people_outline),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select existing customer...'),
                    items: [
                      ...options.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                    validator: (_) {
                      if (!_isNewCustomer && (_selectedCustomer == null || _selectedCustomer!.isEmpty)) {
                        return 'Please select or add a customer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Link to switch to typing a new customer
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _isNewCustomer = true;
                        _selectedCustomer = null;
                      }),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New Customer'),
                    ),
                  ),
                ] else ...[
                  // New customer text field
                  TextFormField(
                    controller: _newCustomerController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'New Customer Name *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Veolia Water Technologies',
                    ),
                    validator: (v) {
                      if (_isNewCustomer && (v == null || v.trim().isEmpty)) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Link back to dropdown
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _isNewCustomer = false;
                        _newCustomerController.clear();
                      }),
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Pick Existing Customer'),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                // Customer address (optional — informational only)
                TextFormField(
                  controller: _customerAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Customer HQ Address (optional)',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 1 Cleantech Loop, Singapore',
                  ),
                ),

                const SizedBox(height: 24),

                // ── SITE SECTION ──────────────────────────────
                _SectionHeader(icon: Icons.factory, label: 'Service Site'),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _siteNameController,
                  decoration: const InputDecoration(
                    labelText: 'Site / Plant Name *',
                    prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Micron Fab 10 — Chiller Plant',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Site name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _siteAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Site Address *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 990 Bendemeer Rd, Singapore 339942',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Site address is required' : null,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(isEditing ? 'Update' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Header Widget
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF003366)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF003366),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: const Color(0xFF003366).withValues(alpha: 0.3))),
      ],
    );
  }
}
