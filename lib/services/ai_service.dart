import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/asset.dart';
import '../models/inspection.dart';

class AIService {
  final String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty 
      ? const String.fromEnvironment('GEMINI_API_KEY') 
      : dotenv.get('GEMINI_API_KEY', fallback: '');

  final String _groqApiKey = const String.fromEnvironment('GROQ_API_KEY').isNotEmpty 
      ? const String.fromEnvironment('GROQ_API_KEY') 
      : dotenv.get('GROQ_API_KEY', fallback: '');

  // Default to Gemini if key is available, else Groq
  bool get _useGemini => _geminiApiKey.isNotEmpty && _geminiApiKey != 'YOUR_API_KEY_HERE';
  
  String get _apiKey => _useGemini ? _geminiApiKey : _groqApiKey;

  bool get isAvailable => _apiKey.isNotEmpty && _apiKey != 'YOUR_GROQ_KEY_HERE' && _apiKey != 'YOUR_API_KEY_HERE';

  Future<String> generateFinalConclusion(Asset asset, Inspection inspection) async {
    if (!isAvailable) {
      return "AI Analysis is currently unavailable. Please configure your GEMINI_API_KEY or GROQ_API_KEY in the .env file.";
    }

    if (_useGemini) {
      final geminiResult = await _generateGeminiConclusion(asset, inspection);
      
      // Check if Gemini hit a rate limit / quota exhaustion (Error 429 / RESOURCE_EXHAUSTED)
      if (geminiResult.contains('Error from Gemini API: 429') || 
          geminiResult.contains('RESOURCE_EXHAUSTED')) {
        
        // Fall back to Groq if the key is available
        if (_groqApiKey.isNotEmpty && _groqApiKey != 'YOUR_GROQ_KEY_HERE') {
          final groqResult = await _generateGroqConclusion(asset, inspection);
          // If Groq succeeded, return the Groq verdict transparently
          if (!groqResult.startsWith('Error from Groq API:')) {
            return groqResult;
          }
        }
      }
      return geminiResult;
    } else {
      return _generateGroqConclusion(asset, inspection);
    }
  }

  Future<String> _generateGeminiConclusion(Asset asset, Inspection inspection) async {
    const String model = 'gemini-flash-latest';
    final String url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''You are a Senior Preventive Maintenance Engineer specializing in industrial pump systems (API 610/ISO 10816).
Your task is to synthesize a professional FINAL CONCLUSION based on multiple technical data points.

INSPECTION SNAPSHOT:
Asset: ${asset.name} (${asset.type})
Vibration: ${inspection.vibrationG}g | Velocity: ${(inspection.vibrationG * 31.2).toStringAsFixed(2)} mm/s
Temperature: ${inspection.temperatureC}°C
Motor Data & Amps: ${inspection.motorParameters}
Pump Condition & Leaks: ${inspection.pumpParameters}
Fasteners & Piping: ${inspection.pipeParameters}
Status: ${inspection.overallStatus}

OUTPUT REQUIREMENTS:
- Provide a professional, one-paragraph verdict (50-100 words).
- Direct, technical, and data-driven language.
- Clearly state the health status, the most critical finding, and the maintenance urgency.
- Do NOT use bullet points.'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      } else {
        return "Error from Gemini API: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error during Gemini conclusion generation: $e";
    }
  }

  Future<String> _generateGroqConclusion(Asset asset, Inspection inspection) async {
    final String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
    final String model = 'llama-3.3-70b-versatile';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
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
      return "Error during Groq conclusion generation: $e";
    }
  }

  // Legacy method for backward compatibility
  Future<String> analyzeInspection(Asset asset, Inspection inspection) async {
    return generateFinalConclusion(asset, inspection);
  }
}
