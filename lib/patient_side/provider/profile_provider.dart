import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Model for the detailed patient profile
class PatientProfile {
  final String fullName;
  final String phoneNumber;
  final String dateOfBirth;
  final String weightKg;
  final String doctorName;
  final String avatar; // ADDED: Avatar field

  PatientProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.weightKg,
    required this.doctorName,
    required this.avatar, // ADDED: Avatar parameter
  });
}

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PatientProfile? _patientProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  PatientProfile? get patientProfile => _patientProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches the complete patient profile, including the doctor's name.
  Future<void> fetchPatientProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch the patient's user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception("User profile not found in the database.");
      }
      final userData = userDoc.data()!;

      // 2. Safely get the doctor's name from the 'assignedDoctors' array
      String doctorName = 'Not Assigned';

      // Check if the 'assignedDoctors' list exists and has at least one doctor
      if (userData.containsKey('assignedDoctors') &&
          userData['assignedDoctors'] is List &&
          (userData['assignedDoctors'] as List).isNotEmpty) {
        // Get the first doctor in the list (their Primary Care Physician)
        final doctorId = (userData['assignedDoctors'] as List).first;

        final doctorDoc =
            await _firestore.collection('users').doc(doctorId).get();

        if (doctorDoc.exists && doctorDoc.data() != null) {
          // Check for 'fullName' or 'name' just to be safe
          doctorName =
              doctorDoc.data()!['fullName'] ??
              doctorDoc.data()!['name'] ??
              'N/A';
        }
      }

      // 3. Safely format the date for display
      String formattedDob = 'Not Provided';
      if (userData.containsKey('dateOfBirth') &&
          userData['dateOfBirth'] != null) {
        // Handle both String and Timestamp formats just in case
        if (userData['dateOfBirth'] is Timestamp) {
          final dobTimestamp = userData['dateOfBirth'] as Timestamp;
          final dob = dobTimestamp.toDate();
          formattedDob =
              "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
        } else {
          formattedDob = userData['dateOfBirth'].toString();
        }
      }

      // 4. Build the profile with safe fallbacks for every field
      _patientProfile = PatientProfile(
        // Look for 'name' first (from our new onboarding), then fallback to 'fullName'
        fullName:
            userData['name'] ?? userData['fullName'] ?? 'No Name Provided',
        phoneNumber: userData['phoneNumber'] ?? 'No Phone Provided',
        dateOfBirth: formattedDob,
        weightKg: (userData['weightKg'] ?? '--').toString(),
        doctorName: doctorName,
        avatar: userData['avatar'] ?? '', // Extract the avatar path
      );
    } catch (e) {
      _errorMessage = "Failed to load profile. Please try again.";
      debugPrint("Detailed Error: $e"); // For your debugging
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
