import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maternalhealthcare/patient_side/screens/take_appointment.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  // Common Google Drive link for all documents
  final String _googleDriveLink =
      'https://drive.google.com/drive/folders/1pYqLCPpm0uLf7f4awI9KAdiMpBKmlK6i?usp=sharing';

  // Helper to launch any URL (Drive or Phone)
  Future<void> _launchURL(String urlString, {bool isPhone = false}) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode:
              isPhone
                  ? LaunchMode.externalApplication
                  : LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: Unable to open link.')));
      }
    }
  }

  // --- Dynamic: Fetch Assigned Doctor's Number ---
  Future<void> _contactAssignedDoctor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Get the patient's document
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data()!.containsKey('assignedDoctors')) {
        final List assignedList = userDoc.data()!['assignedDoctors'];
        if (assignedList.isNotEmpty) {
          final doctorId = assignedList.first;

          // 2. Get the doctor's phone number from their document
          final docSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(doctorId)
                  .get();
          final phoneNumber = docSnapshot.data()?['phoneNumber'];

          if (phoneNumber != null) {
            _launchURL('tel:$phoneNumber', isPhone: true);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assigned doctor found with a valid number.'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error contacting doctor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Records are synced with your Primary Physician.',
                  ),
                ),
              );
            },
            icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
        ],
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
                Text(
                  'Shared Database',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Link to Google Drive Reports
                _buildRecordButton(
                  theme: theme,
                  title: 'View Clinical Reports',
                  subtitle: 'Ultrasounds, Blood Tests, Scans',
                  icon: Icons.folder_shared_rounded,
                  onTap: () => _launchURL(_googleDriveLink),
                ),
                const SizedBox(height: 16),

                // Link to Google Drive Prescriptions
                _buildRecordButton(
                  theme: theme,
                  title: 'View Prescriptions',
                  subtitle: 'Current and past medical advice',
                  icon: Icons.medication_liquid_rounded,
                  onTap: () => _launchURL(_googleDriveLink),
                ),
                const SizedBox(height: 16),

                _buildRecordButton(
                  theme: theme,
                  title: 'Vitals & Fetal History',
                  subtitle: 'Recorded during clinic visits',
                  icon: Icons.favorite_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vitals dashboard coming in next update.',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ActionTile(
                        title: 'Contact\nPhysician',
                        icon: Icons.phone_in_talk_rounded,
                        onTap:
                            _contactAssignedDoctor, // Calls the dynamic fetcher
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ActionTile(
                        title: 'Book\nAppointment',
                        icon: Icons.calendar_today_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TakeAppointmentPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
