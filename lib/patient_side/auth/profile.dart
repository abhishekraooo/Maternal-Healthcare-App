import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/patient_side/auth/auth_service.dart';
import 'package:maternalhealthcare/patient_side/provider/profile_provider.dart';
import 'package:maternalhealthcare/patient_side/screens/doctor_selection_page.dart'; // Import this to allow changing doctors
import 'package:maternalhealthcare/utils/role_selection.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).fetchPatientProfile();
    });
  }

  // --- NEW: Edit Profile Bottom Sheet ---
  void _showEditProfileSheet(
    BuildContext context,
    PatientProfile currentProfile,
  ) {
    final theme = Theme.of(context);
    final _formKey = GlobalKey<FormState>();

    // Pre-fill existing data
    final _nameController = TextEditingController(
      text:
          currentProfile.fullName != 'No Name Provided'
              ? currentProfile.fullName
              : '',
    );
    final _weightController = TextEditingController(
      text: currentProfile.weightKg.replaceAll(' kg', '').replaceAll('--', ''),
    );
    DateTime? _selectedDate;

    // Try to parse existing DOB string to Date to set initial picker date
    try {
      if (currentProfile.dateOfBirth != 'Not Provided') {
        final parts = currentProfile.dateOfBirth.split('-');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Edit Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

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
                            (v) => v!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Weight Input
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _buildInputDecoration(
                          theme,
                          'Weight (in kg)',
                          Icons.monitor_weight_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DOB Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => _selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _buildInputDecoration(
                            theme,
                            'Date of Birth',
                            Icons.cake_outlined,
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color:
                                  _selectedDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _saveProfileUpdates(
                              name: _nameController.text.trim(),
                              weight: _weightController.text.trim(),
                              dob: _selectedDate,
                            );
                            if (context.mounted)
                              Navigator.pop(context); // Close sheet
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- NEW: Function to save updates to Firebase ---
  Future<void> _saveProfileUpdates({
    required String name,
    required String weight,
    DateTime? dob,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> updates = {
        'name': name,
        'fullName': name, // Keep both in sync just in case
        'weightKg': weight,
      };

      if (dob != null) {
        updates['dateOfBirth'] =
            "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the UI with new data
        Provider.of<ProfileProvider>(
          context,
          listen: false,
        ).fetchPatientProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Input decoration helper for the bottom sheet
  InputDecoration _buildInputDecoration(
    ThemeData theme,
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  Future<void> _showSignOutConfirmationDialog(ThemeData theme) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Sign Out',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to securely sign out of your account?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sign out failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        centerTitle: false,
        actions: [
          // --- NEW: Edit Button in AppBar ---
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.patientProfile == null)
                return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Edit Profile',
                onPressed:
                    () => _showEditProfileSheet(
                      context,
                      provider.patientProfile!,
                    ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            );
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchPatientProfile(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (provider.patientProfile == null) {
            return const Center(child: Text('No profile data available.'));
          }

          final profile = provider.patientProfile!;
          final hasAvatar = profile.avatar.isNotEmpty;

          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => provider.fetchPatientProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: theme.colorScheme.secondary
                                      .withValues(alpha: 0.2),
                                  backgroundImage:
                                      hasAvatar
                                          ? AssetImage(profile.avatar)
                                          : null,
                                  child:
                                      !hasAvatar
                                          ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: theme.colorScheme.primary,
                                          )
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                profile.fullName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  profile.phoneNumber,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildSectionHeader(theme, 'Personal Information'),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          theme: theme,
                          children: [
                            _buildInfoTile(
                              theme,
                              'Date of Birth',
                              profile.dateOfBirth,
                              Icons.cake_outlined,
                            ),
                            const Divider(height: 1, indent: 60),
                            _buildInfoTile(
                              theme,
                              'Weight',
                              profile.weightKg.isEmpty ||
                                      profile.weightKg == '--'
                                  ? 'Not recorded'
                                  : '${profile.weightKg} kg',
                              Icons.monitor_weight_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(theme, 'Medical Care'),
                            // --- NEW: Allow patient to change their assigned doctor ---
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const DoctorSelectionScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Change Provider',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildInfoCard(
                          theme: theme,
                          children: [
                            _buildInfoTile(
                              theme,
                              'Primary Care Physician',
                              profile.doctorName,
                              Icons.medical_services_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Sign Out Securely',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed:
                              () => _showSignOutConfirmationDialog(theme),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
