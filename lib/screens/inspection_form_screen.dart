import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asset.dart';
import '../models/inspection.dart';
import '../models/site.dart';
import 'pdf_preview_screen.dart';
import '../domain/repositories/inspection_repository.dart';
import 'package:get_it/get_it.dart';
import '../services/storage_service.dart';
import '../core/celron_company.dart';
import '../services/pdf_service.dart';
import '../logic/health_logic.dart';

import '../models/service_visit.dart';

class InspectionFormScreen extends StatefulWidget {
  final Asset asset;
  final Site site;
  final String? visitId;
  final ServiceVisit? visit;

  const InspectionFormScreen({
    super.key, 
    required this.asset, 
    required this.site,
    this.visitId,
    this.visit,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final InspectionRepository _inspectionRepo = GetIt.instance<InspectionRepository>();
  final _picker = ImagePicker();
  XFile? _vibrationImg;
  XFile? _tempImg;

  double _vibrationG = 0.001;
  double _temperatureC = 55.0;
  String _overallStatus = 'NORMAL';

  late Map<String, dynamic> _motorParams;
  late Map<String, dynamic> _pumpParams;
  late Map<String, dynamic> _pipeParams;

  late TextEditingController _projectRefController;
  late TextEditingController _partnerRefController;
  final _inspectionByController = TextEditingController(text: 'Service Engineer');
  final _quarterlyCycleController = TextEditingController(text: 'Q1-2025');

  @override
  void dispose() {
    _projectRefController.dispose();
    _partnerRefController.dispose();
    _inspectionByController.dispose();
    _quarterlyCycleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _projectRefController = TextEditingController(text: widget.visit?.celronRef ?? 'PRJ-2025-001');
    _partnerRefController = TextEditingController(text: widget.visit?.customerRef ?? 'PART-REF-001');
    _initializeDefaults();
    _updateStatus();
  }

  void _initializeDefaults() {
    _motorParams = {
      'Loose or Missing Bolts, Terminal block': {'status': 'OK', 'remark': ''},
      'Variable speed drive': {'status': 'OK', 'remark': ''},
      'Panel temperature by thermal scanning': {'status': 'OK', 'remark': ''},
      'Selector switch and indication lamps': {'status': 'OK', 'remark': ''},
      'Contactor, relays, MCB, timer, loose connection': {'status': 'OK', 'remark': ''},
      'Dust & foreign materials (keep dry)': {'status': 'OK', 'remark': ''},
      'Corrosion on the internal & external of panel': {'status': 'OK', 'remark': ''},
      'Motor winding resistance': {'status': 'OK', 'remark': 'U1-V1= 0.31 Ω, U1-W1= 0.31 Ω, V1-W1= 0.32 Ω'},
      'Motor insulation resistance': {'status': 'OK', 'remark': 'U1-E=2000MΩ, V1-E =2000MΩ, W1-E =2000MΩ'},
      'Incoming voltage': {'status': 'OK', 'remark': 'L1-L2= 421V  L1-L3=420V     L2-L3=420V'},
      'Motor abnormal noise': {'status': 'OK', 'remark': ''},
      'Motor vibration value': {'status': 'OK', 'remark': 'DE= 0.4mm/s  NDE= 0.7mm/s    A=0.4 mm/s'},
      'Motor voltage': {'status': 'OK', 'remark': 'U=245V       V=245V         W=245V'},
      'Motor Running Current': {'status': 'OK', 'remark': 'U=10.4Amps  V=10.4Amps   W=10Amps'},
      'NDE, DE & Body Temperature': {'status': 'OK', 'remark': 'NDE=32°C,   DE=32.2°C,    BODY=33.3°C'},
      'Motor running': {'status': 'OK', 'remark': ''},
    };

    _pumpParams = {
      'Loose or Missing Bolts': {'status': 'OK', 'remark': ''},
      'Excessive or Abnormal noise': {'status': 'OK', 'remark': ''},
      'Leak from the mech. Seal': {'status': 'OK', 'remark': ''},
      'Leak from Pump Casing, inlet & outlet flange': {'status': 'OK', 'remark': ''},
      'Inspect Suction line strainer': {'status': 'OK', 'remark': ''},
      'pump inboard, outboard and Body Temp': {'status': 'OK', 'remark': 'IB= 31°C,    OB= 31°C,      BODY=31°C'},
      'Excessive vibration by Physical touch': {'status': 'OK', 'remark': ''},
    };

    _pipeParams = {
      'Suction Gate valve': {'status': 'OK', 'remark': 'IB= 31°C,    OB= 31°C,      BODY=31°C'},
      'Strainer': {'status': 'N/A', 'remark': ''},
      'Check Valve18': {'status': 'OK', 'remark': ''},
      'Pipes': {'status': 'OK', 'remark': ''},
    };
  }

  void _updateStatus() {
    setState(() {
      _overallStatus = HealthLogic.getStatusLabel(
        HealthLogic.getOverallStatus(_vibrationG, _temperatureC),
      );
    });
  }

  Future<void> _pickImage(bool isVib) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isVib) _vibrationImg = image;
        else _tempImg = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Inspection: ${widget.asset.reference}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataDisplay(),
            const SizedBox(height: 16),
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildProjectDetailsSection(),
            const SizedBox(height: 24),
            _buildVibrationTempSection(),
            const SizedBox(height: 24),
            _buildParameterSection('Motor Parameters', _motorParams, Icons.settings_input_component),
            const SizedBox(height: 24),
            _buildParameterSection('Pump Parameters', _pumpParams, Icons.plumbing),
            const SizedBox(height: 24),
            _buildParameterSection('Pipes and Others Parameters', _pipeParams, Icons.account_tree),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildMetadataDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF003366).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner: ${widget.site.partnerName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Site: ${widget.site.name}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Address: ${widget.site.address}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),
          Text(
            'System: ${widget.asset.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)),
          ),
          Text(
            'Ref: ${widget.asset.reference}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'Loc: ${widget.asset.location}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Machine Class: ${HealthLogic.getClass(widget.asset.powerKw)} (${widget.asset.powerKw} kW)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor = Colors.green;
    if (_overallStatus == 'MARGINAL') statusColor = Colors.orange;
    if (_overallStatus == 'CRITICAL') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SYSTEM HEALTH:', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _overallStatus,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProjectDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF003366)),
                SizedBox(width: 8),
                Text('Project Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _projectRefController,
              decoration: const InputDecoration(labelText: 'Project Ref', border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partnerRefController,
              decoration: const InputDecoration(labelText: 'Partner Ref', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _inspectionByController,
              decoration: const InputDecoration(labelText: 'Inspection By', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quarterlyCycleController,
              decoration: const InputDecoration(labelText: 'Quarterly Cycle (e.g. Q1-25)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_view_day)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrationTempSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.thermostat, color: Color(0xFF003366)),
                SizedBox(width: 8),
                Text('Vibration & Temperature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _vibrationG.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Vibration (g)',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _vibrationG = double.tryParse(val) ?? 0;
                      _updateStatus();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _temperatureC.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Temperature (°C)',
                      border: OutlineInputBorder(),
                      suffixText: '°C',
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _temperatureC = double.tryParse(val) ?? 0;
                      _updateStatus();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildImagePicker('Vibration Scan', _vibrationImg, () => _pickImage(true)),
                const SizedBox(width: 16),
                _buildImagePicker('Thermal Scan', _tempImg, () => _pickImage(false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, XFile? file, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.blue),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                )
              : const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
      ),
    );
  }

  Widget _buildParameterSection(String title, Map<String, dynamic> params, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF003366)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
              ],
            ),
            const Divider(),
            ...params.keys.map((key) => _buildParamRow(key, params[key])),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: data['status'],
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8), border: OutlineInputBorder()),
                  items: ['OK', 'NOT OK', 'N/A', 'YES', 'NO'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setState(() => data['status'] = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: data['remark'],
            decoration: const InputDecoration(
              hintText: 'Reading / Remark',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) => data['remark'] = val,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          minimumSize: const Size(double.infinity, 50),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: _saveInspection,
        child: const Text('GENERATE CERTIFICATE & SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _saveInspection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? vibUrl;
      String? tempUrl;

      if (_vibrationImg != null) {
        vibUrl = await StorageService().uploadImage(_vibrationImg!, 'inspections/${widget.asset.reference}_vib.jpg');
      }
      if (_tempImg != null) {
        tempUrl = await StorageService().uploadImage(_tempImg!, 'inspections/${widget.asset.reference}_temp.jpg');
      }

      final company = CelRonCompany.instance;

      final site = widget.site;

      final inspection = Inspection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        assetId: widget.asset.id,
        date: DateTime.now(),
        projectRef: _projectRefController.text,
        partnerRef: _partnerRefController.text,
        inspectionBy: _inspectionByController.text,
        quarterlyCycle: _quarterlyCycleController.text,
        vibrationG: _vibrationG,
        temperatureC: _temperatureC,
        vibrationImgUrl: vibUrl,
        tempImgUrl: tempUrl,
        motorParameters: _motorParams,
        pumpParameters: _pumpParams,
        pipeParameters: _pipeParams,
        otherParameters: {},
        overallStatus: _overallStatus,
        visitId: widget.visitId,
      );

      await _inspectionRepo.saveInspection(inspection);

      final pdfData = await PdfService.generateInspectionPdf(
        company: company,
        site: site,
        asset: widget.asset,
        inspection: inspection,
      );

      if (mounted) {
        Navigator.pop(context);
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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
