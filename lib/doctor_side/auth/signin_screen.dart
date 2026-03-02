import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maternalhealthcare/doctor_side/auth/auth_service.dart';
import 'package:maternalhealthcare/doctor_side/auth/onboarding_screen.dart';
import 'package:maternalhealthcare/doctor_side/auth/returning_user_login.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final DoctorAuthService _doctorAuthService = DoctorAuthService();

  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _isLoading = false;

  // Avatar Selection State (Doctor Specific)
  int _selectedAvatarIndex = 0;
  final List<String> _avatars = [
    'assets/images/doc_avatar1.png',
    'assets/images/doc_avatar2.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
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

  // --- NEW: Check if doctor already exists BEFORE sending OTP ---
  Future<bool> _doctorExists(String phone) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phoneNumber', isEqualTo: phone)
              .where('role', isEqualTo: 'doctor')
              .limit(1)
              .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking existence: $e");
      return false; // Fail open to allow retry
    }
  }

  Future<void> _verifyDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);

    // Run the existence check first
    final phone = _phoneController.text.trim();
    final exists = await _doctorExists(phone);

    if (exists) {
      _setLoading(false);
      _showMessage(
        'An account with this number already exists. Please use Secure Login.',
        isError: true,
      );
      return;
    }

    try {
      await _doctorAuthService.verifyDoctorAndSendOtp(
        licenseId: _licenseController.text.trim(),
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await _claimAndSignIn(credential: credential);
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
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'An error occurred', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _claimAndSignIn({AuthCredential? credential}) async {
    if (credential == null && _smsCodeController.text.isEmpty) {
      _showMessage('Please enter the OTP.', isError: true);
      return;
    }

    _setLoading(true);

    try {
      final authCredential =
          credential ??
          PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _smsCodeController.text.trim(),
          );

      final userCredential = await _doctorAuthService.signInWithCredential(
        authCredential,
      );

      if (userCredential?.user != null) {
        final user = userCredential!.user!;

        // Create the complete doctor profile in Firestore immediately
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'doctor',
          'fullName': _nameController.text.trim(),
          'name': _nameController.text.trim(), // Added for redundancy
          'licenseId': _licenseController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'avatar': _avatars[_selectedAvatarIndex],
          'createdAt': FieldValue.serverTimestamp(),
          // Note: specialization will be added in the Onboarding screen
        }, SetOptions(merge: true));

        if (mounted) {
          _showMessage('Verification successful!');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DoctorOnboardingScreen()),
            (route) => false,
          );
        }
      } else {
        _showMessage('Sign in failed. Please check the OTP', isError: true);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
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
                        'Doctor Registration',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure your professional profile to manage patient records.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _verificationId == null
                          ? _buildVerificationForm(theme)
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

  /// =========================
  /// VERIFICATION FORM (NEW USER)
  /// =========================
  Widget _buildVerificationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Profile Avatar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),

        // --- UPGRADED: Centered, Large Avatars ---
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarOption(theme, 0),
              const SizedBox(width: 40), // Large gap between the two
              _buildAvatarOption(theme, 1),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Name Input
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: _buildInputDecoration(
            theme,
            'Full Name',
            Icons.person_outline,
          ),
          validator:
              (v) =>
                  v == null || v.trim().isEmpty ? "Name cannot be empty" : null,
        ),
        const SizedBox(height: 16),

        // License Input
        TextFormField(
          controller: _licenseController,
          textCapitalization: TextCapitalization.characters,
          decoration: _buildInputDecoration(
            theme,
            'Medical License ID',
            Icons.badge_outlined,
          ),
          validator:
              (v) =>
                  v == null || v.trim().isEmpty
                      ? "License ID cannot be empty"
                      : null,
        ),
        const SizedBox(height: 16),

        // Phone Input
        TextFormField(
          controller: _phoneController,
          decoration: _buildInputDecoration(
            theme,
            'Phone Number',
            Icons.phone,
          ).copyWith(prefixText: '+91 '),
          keyboardType: TextInputType.phone,
          validator:
              (v) =>
                  v == null || v.trim().isEmpty
                      ? "Phone number cannot be empty"
                      : null,
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _verifyDoctor,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Verify & Send OTP",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 16),

        // Toggle to Returning Doctor Login
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ExistingDoctorLoginScreen(),
              ),
            );
          },
          child: Text(
            "Already registered? Secure Login",
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

  // --- NEW: Helper for individual large avatars ---
  Widget _buildAvatarOption(ThemeData theme, int index) {
    final isSelected = _selectedAvatarIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatarIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 4,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : [],
        ),
        child: CircleAvatar(
          radius: 45, // Significantly larger radius
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          backgroundImage: AssetImage(_avatars[index]),
        ),
      ),
    );
  }

  /// =========================
  /// OTP FORM
  /// =========================
  Widget _buildOtpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "OTP sent to ${_phoneController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _smsCodeController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(
            theme,
            'Enter OTP',
            Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _claimAndSignIn,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Confirm & Register",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _verificationId = null),
          child: Text(
            "Change Details",
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
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
