import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'text_recognition_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  final ImagePicker _picker = ImagePicker();

  bool _isFocusing = false;
  double _focusX = 0.5;
  double _focusY = 0.5;
  bool _isTorchOn = false;

  // Added for a subtle shutter button animation
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..value = 1.0;
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _captureImage(BuildContext context) async {
    if (!_isCameraReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera is not ready yet.')));
      return;
    }

    try {
      _animationController.reverse().then(
        (_) => _animationController.forward(),
      );
      await _initializeControllerFuture;

      final XFile image = await _controller.takePicture();
      print("Image captured at: ${image.path}");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TextRecognitionPage(
                  imagePath: image.path,
                  imageUrl: '',
                  isFromGallery: false,
                ),
          ),
        );
      }
    } catch (e) {
      print("Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      }
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        print("Image selected from gallery: ${image.path}");

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TextRecognitionPage(
                    imagePath: image.path,
                    imageUrl: '',
                    isFromGallery: true,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No image selected.')));
        }
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _onTapToFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (!_isCameraReady || _isFocusing) return;

    _isFocusing = true;

    final double x = details.localPosition.dx / constraints.maxWidth;
    final double y = details.localPosition.dy / constraints.maxHeight;

    setState(() {
      _focusX = x;
      _focusY = y;
    });

    try {
      await _controller.setFocusPoint(Offset(x, y));
      await _controller.setExposurePoint(Offset(x, y));

      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Error setting focus: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFocusing = false;
        });
      }
    }
  }

  Widget _buildFocusIndicator() {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      opacity: _isFocusing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 80,
        width: 80,
        alignment: Alignment(_focusX * 2 - 1, _focusY * 2 - 1),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.secondary, width: 2),
            borderRadius: BorderRadius.circular(
              8,
            ), // Square brackets for scanner feel
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown:
              (TapDownDetails details) => _onTapToFocus(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRect(child: CameraPreview(_controller)),
              ),
              _buildFocusIndicator(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleTorch() async {
    try {
      if (_isCameraReady) {
        final bool currentState =
            _controller.value.flashMode == FlashMode.torch;
        await _controller.setFlashMode(
          currentState ? FlashMode.off : FlashMode.torch,
        );
        if (mounted) {
          setState(() {
            _isTorchOn = !currentState;
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling torch: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to toggle flash')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black, // Keep black behind the camera preview
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _isCameraReady) {
                  return Center(child: _buildCameraPreview());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera initialization failed',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Updated Control Panel
          Container(
            padding: EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery button
                IconButton(
                  onPressed: () => _pickImageFromGallery(context),
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary.withOpacity(
                      0.2,
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                // Capture button
                GestureDetector(
                  onTap: _isCameraReady ? () => _captureImage(context) : null,
                  child: ScaleTransition(
                    scale: _animationController,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isCameraReady
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // Torch button
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color:
                        _isTorchOn ? Colors.amber : theme.colorScheme.primary,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _isTorchOn
                            ? Colors.amber.withOpacity(0.2)
                            : theme.colorScheme.secondary.withOpacity(0.2),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
