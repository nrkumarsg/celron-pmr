import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/database_service.dart';

class EditAssetScreen extends StatefulWidget {
  final String siteId;
  final Asset? asset;

  const EditAssetScreen({super.key, required this.siteId, this.asset});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _refController = TextEditingController();
  final _typeController = TextEditingController();
  final _modelController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _nameController.text = widget.asset!.name;
      _refController.text = widget.asset!.reference;
      _typeController.text = widget.asset!.type;
      _modelController.text = widget.asset!.model;
      _locationController.text = widget.asset!.location;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset == null ? 'Add Asset' : 'Edit Asset'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'System Name (e.g. Pump System 1)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(labelText: 'Reference Number (e.g. REF-001)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'System Type (e.g. Centrifugal)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model (e.g. CP-200)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Asset Location (e.g. L3, Roof)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final asset = Asset(
                      id: widget.asset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      siteId: widget.siteId,
                      name: _nameController.text,
                      reference: _refController.text,
                      type: _typeController.text,
                      model: _modelController.text,
                      location: _locationController.text,
                    );
                    await DatabaseService().saveAsset(asset);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(widget.asset == null ? 'CREATE SYSTEM' : 'SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
