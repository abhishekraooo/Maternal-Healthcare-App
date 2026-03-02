import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final String patientName;
  final String? avatarPath;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.patientName,
    this.avatarPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract the first letter of the patient's name for the fallback avatar
    final String initial =
        patientName.trim().isNotEmpty
            ? patientName.trim()[0].toUpperCase()
            : '?';

    final bool hasAvatar = avatarPath != null && avatarPath!.isNotEmpty;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          // REDUCED padding to 12.0 to give more breathing room
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  // REDUCED radius slightly from 36 to 32
                  radius: 32,
                  backgroundColor: theme.colorScheme.secondary.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: hasAvatar ? AssetImage(avatarPath!) : null,
                  child:
                      !hasAvatar
                          ? Text(
                            initial,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24, // Reduced font size to match radius
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 12), // Reduced spacing
              // ADDED Flexible so the text compresses instead of overflowing
              Flexible(
                child: Text(
                  patientName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12), // Reduced spacing

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
