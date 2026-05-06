import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Condition Monitoring Knowledge Base'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Understanding Acceleration (g)'),
            _buildContentCard(
              'What can g-value predict?',
              'Acceleration (g) is most sensitive to high-frequency faults. High g-values typically predict:\n'
              '• Bearing defects (rolling element wear)\n'
              '• Gear tooth wear or damage\n'
              '• Cavitation in pumps\n'
              '• High-frequency electrical noise',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Velocity (mm/s) & ISO Standards'),
            _buildContentCard(
              'Why convert to Velocity?',
              'Velocity is the best indicator of overall machine health and structural issues. ISO 10816 / 20816 uses mm/s RMS for classification.',
            ),
            _buildISOChart(),
            const SizedBox(height: 16),
            _buildSectionTitle('2b. ISO 10816-1 Severity Matrix'),
            _buildISOSeverityMatrix(),
            const SizedBox(height: 16),
            _buildSectionTitle('2c. Detailed ISO 10816 Machine Classes'),
            _buildISO10816Detailed(),
            const SizedBox(height: 16),
            _buildSectionTitle('3. The Math: Converting g to mm/s'),
            _buildContentCard(
              'The Formula',
              'To convert peak acceleration (g) to velocity (mm/s RMS):\n\n'
              'V (mm/s RMS) = (g * 9806.65) / (2 * π * f * √2)\n\n'
              'Example:\n'
              '• Freq (f): 50 Hz (3000 RPM)\n'
              '• Acceleration: 0.5g\n'
              '• Result: ~11.0 mm/s RMS (Severe!)',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Frequency Analysis'),
            _buildContentCard(
              'Which frequency to use?',
              '• Low Freq (10Hz - 1kHz): Best for Unbalance, Misalignment, Looseness.\n'
              '• High Freq (1kHz - 10kHz): Best for Bearings and Gearbox Mesh.',
            ),
            _buildContentCard(
              'Gearbox Frequency Calculation',
              'Gear Mesh Frequency (GMF) = Input Speed (RPM) * Number of Teeth / 60\n\n'
              'To find Gearbox faults, look for peaks at the GMF and its harmonics (2x GMF, 3x GMF).',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Fault Detection Guide'),
            _buildFaultGuide(),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Maintenance Decisions & Trending'),
            _buildContentCard(
              'Trend over Time',
              'One reading is a snapshot. A Trend is a movie. Always compare current data to the baseline. A 2x increase in vibration (even if below ISO limits) warrants inspection.',
            ),
            const SizedBox(height: 24),
            _buildLearningResources(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF004488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_graph, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text(
            'Predictive Maintenance Specialist Guide',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Master the art of vibration analysis and ISO reporting.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
      ),
    );
  }

  Widget _buildContentCard(String title, String content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildISOChart() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              const Text('ISO 10816-3 Severity (mm/s RMS)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isoRow('Good (Zone A)', '< 2.3', Colors.green),
              _isoRow('Satisfactory (Zone B)', '2.3 - 4.5', Colors.lightGreen),
              _isoRow('Unsatisfactory (Zone C)', '4.5 - 7.1', Colors.orange),
              _isoRow('Unacceptable (Zone D)', '> 7.1', Colors.red),
            ],
          ),
        ),
        _buildContentCard(
          'How to build an Excel Tracker',
          'Your Excel file should have these columns:\n'
          '1. Date | 2. Asset ID | 3. Point (DE/NDE) | 4. G-Peak | 5. mm/s RMS | 6. Temp\n\n'
          'Tip: Use "Conditional Formatting" in Excel to highlight cells red if mm/s > 7.1.',
        ),
      ],
    );
  }

  Widget _isoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildISO10816Detailed() {
    return Column(
      children: [
        _classLimitsTable(
          'Machine Class: 1',
          'Small machines (up to 15 kW)',
          '1.8', '4.5',
        ),
        _classLimitsTable(
          'Machine Class: 2',
          'Medium-sized machines (15 to 75 kW)',
          '2.8', '7.1',
        ),
        _classLimitsTable(
          'Machine Class: 3',
          'Large machines on rigid foundations',
          '4.5', '11.2',
        ),
        _classLimitsTable(
          'Machine Class: 4',
          'Large machines on soft foundations',
          '7.1', '18.0',
        ),
        _classLimitsTable(
          'Machine Class: 5',
          'Reciprocating machines (Rigid)',
          '11.1', '28.0',
        ),
        _classLimitsTable(
          'Machine Class: 6',
          'Special machines (Slack coupled)',
          '18.0', '45.0',
        ),
      ],
    );
  }

  Widget _buildISOSeverityMatrix() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF003366),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: const Center(child: Text('ISO 10816-1 Velocity Severity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            children: [
              _matrixHeader(),
              _matrixRow('0.28 - 0.71', [Colors.green, Colors.green, Colors.green, Colors.green], 'Good'),
              _matrixRow('1.12 - 1.80', [Colors.white, Colors.white, Colors.green, Colors.green], 'Satisfactory'),
              _matrixRow('2.80 - 4.50', [Colors.yellow, Colors.yellow, Colors.white, Colors.white], 'Alert'),
              _matrixRow('7.10 - 11.20', [Colors.red, Colors.red, Colors.yellow, Colors.yellow], 'Alarm'),
              _matrixRow('18.00 - 45.00', [Colors.red, Colors.red, Colors.red, Colors.red], 'Critical'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _matrixHeader() {
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.all(4), child: Text('mm/s', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(4), child: Text('Class I', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(4), child: Text('Class II', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(4), child: Text('Class III', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(4), child: Text('Class IV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
      ],
    );
  }

  TableRow _matrixRow(String range, List<Color> colors, String label) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(range, style: const TextStyle(fontSize: 9))),
        ...colors.map((c) => Container(height: 30, color: c)),
      ],
    );
  }

  Widget _classLimitsTable(String title, String desc, String normal, String marginal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            color: const Color(0xFF003366).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Vibration Level', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Up to $normal mm/s')),
                  const Padding(padding: EdgeInsets.all(8), child: Text('Normal', style: TextStyle(color: Colors.green))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('$normal to $marginal mm/s')),
                  const Padding(padding: EdgeInsets.all(8), child: Text('Marginal', style: TextStyle(color: Colors.orange))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Above $marginal mm/s')),
                  const Padding(padding: EdgeInsets.all(8), child: Text('Critical', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaultGuide() {
    return Column(
      children: [
        _buildContentCard(
          'Pump Faults',
          '• Cavitation: High-frequency "hissing" g-noise.\n'
          '• Impeller Damage: Peaks at 1x RPM * No. of Vanes.\n'
          '• Misalignment: High axial vibration at 1x and 2x RPM.',
        ),
        _buildContentCard(
          'Gearbox Faults',
          '• Cracked Tooth: Periodic impact noise in time waveform.\n'
          '• Mesh Issue: High peaks at GMF with sidebands.\n'
          '• Eccentricity: Modulation of GMF by shaft RPM.',
        ),
      ],
    );
  }

  Widget _buildLearningResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Learning Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
        const SizedBox(height: 12),
        _buildLinkTile('Mobius Institute - Vibration 101', 'https://www.youtube.com/user/MobiusInstitute'),
        _buildLinkTile('Reliability Web - Asset Management', 'https://reliabilityweb.com/'),
        _buildLinkTile('ISO 20816 Standards Guide', 'https://www.iso.org/standard/66181.html'),
      ],
    );
  }

  Widget _buildLinkTile(String title, String url) {
    return ListTile(
      leading: const Icon(Icons.menu_book, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );
  }
}
