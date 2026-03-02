import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Data Models ---

/// Represents a patient in the doctor's dashboard list and details view
class Patient {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatar;
  final String dateOfBirth;
  final String weightKg;

  Patient({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.avatar,
    required this.dateOfBirth,
    required this.weightKg,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Patient(
      id: doc.id,
      // Check both 'name' and 'fullName' to support different registration versions
      fullName: data['fullName'] ?? data['name'] ?? 'Unknown Patient',
      phoneNumber: data['phoneNumber'] ?? 'N/A',
      avatar: data['avatar'],
      dateOfBirth: data['dateOfBirth'] ?? 'Not Provided',
      weightKg: (data['weightKg'] ?? '--').toString(),
    );
  }
}

/// Represents the profile of the currently logged-in doctor
class DoctorProfile {
  final String name;
  final String licenseId;
  final String? avatar;
  final String? specialization;

  DoctorProfile({
    required this.name,
    required this.licenseId,
    this.avatar,
    this.specialization,
  });

  factory DoctorProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DoctorProfile(
      name: data['fullName'] ?? data['name'] ?? 'Dr. Name Not Found',
      licenseId: data['licenseId'] ?? 'N/A',
      avatar: data['avatar'],
      specialization: data['specialization'] ?? 'General Practice',
    );
  }
}

// --- Provider ---

class DoctorDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State Management
  bool _isLoadingPatients = false;
  List<Patient> _patients = [];

  bool _isLoadingProfile = false;
  DoctorProfile? _profile;

  // Getters
  bool get isLoadingPatients => _isLoadingPatients;
  List<Patient> get patients => _patients;

  bool get isLoadingProfile => _isLoadingProfile;
  DoctorProfile? get profile => _profile;

  /// Fetches patients who have the current doctor's ID in their 'assignedDoctors' array.
  Future<void> fetchPatients() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingPatients = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'patient')
              // Searches the array we established during patient onboarding
              .where('assignedDoctors', arrayContains: user.uid)
              .get();

      _patients =
          snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching patients from Firestore: $e");
      _patients = [];
    } finally {
      _isLoadingPatients = false;
      notifyListeners();
    }
  }

  /// Fetches the profile details of the logged-in provider.
  Future<void> fetchDoctorProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingProfile = true;
    notifyListeners();

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        _profile = DoctorProfile.fromFirestore(docSnapshot);
      }
    } catch (e) {
      debugPrint("Error fetching doctor profile from Firestore: $e");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Optional: Clear local data on sign-out
  void clearData() {
    _patients = [];
    _profile = null;
    _isLoadingPatients = false;
    _isLoadingProfile = false;
    notifyListeners();
  }
}
