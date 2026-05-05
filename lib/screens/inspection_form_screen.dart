import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asset.dart';
import '../models/inspection.dart';
import '../logic/health_logic.dart';
import '../services/pdf_service.dart';
import '../models/company.dart';
import '../models/site.dart';
import 'pdf_preview_screen.dart';
import 'dart:typed_data';

class InspectionFormScreen extends StatefulWidget {
  final Asset asset;

  const InspectionFormScreen({super.key, required this.asset});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  double _vibrationG = 0.0;
  double _temperatureC = 0.0;
  XFile? _vibrationImg;
  XFile? _tempImg;

  final Map<String, String> _motorParams = {
    'Loose or Missing Bolts': 'OK',
    'Variable speed drive': 'OK',
    'Motor vibration value': '',
    'Motor winding resistance': '',
  };

  final Map<String, String> _pumpParams = {
    'Loose or Missing Bolts': 'OK',
    'Leak from the mech. Seal': 'OK',
    'Pump inboard/outboard Temp': '',
  };

  HealthStatus get _overallStatus => HealthLogic.getOverallStatus(_vibrationG, _temperatureC);

  Future<void> _pickImage(bool isVibration) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        if (isVibration) {
          _vibrationImg = image;
        } else {
          _tempImg = image;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = HealthLogic.getStatusColor(_overallStatus);
    final statusLabel = HealthLogic.getStatusLabel(_overallStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Inspection: ${widget.asset.reference}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Status Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SYSTEM HEALTH:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Critical Readings
              const Text('Vibration & Temperature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Vibration (g)',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          _vibrationG = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Temperature (°C)',
                        border: OutlineInputBorder(),
                        suffixText: '°C',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          _temperatureC = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Uploaders
              Row(
                children: [
                  Expanded(
                    child: _ImageUploadButton(
                      label: 'Vibration Photo',
                      image: _vibrationImg,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ImageUploadButton(
                      label: 'Thermal Scan',
                      image: _tempImg,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),

              // Motor Parameters
              _ParameterSection(title: 'Motor Parameters', params: _motorParams),
              const SizedBox(height: 16),
              
              // Pump Parameters
              _ParameterSection(title: 'Pump Parameters', params: _pumpParams),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Create dummy data for PDF
                    final company = Company(
                      id: 'celron',
                      name: 'CEL-RON Enterprises Pte Ltd',
                      regOffice: '14, Robinson Road, #08-01A, Far East Finance Building, Singapore 048545',
                      phone: '+65 66181721',
                      fax: '+65 63334636',
                      mobile: '+65 97685891',
                      email: 'sales@celron.net',
                      web: 'www.celron.net',
                      brn: '201436227C',
                      gstReg: '201436227C',
                    );

                    final site = Site(id: '1', companyId: 'celron', name: 'Micron Bendemeer', address: '990 Bendemeer Road, Singapore');

                    final inspection = Inspection(
                      id: 'new',
                      assetId: widget.asset.id,
                      date: DateTime.now(),
                      cycle: '2nd Quarter 2025',
                      vibrationG: _vibrationG,
                      temperatureC: _temperatureC,
                      motorParameters: _motorParams,
                      pumpParameters: _pumpParams,
                      otherParameters: {},
                      overallStatus: _overallStatus,
                    );

                    final pdfData = await PdfService.generateInspectionPdf(
                      company: company,
                      site: site,
                      asset: widget.asset,
                      inspection: inspection,
                    );

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(
                            pdfData: pdfData,
                            fileName: 'Report_${widget.asset.reference}.pdf',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('GENERATE CERTIFICATE & SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadButton extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;

  const _ImageUploadButton({required this.label, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.grey),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            : const Icon(Icons.check_circle, color: Colors.green, size: 40),
      ),
    );
  }
}

class _ParameterSection extends StatelessWidget {
  final String title;
  final Map<String, String> params;

  const _ParameterSection({required this.title, required this.params});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        ...params.keys.map((key) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(key, style: const TextStyle(fontSize: 14))),
              Expanded(
                child: TextFormField(
                  initialValue: params[key],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => params[key] = val,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
