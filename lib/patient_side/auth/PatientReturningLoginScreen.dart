import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/patient_side/auth/auth_service.dart';
import 'package:maternalhealthcare/patient_side/screens/home.dart';
import 'login_page.dart'; // Ensure this points to PatientLoginScreen

class PatientReturningLoginScreen extends StatefulWidget {
  const PatientReturningLoginScreen({super.key});

  @override
  State<PatientReturningLoginScreen> createState() =>
      _PatientReturningLoginScreenState();
}

class _PatientReturningLoginScreenState
    extends State<PatientReturningLoginScreen> {
  final AuthService _authService = AuthService();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _isLoading = false;
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError
                  ? Colors.red.shade400
                  : Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _validatePhone(String phone) {
    final RegExp phoneRegex = RegExp(r'^\+91[1-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (credential) async {
          try {
            final result = await _authService.signInWithCredential(credential);
            if (result != null && mounted) {
              await _checkProfileAndRoute();
            }
          } catch (e) {
            _showMessage('Auto-verification failed: $e', isError: true);
          }
        },
        verificationFailed: (e) {
          _showMessage(e.message ?? 'Verification failed', isError: true);
        },
        codeSent: (verificationId, resendToken) {
          setState(() => _verificationId = verificationId);
          _showMessage('OTP sent successfully!');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _showMessage('OTP timeout. Please try again.', isError: true);
        },
      );
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _verifyAndSignIn() async {
    if (_smsCodeController.text.length != 6) {
      _showMessage('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    _setLoading(true);
    try {
      final result = await _authService.signInWithSmsCode(
        _verificationId!,
        _smsCodeController.text,
      );

      if (result != null) {
        await _checkProfileAndRoute();
      } else {
        _showMessage('Invalid OTP. Please try again.', isError: true);
        _setLoading(false);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
      _setLoading(false);
    }
  }

  Future<void> _checkProfileAndRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if the user actually has a profile in Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data()?['role'] == 'patient') {
          _showMessage('Welcome back!');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const PatientHomeScreen(),
              ),
              (route) => false,
            );
          }
        } else {
          // If they don't exist, log them out and tell them to sign up
          await FirebaseAuth.instance.signOut();
          _showMessage(
            'Account not found. Please sign up as a new patient.',
            isError: true,
          );

          if (mounted) {
            setState(() {
              _verificationId = null;
              _isLoading = false;
            });
            // Auto-route them to the Sign-Up screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
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
                        'Sign in to access your health records and upcoming appointments.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildPhoneAuthForm(theme),
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

  Widget _buildPhoneAuthForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_verificationId == null) ...[
          // Phone Input
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
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
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.phone,

            onTap: () {
              if (_phoneController.text.isEmpty) {
                setState(() {
                  _phoneController.text = "+911234567890";

                  _phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _phoneController.text.length),
                  );

                  // 🔥 THIS IS THE IMPORTANT FIX
                  _isPhoneValid = _validatePhone(_phoneController.text);
                });
              }
            },

            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter a phone number';
              if (!_validatePhone(value))
                return 'Please enter a valid Indian phone number (+91...)';
              return null;
            },

            onChanged:
                (value) =>
                    setState(() => _isPhoneValid = _validatePhone(value)),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isPhoneValid ? _sendOtp : null,
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

          const SizedBox(height: 16), // ADDED PADDING
          // ADDED TOGGLE BUTTON TO NEW USER SCREEN
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientLoginScreen(),
                ),
              );
            },
            child: Text(
              'New patient? Create an account',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ] else ...[
          // OTP Input
          TextFormField(
            controller: _smsCodeController,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.primary,
              ),
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
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
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
              'Secure Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _verificationId = null),
            child: Text(
              'Change Number?',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ],
    );
  }
}
