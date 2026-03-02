import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:maternalhealthcare/doc_prescription/prescription_analysis_page.dart';

class TextRecognitionPage extends StatefulWidget {
  final String imagePath;
  final String imageUrl;
  final bool isFromGallery;

  const TextRecognitionPage({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    required this.isFromGallery,
  });

  @override
  _TextRecognitionPageState createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends State<TextRecognitionPage> {
  String _extractedText = '';
  bool _isLoading = true; // Tracks OCR scanning
  bool _isPlaying = false; // Tracks Text-to-Speech
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _recognizeText();
  }

  // Initialize TTS settings and state handlers
  void _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);

    // Automatically reset the play button when the speech finishes naturally
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _recognizeText() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String extractedText = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          extractedText += '${line.text}\n';
        }
        extractedText += '\n'; // Add spacing between paragrap  h blocks
      }

      if (mounted) {
        setState(() {
          _extractedText = extractedText.trim();
          _isLoading = false;
        });
      }

      textRecognizer.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error recognizing text: $e')));
      }
    }
  }

  // Function to start or stop reading text
  void _toggleReading() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
    } else {
      if (_extractedText.isNotEmpty) {
        setState(() => _isPlaying = true);
        await _flutterTts.speak(_extractedText);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No text to read.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Review Prescription',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          if (!_isLoading && _extractedText.isNotEmpty)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              tooltip: _isPlaying ? 'Stop Reading' : 'Read Aloud',
              onPressed: _toggleReading,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Extracted Text',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review the text below. Once verified, tap analyze to get AI insights.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                // Main Text Container (Responsive & Scrollable)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        _isLoading
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Scanning document...',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(20.0),
                              child:
                                  _extractedText.isNotEmpty
                                      ? Text(
                                        _extractedText,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: Colors.black87,
                                          height:
                                              1.6, // Increased line height for readability
                                          letterSpacing: 0.3,
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          'No readable text found in this image.\nPlease try taking a clearer photo.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Action
                ElevatedButton.icon(
                  // Disable button if loading or if no text was found
                  onPressed:
                      (_isLoading || _extractedText.isEmpty)
                          ? null
                          : () {
                            // Stop reading before leaving the page
                            _flutterTts.stop();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PrescriptionAnalysisPage(
                                      extractedText: _extractedText,
                                    ),
                              ),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Navigation to New Page ready!'),
                              ),
                            );
                          },
                  icon: const Icon(Icons.auto_awesome, size: 24),
                  label: const Text(
                    'Analyze with AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
