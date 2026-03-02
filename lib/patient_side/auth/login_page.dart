import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/patient_side/auth/PatientReturningLoginScreen.dart';
import 'package:maternalhealthcare/patient_side/auth/auth_service.dart';
import 'package:maternalhealthcare/patient_side/screens/doctor_selection_page.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _isLoading = false;
  bool _isPhoneValid = false;

  // Avatar Selection State
  int _selectedAvatarIndex = 0;
  final List<String> _avatars = [
    'assets/images/avatar1.png',
    'assets/images/avatar2.png',
    'assets/images/avatar3.png',
    'assets/images/avatar4.png',
    'assets/images/avatar5.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
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
              await _saveProfileAndContinue();
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
        await _saveProfileAndContinue();
      } else {
        _showMessage('Invalid OTP. Please try again.', isError: true);
        _setLoading(false);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
      _setLoading(false);
    }
  }

  Future<void> _saveProfileAndContinue() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save initial patient profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'patient',
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'avatar': _avatars[_selectedAvatarIndex],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showMessage('Sign in successful!');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DoctorSelectionScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _showMessage('Failed to save profile: $e', isError: true);
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
                        Icons.pregnant_woman_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Patient Profile',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your details to securely connect with your healthcare provider.',
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
              color: theme.colorScheme.surface.withOpacity(0.8),
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
          // Avatar Selection Section
          Text(
            'Choose your Avatar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                              : [],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.2,
                      ),
                      backgroundImage: AssetImage(_avatars[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Name Input
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(
                Icons.person_outline,
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
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Please enter your name'
                        : null,
          ),
          const SizedBox(height: 16),

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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a phone number';
              }
              if (!_validatePhone(value)) {
                return 'Please enter a valid Indian phone number (+91...)';
              }
              return null;
            },
            onChanged:
                (value) =>
                    setState(() => _isPhoneValid = _validatePhone(value)),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed:
                _isPhoneValid && _nameController.text.isNotEmpty
                    ? _sendOtp
                    : null,
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

          // TOGGLE TO RETURNING LOGIN
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientReturningLoginScreen(),
                ),
              );
            },
            child: Text(
              'Already a patient? Log in here',
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
              hintText: '6-digit code',
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
              'Verify & Secure Login',
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
