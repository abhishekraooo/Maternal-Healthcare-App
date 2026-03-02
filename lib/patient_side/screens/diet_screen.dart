import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

// Data model
class DietSuggestion {
  final String name;
  final String quantity;
  final String description;

  DietSuggestion({
    required this.name,
    required this.quantity,
    required this.description,
  });

  factory DietSuggestion.fromJson(Map<String, dynamic> json) {
    return DietSuggestion(
      name: json['name'] ?? 'No Name',
      quantity: json['quantity'] ?? 'N/A',
      description: json['description'] ?? 'No description available.',
    );
  }
}

class PatientDietScreen extends StatefulWidget {
  const PatientDietScreen({super.key});

  @override
  State<PatientDietScreen> createState() => _PatientDietScreenState();
}

class _PatientDietScreenState extends State<PatientDietScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  List<DietSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load cached data from the Provider when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      if (provider.cachedDietSuggestions.isNotEmpty) {
        setState(() {
          _monthController.text = provider.cachedDietMonth;
          _weightController.text = provider.cachedDietWeight;
          // Cast the cached dynamic list back to DietSuggestion
          _suggestions = provider.cachedDietSuggestions.cast<DietSuggestion>();
        });
      }
    });
  }

  @override
  void dispose() {
    _monthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --- Main Logic to Get Diet Suggestions ---
  Future<void> _getDietSuggestions() async {
    if (_formKey.currentState!.validate()) {
      final int month = int.tryParse(_monthController.text) ?? 0;
      final String weight = _weightController.text;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _suggestions = [];
      });

      try {
        final fetchedSuggestions = await _fetchSuggestionsFromGemini(month);

        setState(() {
          _suggestions = fetchedSuggestions;
        });

        // Save the successful fetch to our global provider cache
        if (mounted) {
          Provider.of<PatientDataProvider>(
            context,
            listen: false,
          ).saveDietCache(fetchedSuggestions, _monthController.text, weight);
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Error: ${e.toString()}";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }

      FocusScope.of(context).unfocus();
    }
  }

  Future<List<DietSuggestion>> _fetchSuggestionsFromGemini(int month) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API Key not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey',
    );

    final String prompt = '''
    You are a pregnancy nutrition expert. Your knowledge is based STRICTLY on guidelines from healthychildren.org (American Academy of Pediatrics).
    For month $month of pregnancy, provide 5 distinct dietary suggestions focusing on key nutrients for that stage.
    Respond ONLY with a valid JSON array of objects. Do not include any other text, explanations, or markdown formatting like ```json.
    Each object must have three string keys: "name", "quantity", and "description".
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
      final List<dynamic> jsonList = jsonDecode(textContent);

      return jsonList.map((json) => DietSuggestion.fromJson(json)).toList();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Failed to load suggestions: ${errorBody['error']['message']}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pregnancy Diet Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputForm(theme),
                const SizedBox(height: 32),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_suggestions.isNotEmpty) _buildResultsSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Tell Us About Your Pregnancy",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _monthController,
              decoration: _buildInputDecoration(
                theme,
                'Current Month (1-9)',
                Icons.calendar_today,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a month';
                }
                final month = int.tryParse(value);
                if (month == null || month < 1 || month > 9) {
                  return 'Please enter a valid month (1-9)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: _buildInputDecoration(
                theme,
                'Pre-Pregnancy Weight (kg)',
                Icons.monitor_weight_outlined,
              ),
              keyboardType: TextInputType.number,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter your weight'
                          : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _getDietSuggestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Get Suggestions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Daily Suggestions",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.secondary),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These AI-generated suggestions are for informational purposes. Always consult your healthcare provider for personalized medical advice.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            return _buildSuggestionCard(theme, _suggestions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(ThemeData theme, DietSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Recommended: ${suggestion.quantity}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            Text(
              suggestion.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme,
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.secondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }
}
