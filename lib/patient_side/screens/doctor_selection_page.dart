import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/patient_side/screens/home.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'doctor')
              .get();

      if (mounted) {
        setState(() {
          _doctors =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id; // Store the document ID
                return data;
              }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load available doctors.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndLinkDoctor(String doctorId, String doctorName) async {
    // Show a confirmation dialog before linking
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Selection'),
          content: Text(
            'Would you like to select $doctorName as your primary healthcare provider?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in.");

      // Link the doctor to the patient's profile
      await _firestore.collection('users').doc(user.uid).update({
        'assignedDoctors': FieldValue.arrayUnion([doctorId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Finalize onboarding and go to Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking provider: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Your Provider',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        automaticallyImplyLeading: false, // Prevent going back to OTP
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose Your Doctor',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your primary care physician. This ensures your medical records and appointments are securely shared directly with their clinic.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        _isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                            : _doctors.isEmpty
                            ? _buildEmptyState(theme)
                            : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 8.0,
                              ),
                              itemCount: _doctors.length,
                              itemBuilder: (context, index) {
                                final doctor = _doctors[index];
                                return _buildDoctorCard(theme, doctor);
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSaving)
            Container(
              color: theme.colorScheme.surface.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Securing connection...',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(ThemeData theme, Map<String, dynamic> doctor) {
    final String name =
        doctor['fullName'] ?? doctor['name'] ?? 'Unknown Doctor';
    final String specialization =
        doctor['specialization'] ?? 'General Practitioner';
    final String doctorId = doctor['id'];

    // Fallback to 'Dr.' if name doesn't include it
    final String displayName =
        name.toLowerCase().startsWith('dr') ? name : 'Dr. $name';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => _confirmAndLinkDoctor(doctorId, displayName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.3),
                child: Icon(
                  Icons.medical_services,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialization,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Providers Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are currently no registered doctors in the system. Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchDoctors,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
