import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maternalhealthcare/patient_side/screens/home.dart';

// --- IMPORTANT: Update these imports to match your actual file paths ---
import 'package:maternalhealthcare/utils/role_selection.dart';
import 'package:maternalhealthcare/doctor_side/screens/doctor_home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Listen to Firebase Auth State (Is someone logged in?)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting to connect to Firebase
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        // User is NOT logged in -> Send to Role Selection
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const RoleSelectionScreen();
        }

        // 2. User IS logged in -> Check their Role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(authSnapshot.data!.uid)
                  .get(),
          builder: (context, userSnapshot) {
            // Waiting to fetch role from Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: theme.colorScheme.surface,
                body: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }

            // If the document doesn't exist or there is an error, force a clean sign out
            if (userSnapshot.hasError ||
                !userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const RoleSelectionScreen();
            }

            // 3. Extract the role and route them!
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? '';

            if (role == 'doctor') {
              return const DoctorHomeScreen();
            } else if (role == 'patient') {
              return const PatientHomeScreen(); // Note: Update this if your patient home class is named differently (e.g., PatientNavScreen)
            } else {
              // Unknown role fallback
              FirebaseAuth.instance.signOut();
              return const RoleSelectionScreen();
            }
          },
        );
      },
    );
  }
}
