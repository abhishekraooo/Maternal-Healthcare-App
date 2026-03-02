import 'package:flutter/material.dart';
import 'package:maternalhealthcare/patient_side/auth/profile.dart';
import 'package:maternalhealthcare/doc_prescription/first_page.dart';
import 'package:maternalhealthcare/patient_side/screens/chatbot.dart';
import 'package:maternalhealthcare/patient_side/screens/govt_schemes.dart';
import 'package:maternalhealthcare/patient_side/screens/lib_and_relax.dart';
import 'package:maternalhealthcare/patient_side/screens/sos.dart';
import 'diet_screen.dart';
import 'vaccination_screen.dart';
// import '../widgets/feature_button.dart'; // We won't need the old one anymore
import 'package:maternalhealthcare/patient_side/screens/duedate.dart';
import 'package:maternalhealthcare/patient_side/screens/ovulation.dart';

class FeaturesDashboardScreen extends StatelessWidget {
  const FeaturesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate grid cross-axis count based on screen width for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Features',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            tooltip: 'Manage Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // The main Grid layout
          GridView.count(
            crossAxisCount: crossAxisCount,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom:
                  120.0, // Extra padding so the floating buttons don't cover the bottom row
            ),
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio:
                0.9, // Slightly taller than wide to fit the text comfortably
            children: [
              _FeatureTile(
                title: 'Diet & Exercise',
                imagePath: 'assets/images/diet_exercise.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientDietScreen(),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'Due Date',
                imagePath: 'assets/images/duedate.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DueDateCalculator(),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'Vaccinations',
                imagePath: 'assets/images/vaccination.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaccinationPage(),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'Cycle Tracker',
                imagePath: 'assets/images/ovulation.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OvulationCalculatorPage(),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'Govt Schemes',
                imagePath: 'assets/images/government.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GovtSchemes(),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'Prescriptions',
                imagePath: 'assets/images/prescription.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
              _FeatureTile(
                title: 'Library & Relax',
                imagePath: 'assets/images/library.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Fixed Bottom Actions (SOS & Chatbot)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24, // Lifted slightly off the bottom edge
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: _FloatingActionButton(
                      icon: Icons.sos_rounded,
                      label: 'Emergency SOS',
                      color:
                          Colors
                              .red
                              .shade400, // Kept red for universal emergency recognition
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Sos()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FloatingActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Ask AI',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MedicalChatbotPage(),
                          ),
                        );
                      },
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
}

// --- Custom Grid Tile Widget ---
class _FeatureTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          20,
        ), // More organic, rounded corners
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Assuming your assets are PNGs with transparent backgrounds.
                    // Using secondary color to give a soft highlight behind the image.
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Custom Bottom Action Buttons ---
class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
