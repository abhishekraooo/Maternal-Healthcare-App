import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class BabyHeadClassifier extends StatefulWidget {
  const BabyHeadClassifier({super.key});

  @override
  State<BabyHeadClassifier> createState() => _BabyHeadClassifierState();
}

class _BabyHeadClassifierState extends State<BabyHeadClassifier> {
  Interpreter? _interpreter;
  File? _image;
  // UPDATE: Removed "AI"
  String _status = "Initializing ML Model...";
  bool _isAnalyzing = false;
  bool _isModelReady = false;

  final ImagePicker _picker = ImagePicker();
  List<String> _labels = ["Ideal Position", "Breech Position"];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_unquant.tflite',
      );
      _labels = await _loadLabels('assets/labels/labels.txt');
      if (mounted) {
        setState(() {
          _isModelReady = true;
          _status = "Model Ready. Please upload an ultrasound.";
        });
      }
    } catch (e) {
      debugPrint("Error loading model: $e");
      if (mounted) {
        setState(() {
          // UPDATE: Removed "AI"
          _status = "Failed to load ML model. Please restart.";
        });
      }
    }
  }

  Future<List<String>> _loadLabels(String path) async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString(path);
      return data.split('\n').map((e) => e.trim()).toList();
    } catch (e) {
      debugPrint("Error loading labels: $e");
      return ["Ideal Position", "Breech Position", "Unknown"];
    }
  }

  Future<void> _pickImage() async {
    if (!_isModelReady) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isAnalyzing = true;
        _status = "Analyzing ultrasound scan...";
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _runModel(_image!);
    }
  }

  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Cannot decode image");

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];

    final resized = img.copyResize(
      image,
      width: inputWidth,
      height: inputHeight,
    );
    final imageBytes = resized.getBytes();

    return [
      List.generate(inputHeight, (y) {
        return List.generate(inputWidth, (x) {
          int baseIndex = (y * resized.width + x) * 4;
          if (baseIndex + 2 >= imageBytes.length) {
            return [0.0, 0.0, 0.0];
          }
          return [
            imageBytes[baseIndex] / 255.0,
            imageBytes[baseIndex + 1] / 255.0,
            imageBytes[baseIndex + 2] / 255.0,
          ];
        });
      }),
    ];
  }

  Future<void> _runModel(File image) async {
    if (_interpreter == null) return;

    try {
      final input = _preprocessImage(image);
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.generate(
        outputShape[0],
        (_) => List.generate(outputShape[1], (_) => 0.0),
      );

      _interpreter!.run(input, output);

      int predictedIndex = 0;
      double maxVal = output[0][0];
      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > maxVal) {
          maxVal = output[0][i];
          predictedIndex = i;
        }
      }

      setState(() {
        _isAnalyzing = false;
        _status = "Analysis complete.";
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultPage(
                  prediction: _labels[predictedIndex],
                  confidence: maxVal,
                  imageFile: image,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error running model: $e");
      setState(() {
        _isAnalyzing = false;
        _status = "Error analyzing image. Please try another.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fetal Presentation Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Educational Summary Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'About this Tool',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // UPDATE: Replaced "AI" with "Machine Learning model" and specified TensorFlow Lite
                      Text(
                        'This Machine Learning tool analyzes ultrasound scans to detect fetal presentation. Powered by a TensorFlow Lite model, it classifies the position as either "Ideal" (Cephalic/head-down) or "Breech" (feet/buttocks-down).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // UPDATE: Added accuracy disclaimer
                      Text(
                        'Disclaimer: This model is not 100% accurate and should only be used as an assistive tool. It is not a substitute for professional medical advice. Always consult your primary care physician for an official medical diagnosis.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- Upload Area ---
                GestureDetector(
                  onTap: _isAnalyzing ? null : _pickImage,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _isAnalyzing
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary.withValues(
                                  alpha: 0.5,
                                ),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        _isAnalyzing
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Analyzing Image...",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                            : _image != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 64,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Tap to upload Ultrasound",
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Status Text ---
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Action Button ---
                ElevatedButton.icon(
                  onPressed: _isAnalyzing || !_isModelReady ? null : _pickImage,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text(
                    'Select from Gallery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// RESULT PAGE
// ==========================================

class ResultPage extends StatelessWidget {
  final String prediction;
  final double confidence;
  final File imageFile;

  const ResultPage({
    super.key,
    required this.prediction,
    required this.confidence,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isIdeal = prediction.toLowerCase().contains("ideal");

    final Color statusColor =
        isIdeal ? Colors.green.shade600 : Colors.orange.shade700;
    final IconData statusIcon =
        isIdeal
            ? Icons.check_circle_outline_rounded
            : Icons.warning_amber_rounded;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Thumbnail
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),

                // Result Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(statusIcon, size: 64, color: statusColor),
                      const SizedBox(height: 16),
                      Text(
                        prediction.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // UPDATE: Changed "AI Confidence" to "Model Confidence"
                      Text(
                        "Model Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: statusColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Medical Context
                Text(
                  'Clinical Context',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isIdeal
                          ? 'The ultrasound indicates a Cephalic (head-down) presentation. This is the optimal position for a safe vaginal delivery. Continue routine check-ups.'
                          : 'The ultrasound indicates a Breech presentation. While common earlier in pregnancy, if this persists into the third trimester, your physician may discuss options such as External Cephalic Version (ECV) or scheduling a cesarean delivery.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Analyze Another Scan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
