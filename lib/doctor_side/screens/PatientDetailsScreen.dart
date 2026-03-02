import 'package:flutter/material.dart';
import 'package:maternalhealthcare/doctor_side/screens/vaccine_marker.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientDetailScreen extends StatelessWidget {
  final dynamic patient;

  const PatientDetailScreen({super.key, required this.patient});

  // --- Opens the common Google Drive link ---
  Future<void> _openGoogleDrive(BuildContext context) async {
    const String driveUrl =
        'https://drive.google.com/drive/folders/1pYqLCPpm0uLf7f4awI9KAdiMpBKmlK6i?usp=drive_link';
    final Uri url = Uri.parse(driveUrl);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Could not launch Google Drive. Please check the link.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error opening drive: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to open documents folder."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleVaccineMarking(BuildContext context) {
    // 1. Extract the ID safely
    String patientId = 'unknown_patient';
    try {
      patientId = patient.id ?? 'unknown_patient';
    } catch (_) {
      if (patient is Map && patient.containsKey('id')) {
        patientId = patient['id'];
      }
    }

    // 2. Extract the phone number safely
    String phoneNumber = 'N/A';
    try {
      phoneNumber = patient.phoneNumber ?? 'N/A';
    } catch (_) {
      if (patient is Map && patient.containsKey('phoneNumber')) {
        phoneNumber = patient['phoneNumber'];
      }
    }

    // 3. Navigate with the required data!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VaccineMarkerScreen(
              patientId: patientId,
              patientPhone: phoneNumber,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safely extract ALL properties, including the new vitals
    String patientName = 'Unknown Patient';
    String phoneNumber = 'N/A';
    String? avatarPath;
    String dateOfBirth = 'Not Provided';
    String weightKg = '--';

    try {
      patientName = patient.fullName ?? patient.name ?? 'Unknown Patient';
      phoneNumber = patient.phoneNumber ?? 'N/A';
      avatarPath = patient.avatar;
      dateOfBirth = patient.dateOfBirth ?? 'Not Provided';
      weightKg = patient.weightKg ?? '--';
    } catch (_) {
      if (patient is Map) {
        patientName =
            patient['fullName'] ?? patient['name'] ?? 'Unknown Patient';
        phoneNumber = patient['phoneNumber'] ?? 'N/A';
        avatarPath = patient['avatar'];
        dateOfBirth = patient['dateOfBirth'] ?? 'Not Provided';
        weightKg = patient['weightKg']?.toString() ?? '--';
      } else {
        patientName = patient.toString();
      }
    }

    final String initial =
        patientName.isNotEmpty && patientName != 'Unknown Patient'
            ? patientName[0].toUpperCase()
            : '?';

    final bool hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Record',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Patient Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.secondary
                              .withValues(alpha: 0.2),
                          backgroundImage:
                              hasAvatar ? AssetImage(avatarPath!) : null,
                          child:
                              !hasAvatar
                                  ? Text(
                                    initial,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phoneNumber,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Active Patient',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- NEW: Patient Vitals Section ---
                Row(
                  children: [
                    Expanded(
                      child: _buildVitalCard(
                        theme,
                        'Date of Birth',
                        dateOfBirth,
                        Icons.cake_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildVitalCard(
                        theme,
                        'Weight',
                        weightKg == '--' || weightKg.isEmpty
                            ? 'Not logged'
                            : '$weightKg kg',
                        Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                Text(
                  'Clinical Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Access Shared Drive Card
                _buildActionCard(
                  theme: theme,
                  title: 'Patient Documents',
                  subtitle:
                      'Access the shared Google Drive database to view or upload prescriptions and ultrasound reports.',
                  icon: Icons.add_to_drive_rounded,
                  isHighlighted: true,
                  onTap: () => _openGoogleDrive(context),
                ),
                const SizedBox(height: 16),

                // Vaccine Marker Card
                _buildActionCard(
                  theme: theme,
                  title: 'Vaccine Marker',
                  subtitle:
                      'Update and monitor the patient\'s maternal immunization schedule stored in Firebase.',
                  icon: Icons.vaccines_rounded,
                  onTap: () => _handleVaccineMarking(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Helper widget for the Vitals row ---
  Widget _buildVitalCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper widget for premium action cards
  Widget _buildActionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Card(
      elevation: isHighlighted ? 4 : 0,
      shadowColor:
          isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isHighlighted
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.secondary.withValues(alpha: 0.5),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      color:
          isHighlighted
              ? theme.colorScheme.surface
              : theme.colorScheme.secondary.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
