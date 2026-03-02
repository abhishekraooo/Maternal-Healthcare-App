import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

// --- Data Models ---
class PrescriptionAnalysis {
  final List<MedicationInfo> medications;
  final String generalAdvice;
  final String disclaimer;

  PrescriptionAnalysis({
    required this.medications,
    required this.generalAdvice,
    required this.disclaimer,
  });

  factory PrescriptionAnalysis.fromJson(Map<String, dynamic> json) {
    var list = json['medications'] as List? ?? [];
    List<MedicationInfo> medList =
        list.map((i) => MedicationInfo.fromJson(i)).toList();

    return PrescriptionAnalysis(
      medications: medList,
      generalAdvice: json['general_advice'] ?? 'No general advice provided.',
      disclaimer:
          json['disclaimer'] ??
          'Always consult your doctor before taking any medication during pregnancy.',
    );
  }
}

class MedicationInfo {
  final String name;
  final String usage;
  final String pregnancySafety;

  MedicationInfo({
    required this.name,
    required this.usage,
    required this.pregnancySafety,
  });

  factory MedicationInfo.fromJson(Map<String, dynamic> json) {
    return MedicationInfo(
      name: json['name'] ?? 'Unknown',
      usage: json['usage'] ?? 'Usage not specified',
      pregnancySafety: json['pregnancy_safety'] ?? 'Safety unknown',
    );
  }
}

// --- Main Screen ---
class PrescriptionAnalysisPage extends StatefulWidget {
  final String extractedText;

  const PrescriptionAnalysisPage({super.key, required this.extractedText});

  @override
  State<PrescriptionAnalysisPage> createState() =>
      _PrescriptionAnalysisPageState();
}

class _PrescriptionAnalysisPageState extends State<PrescriptionAnalysisPage> {
  bool _isLoading = true;
  String? _errorMessage;
  PrescriptionAnalysis? _analysisResult;

  @override
  void initState() {
    super.initState();
    _loadOrFetchData();
  }

  Future<void> _loadOrFetchData() async {
    final provider = Provider.of<PatientDataProvider>(context, listen: false);

    // If the exact same text was already analyzed and cached, load it instantly.
    if (provider.cachedPrescriptionText == widget.extractedText &&
        provider.cachedPrescriptionAnalysis != null) {
      setState(() {
        _analysisResult = PrescriptionAnalysis.fromJson(
          provider.cachedPrescriptionAnalysis!,
        );
        _isLoading = false;
      });
      return;
    }

    // Otherwise, fetch from Gemini
    await _analyzeWithGemini();
  }

  Future<void> _analyzeWithGemini() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API Key not found');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey',
      );

      final String prompt = '''
      You are an expert maternal healthcare AI. Analyze the following OCR text extracted from a medical prescription: 
      "${widget.extractedText}"
      
      Identify any medications mentioned. For each medication, explain its standard usage and its safety profile during pregnancy based on standard medical guidelines.
      
      Respond ONLY with a valid JSON object matching exactly this structure. Do not use markdown blocks like ```json.
      {
        "medications": [
          {
            "name": "Medication Name",
            "usage": "What it is used for",
            "pregnancy_safety": "Is it safe during pregnancy? Detail any risks."
          }
        ],
        "general_advice": "Brief summary of the prescription's intent",
        "disclaimer": "A strong medical disclaimer"
      }
      ''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {"responseMimeType": "application/json"},
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final textContent =
            responseBody['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> jsonResult = jsonDecode(textContent);

        setState(() {
          _analysisResult = PrescriptionAnalysis.fromJson(jsonResult);
          _isLoading = false;
        });

        // Save to provider cache
        if (mounted) {
          Provider.of<PatientDataProvider>(
            context,
            listen: false,
          ).savePrescriptionCache(widget.extractedText, jsonResult);
        }
      } else {
        throw Exception('Failed to analyze prescription');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not analyze the text. Please ensure the scan is clear or try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeWithGemini,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_analysisResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Disclaimer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _analysisResult!.disclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // General Advice
          Text(
            'Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysisResult!.generalAdvice,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Medications List
          Text(
            'Identified Medications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (_analysisResult!.medications.isEmpty)
            const Text(
              'No specific medications could be identified from this scan.',
            )
          else
            ..._analysisResult!.medications.map(
              (med) => _buildMedicationCard(theme, med),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary.withOpacity(0.5),
                ),
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Consulting Medical AI...',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analyzing prescription safety profiles',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(ThemeData theme, MedicationInfo med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    med.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            _buildDataRow(theme, 'Usage', med.usage),
            const SizedBox(height: 12),
            _buildDataRow(
              theme,
              'Pregnancy Safety',
              med.pregnancySafety,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    ThemeData theme,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: isHighlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
          decoration:
              isHighlight
                  ? BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                    ),
                  )
                  : null,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isHighlight ? theme.colorScheme.primary : Colors.black87,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
