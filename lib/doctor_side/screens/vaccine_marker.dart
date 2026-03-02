import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineMarkerScreen extends StatefulWidget {
  final String patientId;
  final String patientPhone;

  const VaccineMarkerScreen({
    super.key,
    required this.patientId,
    required this.patientPhone,
  });

  @override
  State<VaccineMarkerScreen> createState() => _VaccineMarkerScreenState();
}

class _VaccineMarkerScreenState extends State<VaccineMarkerScreen> {
  final Set<int> _completedVaccinations = {};
  bool _isLoading = true;

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
      'name': 'Tdap',
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

  @override
  void initState() {
    super.initState();
    _loadFirebaseVaccinations();
  }

  // --- NEW: Load from Firebase ---
  Future<void> _loadFirebaseVaccinations() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patientId)
              .get();

      if (doc.exists && doc.data()!.containsKey('completedVaccinations')) {
        final List<dynamic> savedData = doc.data()!['completedVaccinations'];
        setState(() {
          _completedVaccinations.addAll(savedData.map((e) => e as int));
        });
      }
    } catch (e) {
      debugPrint("Error loading vaccinations: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Save to Firebase ---
  Future<void> _toggleVaccination(int index, bool currentlyCompleted) async {
    // Optimistic UI update
    setState(() {
      if (currentlyCompleted) {
        _completedVaccinations.remove(index);
      } else {
        _completedVaccinations.add(index);
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .set({
            'completedVaccinations': _completedVaccinations.toList(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyCompleted
                  ? 'Vaccine marked as incomplete'
                  : 'Vaccine marked as completed!',
            ),
            backgroundColor: currentlyCompleted ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert if failed
      setState(() {
        if (currentlyCompleted) {
          _completedVaccinations.add(index);
        } else {
          _completedVaccinations.remove(index);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UPGRADED: Dynamic SMS Sender ---
  Future<void> _sendReminderSMS(String vaccineName) async {
    if (widget.patientPhone.isEmpty || widget.patientPhone == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this patient.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String message =
        "Clinic Reminder: It is time for your $vaccineName vaccination. Please contact us to schedule your visit.";
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: widget.patientPhone,
      queryParameters: <String, String>{'body': message},
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
          const SnackBar(
            content: Text('Unable to open SMS app. Check device permissions.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vaccine Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        centerTitle: false,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: vaccinations.length,
                  itemBuilder: (context, index) {
                    final v = vaccinations[index];
                    final isCompleted = _completedVaccinations.contains(index);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              isCompleted
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : theme.colorScheme.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                        ),
                      ),
                      elevation: 0,
                      color:
                          isCompleted
                              ? Colors.green.withValues(alpha: 0.05)
                              : theme.colorScheme.surface,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.secondary.withValues(
                                    alpha: 0.2,
                                  ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : Icons.vaccines_rounded,
                            color:
                                isCompleted
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          '${v['name']} (${v['month']})',
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
                          isCompleted ? 'Completed' : 'Pending Action',
                          style: TextStyle(
                            color:
                                isCompleted
                                    ? Colors.green
                                    : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              top: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildInfoRow('Description', v['description']!),
                                const SizedBox(height: 8),
                                _buildInfoRow('Cause', v['cause']!),
                                const SizedBox(height: 8),
                                _buildInfoRow('Prevention', v['prevention']!),
                                const SizedBox(height: 20),

                                // Action Buttons
                                Row(
                                  children: [
                                    // Remind Button (Only show if not completed)
                                    if (!isCompleted) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              () =>
                                                  _sendReminderSMS(v['name']!),
                                          icon: const Icon(
                                            Icons.sms_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Remind'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.primary,
                                            side: BorderSide(
                                              color: theme.colorScheme.primary,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],

                                    // Toggle Status Button
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _toggleVaccination(
                                              index,
                                              isCompleted,
                                            ),
                                        icon: Icon(
                                          isCompleted
                                              ? Icons.undo_rounded
                                              : Icons.check_rounded,
                                        ),
                                        label: Text(
                                          isCompleted
                                              ? 'Mark as Pending'
                                              : 'Mark as Administered',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isCompleted
                                                  ? Colors.orange.shade50
                                                  : Colors.green,
                                          foregroundColor:
                                              isCompleted
                                                  ? Colors.orange.shade800
                                                  : Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildInfoRow(String title, String content) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}
