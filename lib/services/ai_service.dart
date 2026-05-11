import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/asset.dart';
import '../models/inspection.dart';

class AIService {
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY').isNotEmpty 
      ? const String.fromEnvironment('GROQ_API_KEY') 
      : dotenv.get('GROQ_API_KEY', fallback: '');

  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _model = 'llama-3.3-70b-versatile';

  bool get isAvailable => _apiKey.isNotEmpty && _apiKey != 'YOUR_GROQ_KEY_HERE';

  Future<String> generateFinalConclusion(Asset asset, Inspection inspection) async {
    if (!isAvailable) {
      return "AI Analysis is currently unavailable. Please configure your GROQ_API_KEY.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a Senior Preventive Maintenance Engineer specializing in industrial pump systems (API 610/ISO 10816).
Your task is to synthesize a professional FINAL CONCLUSION based on multiple technical data points.

You MUST analyze and correlate the following factors:
1. VIBRATION: Both g-levels and Velocity (mm/s).
2. THERMAL: Operating temperature relative to typical limits.
3. ELECTRICAL: Ampere readings and motor load.
4. MECHANICAL: Fastener integrity (bolts/nuts), mechanical seals (leaks), and structural condition.
5. AUXILIARY: Pipes, strainers, and valves.

OUTPUT REQUIREMENTS:
- Provide a professional, one-paragraph verdict (50-100 words).
- Direct, technical, and data-driven language.
- Clearly state the health status, the most critical finding, and the maintenance urgency.
- Do NOT use bullet points.'''
            },
            {
              'role': 'user',
              'content': '''INSPECTION SNAPSHOT:
Asset: ${asset.name} (${asset.type})
Vibration: ${inspection.vibrationG}g | Velocity: ${(inspection.vibrationG * 31.2).toStringAsFixed(2)} mm/s
Temperature: ${inspection.temperatureC}°C
Motor Data & Amps: ${inspection.motorParameters}
Pump Condition & Leaks: ${inspection.pumpParameters}
Fasteners & Piping: ${inspection.pipeParameters}
Status: ${inspection.overallStatus}'''
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return "Error from Groq API: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error during AI conclusion generation: $e";
    }
  }

  // Legacy method for backward compatibility
  Future<String> analyzeInspection(Asset asset, Inspection inspection) async {
    return generateFinalConclusion(asset, inspection);
  }
}
