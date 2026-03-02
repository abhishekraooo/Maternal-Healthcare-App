import 'package:flutter/material.dart';
import 'package:maternalhealthcare/doctor_side/provider/doctor_provider.dart';
import 'package:maternalhealthcare/doctor_side/screens/PatientDetailsScreen.dart';
import 'package:maternalhealthcare/doctor_side/widgets/patient_card.dart';
import 'package:provider/provider.dart';

class PatientsDashboardScreen extends StatefulWidget {
  const PatientsDashboardScreen({super.key});

  @override
  State<PatientsDashboardScreen> createState() =>
      _PatientsDashboardScreenState();
}

class _PatientsDashboardScreenState extends State<PatientsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the fetch for the list of patients when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorDataProvider>(context, listen: false).fetchPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic column count for tablet vs phone responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Consumer<DoctorDataProvider>(
        builder: (context, doctorData, child) {
          if (doctorData.isLoadingPatients) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            );
          }

          // Premium Empty State if no patients exist
          if (doctorData.patients.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Patients Found',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'When patients select you as their primary care physician during onboarding, they will automatically appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => doctorData.fetchPatients(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Dashboard'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Main Responsive Grid
          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => doctorData.fetchPatients(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ), // Max width for ultrawide screens
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: doctorData.patients.length,
                  itemBuilder: (context, index) {
                    final patient = doctorData.patients[index];
                    return PatientCard(
                      patientName: patient.fullName,
                      // Pass avatar if your PatientCard supports it!
                      avatarPath: patient.avatar,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PatientDetailScreen(patient: patient),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
