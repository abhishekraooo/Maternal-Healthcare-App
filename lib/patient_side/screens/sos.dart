import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Sos extends StatelessWidget {
  const Sos({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary, // Adheres to global theme
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
                // Hero Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emergency_outlined,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Immediate Assistance',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the buttons below to instantly connect to emergency medical services or request urgent blood supply.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // Primary Action: Call Ambulance
                _buildEmergencyCard(
                  title: 'Call Ambulance',
                  subtitle: 'Direct line to emergency medical transport',
                  icon: Icons.local_hospital_rounded,
                  color: Colors.red.shade600,
                  onTap: () => _callAmbulance(context),
                ),
                const SizedBox(height: 16),

                // Secondary Action: Blood Bank
                _buildEmergencyCard(
                  title: 'Contact Blood Bank',
                  subtitle: 'Send an urgent WhatsApp request for blood',
                  icon: Icons.bloodtype_rounded,
                  color: Colors.red.shade900,
                  onTap: () => _showBloodGroupDialog(context),
                ),
                const SizedBox(height: 48),

                // Informative Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'When to call an ambulance?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWarningSign(
                        theme,
                        'Severe or persistent abdominal pain',
                      ),
                      _buildWarningSign(theme, 'Heavy vaginal bleeding'),
                      _buildWarningSign(
                        theme,
                        'Sudden gush of fluid (water breaking early)',
                      ),
                      _buildWarningSign(
                        theme,
                        'Difficulty breathing or chest pain',
                      ),
                      _buildWarningSign(
                        theme,
                        'Severe dizziness, fainting, or blurred vision',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningSign(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to call the predefined ambulance number
  Future<void> _callAmbulance(BuildContext context) async {
    const String ambulanceNumber = '+917892942557';
    final Uri url = Uri(scheme: 'tel', path: ambulanceNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone dialer.')),
        );
      }
    }
  }

  // Redesigned Blood Group Dialog using a Grid instead of a Dropdown
  void _showBloodGroupDialog(BuildContext context) {
    final List<String> bloodGroups = [
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];

    final Map<String, String> bloodGroupToNumber = {
      'A+': '+919481032460',
      'A-': '+917892942557',
      'B+': '+919606248727',
      'B-': '+918217748909',
      'AB+': '+919481032460',
      'AB-': '+917892942557',
      'O+': '+919606248727',
      'O-': '+918217748909',
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Required Blood Group',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: bloodGroups.length,
              itemBuilder: (context, index) {
                final bg = bloodGroups[index];
                return InkWell(
                  onTap: () async {
                    Navigator.of(context).pop(); // Close dialog immediately

                    String phoneNumber = bloodGroupToNumber[bg]!;
                    String message =
                        'Urgent: Medical emergency. Need blood group $bg.';
                    final Uri url = Uri.parse(
                      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
                    );

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch WhatsApp.'),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Center(
                      child: Text(
                        bg,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
