import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/doctor_side/auth/signin_screen.dart';
import 'package:maternalhealthcare/patient_side/auth/auth_service.dart';
import 'package:maternalhealthcare/doctor_side/screens/doctor_home.dart';

class ExistingDoctorLoginScreen extends StatefulWidget {
  const ExistingDoctorLoginScreen({super.key});

  @override
  State<ExistingDoctorLoginScreen> createState() =>
      _ExistingDoctorLoginScreenState();
}

class _ExistingDoctorLoginScreenState extends State<ExistingDoctorLoginScreen> {
  // NOTE: We use the main AuthService because an existing doctor is just a regular user
  // in our system.
  final AuthService _authService = AuthService();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade400 : theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (credential) async {
          // Handle auto-verification if it occurs
          final userCredential = await _authService.signInWithCredential(
            credential,
          );
          if (userCredential == null) {
            _showMessage('Auto-verification failed.', isError: true);
          } else {
            await _checkDoctorProfileAndRoute();
          }
        },
        verificationFailed: (e) {
          _showMessage(e.message ?? 'Verification failed', isError: true);
        },
        codeSent: (verificationId, resendToken) {
          setState(() => _verificationId = verificationId);
          _showMessage('OTP sent successfully!');
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      _showMessage('An error occurred: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _verifyAndSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );
      final userCredential = await _authService.signInWithCredential(
        credential,
      );

      if (userCredential == null) {
        _showMessage('Sign in failed. Please check the OTP.', isError: true);
        _setLoading(false);
        return;
      }

      await _checkDoctorProfileAndRoute();
    } catch (e) {
      _showMessage('Verification failed: ${e.toString()}', isError: true);
      _setLoading(false);
    }
  }

  // --- NEW: Security Check to Ensure they are actually a Doctor ---
  Future<void> _checkDoctorProfileAndRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data()?['role'] == 'doctor') {
          _showMessage('Welcome back, doctor!');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
              (route) => false,
            );
          }
        } else {
          // If they aren't a doctor, boot them out immediately.
          await FirebaseAuth.instance.signOut();
          _showMessage(
            'No provider account found for this number.',
            isError: true,
          );

          if (mounted) {
            setState(() {
              _verificationId = null;
              _isLoading = false;
            });
            // Auto-route them to the Doctor Sign-Up screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DoctorLoginScreen()),
            );
          }
        }
      }
    } catch (e) {
      _showMessage('Failed to verify profile: $e', isError: true);
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access your doctor dashboard',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _verificationId == null
                          ? _buildPhoneForm(theme)
                          : _buildOtpForm(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: _buildInputDecoration(theme, 'Phone Number', Icons.phone),
          keyboardType: TextInputType.phone,

          onTap: () {
            if (_phoneController.text.isEmpty) {
              _phoneController.text = "+911234567891";

              // move cursor to end
              _phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _phoneController.text.length),
              );
            }
          },

          validator: (v) => v!.isEmpty ? 'Phone number cannot be empty' : null,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _sendOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Send OTP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        // --- NEW: Toggle to New Provider Screen ---
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorLoginScreen(),
              ),
            );
          },
          child: Text(
            "New provider? Register here",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'An OTP has been sent to\n${_phoneController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _smsCodeController,
          decoration: _buildInputDecoration(
            theme,
            '6-digit OTP',
            Icons.lock_outline,
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,

          onTap: () {
            if (_smsCodeController.text.isEmpty) {
              _smsCodeController.text = "000000";

              // move cursor to end
              _smsCodeController.selection = TextSelection.fromPosition(
                TextPosition(offset: _smsCodeController.text.length),
              );
            }
          },

          validator:
              (v) =>
                  v!.isEmpty || v.length < 6
                      ? 'Please enter the 6-digit OTP'
                      : null,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _verifyAndSignIn,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Confirm & Sign In',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _verificationId = null),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            'Change Number?',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Helper for consistent Input Decoration
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
