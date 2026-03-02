import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VaccinationPage extends StatefulWidget {
  const VaccinationPage({super.key});

  @override
  State<VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<Map<String, String>> vaccinations = [
    {
      'month': 'Month 1',
      'name': 'Hepatitis B (1st dose)',
      'description': 'Prevents mother-to-child transmission of Hepatitis B.',
      'cause': 'Caused by Hepatitis B virus (HBV).',
      'prevention': 'Vaccination, avoiding contact with infected blood.',
    },
    {
      'month': 'Month 2',
      'name': 'Hepatitis B (2nd dose)',
      'description': 'Second dose ensures continued protection.',
      'cause': 'Caused by Hepatitis B virus (HBV).',
      'prevention': 'Timely immunization and hygiene.',
    },
    {
      'month': 'Month 3',
      'name': 'Influenza (Flu)',
      'description': 'Protects pregnant women from seasonal flu.',
      'cause': 'Influenza virus, airborne and contagious.',
      'prevention': 'Annual vaccination, mask use, and hygiene.',
    },
    {
      'month': 'Month 4',
      'name': 'Pneumococcal Vaccine',
      'description': 'Protects against pneumonia and meningitis.',
      'cause': 'Streptococcus pneumoniae bacteria.',
      'prevention': 'Vaccination and avoiding respiratory infections.',
    },
    {
      'month': 'Month 5',
      'name': 'Meningococcal Vaccine',
      'description': 'Prevents meningitis and bloodstream infections.',
      'cause': 'Neisseria meningitidis bacteria.',
      'prevention': 'Vaccination, avoid sharing utensils, good hygiene.',
    },
    {
      'month': 'Month 6',
      'name': 'Tdap (Tetanus, Diphtheria, Pertussis)',
      'description':
          'Protects mother and baby from tetanus, diphtheria, and whooping cough.',
      'cause': 'Bacterial infections transmitted via wounds or air.',
      'prevention': 'Vaccination during every pregnancy.',
    },
    {
      'month': 'Month 7',
      'name': 'Influenza (2nd dose)',
      'description': 'Boosts flu protection in the later pregnancy stage.',
      'cause': 'Influenza virus.',
      'prevention': 'Booster flu shot, avoid sick individuals.',
    },
    {
      'month': 'Month 8',
      'name': 'Hepatitis A',
      'description':
          'Prevents foodborne liver infections especially in regions with poor sanitation.',
      'cause': 'Hepatitis A virus.',
      'prevention': 'Vaccination, safe food, and clean water.',
    },
    {
      'month': 'Month 9',
      'name': 'Hepatitis B (3rd dose)',
      'description':
          'Final dose ensures complete immunity against Hepatitis B.',
      'cause': 'Hepatitis B virus.',
      'prevention': 'Complete 3-dose vaccine series.',
    },
  ];

  // Opens SMS app so the patient can text a family member or themselves a reminder
  void sendSMS(BuildContext context, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      // Leaving path empty opens the default SMS app to let the user pick the contact
      path: '',
      queryParameters: {'body': message},
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'Could not launch SMS app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open SMS app.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your records.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Vaccine Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          // StreamBuilder listens to Firestore and updates the UI instantly if the doctor makes a change
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading records."));
              }

              // Extract the completed vaccines from the Firestore document safely
              Set<int> completedVaccinations = {};
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                if (data.containsKey('completedVaccinations')) {
                  final List<dynamic> savedData = data['completedVaccinations'];
                  completedVaccinations.addAll(savedData.map((e) => e as int));
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: vaccinations.length,
                itemBuilder: (context, index) {
                  final v = vaccinations[index];
                  final isCompleted = completedVaccinations.contains(index);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            isCompleted
                                ? Colors.green.withValues(alpha: 0.4)
                                : theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                        width: isCompleted ? 2 : 1,
                      ),
                    ),
                    elevation: 0,
                    color:
                        isCompleted
                            ? Colors.green.withValues(alpha: 0.05)
                            : theme.colorScheme.surface,
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        // Read-only indicator for the patient
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : Icons.vaccines_outlined,
                            color:
                                isCompleted
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          v['name']!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isCompleted
                                    ? Colors.green.shade700
                                    : theme.colorScheme.primary,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          isCompleted
                              ? 'Administered by Provider'
                              : v['month']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isCompleted
                                    ? Colors.green.shade600
                                    : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildInfoRow(
                                  theme,
                                  "Description",
                                  v['description']!,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(theme, "Cause", v['cause']!),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  theme,
                                  "Prevention",
                                  v['prevention']!,
                                ),

                                // Only show the reminder button if it is NOT completed yet
                                if (!isCompleted) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final msg =
                                          'Health Reminder: It is time to schedule the ${v['name']} vaccination (${v['month']}).';
                                      sendSMS(context, msg);
                                    },
                                    icon: const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Draft SMS Reminder',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.3),
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
