import 'package:flutter/material.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';
import 'package:maternalhealthcare/patient_side/screens/babypositiondetection.dart';
import 'package:provider/provider.dart';
// import 'vitals_monitoring_screen.dart'; // Ensure this exists in your project

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the data fetch from the UI when it loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      provider.fetchVitals();
      provider.fetchFetalData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PatientDataProvider>(
      builder: (context, patientData, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Real-Time Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: theme.colorScheme.primary,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                UnifiedCard(
                  title: 'Vitals Monitoring',
                  description:
                      'Track your real-time heart rate, blood pressure, and temperature to ensure maternal stability.',
                  icon: Icons.monitor_heart_outlined,
                  isLoading: patientData.isVitalsLoading,
                  dataWidgets:
                      patientData.vitals
                          .map(
                            (vital) =>
                                DataChip(label: vital.name, value: vital.value),
                          )
                          .toList(),
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const VitalsMonitoringScreen(),
                    //   ),
                    // );
                  },
                  cardType: CardType.monitoring,
                ),
                const SizedBox(height: 16),
                UnifiedCard(
                  title: 'Fetal Monitoring',
                  description:
                      'Keep a close watch on the baby\'s heart rate and movement activity metrics.',
                  icon: Icons.child_care_outlined,
                  isLoading: patientData.isFetalDataLoading,
                  dataWidgets:
                      patientData.fetalData
                          .map(
                            (data) =>
                                DataChip(label: data.name, value: data.value),
                          )
                          .toList(),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Fetal Monitoring Screen not yet implemented.',
                        ),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                  cardType: CardType.monitoring,
                ),
                const SizedBox(height: 16),
                UnifiedCard(
                  title: 'Baby Position Detection',
                  description:
                      'Analyze ultrasound or physical scan data to determine the current orientation and head position of the baby.',
                  icon: Icons.flip_camera_ios_outlined,
                  buttonText: 'Classify Head Position',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BabyHeadClassifier(),
                      ),
                    );
                  },
                  cardType: CardType.action,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Reusable Widgets ---
enum CardType { monitoring, action }

class UnifiedCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final CardType cardType;
  final bool? isLoading;
  final List<Widget>? dataWidgets;
  final String? buttonText;

  const UnifiedCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.cardType,
    this.isLoading,
    this.dataWidgets,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      // Theming is handled by your global CardTheme, but we ensure layout is clean here
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildContent(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (cardType) {
      case CardType.monitoring:
        if (isLoading == true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }
        if (dataWidgets == null || dataWidgets!.isEmpty) {
          return const Text(
            'No data available at the moment.',
            style: TextStyle(
              color: Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        return Wrap(spacing: 8.0, runSpacing: 8.0, children: dataWidgets!);

      case CardType.action:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              buttonText ?? 'Action',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
  }
}

class DataChip extends StatelessWidget {
  final String label;
  final String value;

  const DataChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.15),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
          ),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: Colors.black87.withOpacity(0.7)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
