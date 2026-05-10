import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/asset.dart';
import '../models/inspection.dart';

class AIService {
  late final GenerativeModel _model;
  final String _apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');

  AIService() {
    if (_apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE') {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    }
  }

  bool get isAvailable => _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE';

  Future<String> analyzeInspection(Asset asset, Inspection inspection) async {
    if (!isAvailable) {
      return "AI Analysis is currently unavailable. Please configure your GEMINI_API_KEY in the .env file to enable Version 2 diagnostic reports.";
    }

    try {
      final prompt = '''
As an expert industrial maintenance engineer, analyze the following inspection data for a ${asset.type} ${asset.name}.

Asset Details:
- Reference: ${asset.reference}
- Model: ${asset.model}
- Power: ${asset.powerKw} kW
- RPM: ${asset.rpm}
- Location: ${asset.location}

Current Inspection Data:
- Vibration (g): ${inspection.vibrationG}
- Temperature (°C): ${inspection.temperatureC}
- Overall Status: ${inspection.overallStatus}
- Motor Parameters: ${inspection.motorParameters}
- Pump Parameters: ${inspection.pumpParameters}
- Pipe/Other Parameters: ${inspection.pipeParameters}

Please provide:
1. A concise health assessment summary.
2. Potential failure modes identified from this data.
3. Specific maintenance recommendations for the next cycle.
4. If critical, immediate actions required.

Format the output in a professional report style.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "AI failed to generate a response.";
    } catch (e) {
      print('AIService Error: $e');
      return "Error during AI analysis: $e";
    }
  }
}
