import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Data Models ---
class Doctor {
  final String id;
  final String fullName;

  Doctor({required this.id, required this.fullName});

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Doctor(id: doc.id, fullName: data['fullName'] ?? '');
  }
}

class Vital {
  final String name;
  final String value;
  Vital({required this.name, required this.value});
}

class FetalData {
  final String name;
  final String value;
  FetalData({required this.name, required this.value});
}

class PatientDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // ORIGINAL STATE: DOCTORS, VITALS, FETAL DATA
  // ==========================================
  bool _isLoadingDoctors = false;
  List<Doctor> _doctors = [];
  bool _isVitalsLoading = false;
  List<Vital> _vitals = [];
  bool _isFetalDataLoading = false;
  List<FetalData> _fetalData = [];

  bool get isLoadingDoctors => _isLoadingDoctors;
  List<Doctor> get doctors => _doctors;
  bool get isVitalsLoading => _isVitalsLoading;
  List<Vital> get vitals => _vitals;
  bool get isFetalDataLoading => _isFetalDataLoading;
  List<FetalData> get fetalData => _fetalData;

  PatientDataProvider();

  Future<void> fetchDoctors() async {
    if (_isLoadingDoctors || _doctors.isNotEmpty) return;
    _isLoadingDoctors = true;
    notifyListeners();
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'doctor')
              .get();
      _doctors = snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
      _doctors = [];
    } finally {
      _isLoadingDoctors = false;
      notifyListeners();
    }
  }

  Future<void> fetchVitals() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isVitalsLoading = true;
    notifyListeners();

    try {
      final bpSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('vitals_history')
              .where('type', isEqualTo: 'Blood Pressure')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      final hrSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('vitals_history')
              .where('type', isEqualTo: 'Heart Rate')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      final bpValue =
          bpSnapshot.docs.isNotEmpty
              ? bpSnapshot.docs.first['value']
              : '-- mmHg';
      final hrValue =
          hrSnapshot.docs.isNotEmpty
              ? hrSnapshot.docs.first['value']
              : '-- bpm';

      _vitals = [
        Vital(name: 'Blood Pressure', value: bpValue),
        Vital(name: 'Heart Rate', value: hrValue),
      ];
    } catch (e) {
      debugPrint("Error fetching vitals: $e");
      _vitals = [
        Vital(name: 'Blood Pressure', value: 'Error'),
        Vital(name: 'Heart Rate', value: 'Error'),
      ];
    } finally {
      _isVitalsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFetalData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isFetalDataLoading = true;
    notifyListeners();

    try {
      final fhrSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('fetal_data_history')
              .where('type', isEqualTo: 'FHR')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      final fhrValue =
          fhrSnapshot.docs.isNotEmpty
              ? fhrSnapshot.docs.first['value']
              : '-- bpm';
      _fetalData = [FetalData(name: 'FHR', value: fhrValue)];
    } catch (e) {
      debugPrint("Error fetching fetal data: $e");
      _fetalData = [FetalData(name: 'FHR', value: 'Error')];
    } finally {
      _isFetalDataLoading = false;
      notifyListeners();
    }
  }

  void updateHeartRate(double averageBpm) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newBpmValue = '${averageBpm.toStringAsFixed(0)} bpm';
    int index = _vitals.indexWhere((vital) => vital.name == 'Heart Rate');
    if (index != -1) {
      _vitals[index] = Vital(name: 'Heart Rate', value: newBpmValue);
    } else {
      _vitals.add(Vital(name: 'Heart Rate', value: newBpmValue));
    }
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vitals_history')
          .add({
            'type': 'Heart Rate',
            'value': newBpmValue,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error saving heart rate to Firestore: $e");
    }
  }

  // ==========================================
  // CACHED FEATURE: PRESCRIPTION AI
  // ==========================================
  String _cachedPrescriptionText = '';
  Map<String, dynamic>? _cachedPrescriptionAnalysis;

  String get cachedPrescriptionText => _cachedPrescriptionText;
  Map<String, dynamic>? get cachedPrescriptionAnalysis =>
      _cachedPrescriptionAnalysis;

  void savePrescriptionCache(String text, Map<String, dynamic> analysis) {
    _cachedPrescriptionText = text;
    _cachedPrescriptionAnalysis = analysis;
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: DIET GUIDE
  // ==========================================
  List<dynamic> _cachedDietSuggestions = [];
  String _cachedDietMonth = '';
  String _cachedDietWeight = '';

  List<dynamic> get cachedDietSuggestions => _cachedDietSuggestions;
  String get cachedDietMonth => _cachedDietMonth;
  String get cachedDietWeight => _cachedDietWeight;

  void saveDietCache(List<dynamic> suggestions, String month, String weight) {
    _cachedDietSuggestions = suggestions;
    _cachedDietMonth = month;
    _cachedDietWeight = weight;
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: DUE DATE CALCULATOR
  // ==========================================
  String _cachedLmpDate = '';
  DateTime? _cachedDueDate;

  String get cachedLmpDate => _cachedLmpDate;
  DateTime? get cachedDueDate => _cachedDueDate;

  void saveDueDateCache(String lmpDate, DateTime? dueDate) {
    _cachedLmpDate = lmpDate;
    _cachedDueDate = dueDate;
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: VACCINATION PAGE
  // ==========================================
  Set<int> _completedVaccinations = {};
  Set<int> get completedVaccinations => _completedVaccinations;

  void toggleVaccination(int index) {
    if (_completedVaccinations.contains(index)) {
      _completedVaccinations.remove(index);
    } else {
      _completedVaccinations.add(index);
    }
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: OVULATION TRACKER
  // ==========================================
  DateTime? _cachedOvulationLmpDate;
  int _cachedCycleLength = 28;

  DateTime? get cachedOvulationLmpDate => _cachedOvulationLmpDate;
  int get cachedCycleLength => _cachedCycleLength;

  void saveOvulationCache(DateTime? lmpDate, int cycleLength) {
    _cachedOvulationLmpDate = lmpDate;
    _cachedCycleLength = cycleLength;
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: GOVT SCHEMES
  // ==========================================
  String? _cachedGovtOption;
  int? _cachedGovtMonth;
  String? _cachedGovtResource;

  String? get cachedGovtOption => _cachedGovtOption;
  int? get cachedGovtMonth => _cachedGovtMonth;
  String? get cachedGovtResource => _cachedGovtResource;

  void saveGovtSchemesCache(String? option, int? month, String? resource) {
    _cachedGovtOption = option;
    _cachedGovtMonth = month;
    _cachedGovtResource = resource;
    notifyListeners();
  }

  // ==========================================
  // CACHED FEATURE: MEDICAL CHATBOT
  // ==========================================
  List<Map<String, dynamic>> _cachedChatHistory = [];

  List<Map<String, dynamic>> get cachedChatHistory => _cachedChatHistory;

  void saveChatHistory(List<Map<String, dynamic>> history) {
    _cachedChatHistory = history;
    notifyListeners();
  }

  void clearChatHistory() {
    _cachedChatHistory.clear();
    notifyListeners();
  }

  // ==========================================
  // GLOBAL LOGOUT / CLEAR CACHE
  // ==========================================
  void clearAllFeatureCaches() {
    _cachedPrescriptionText = '';
    _cachedPrescriptionAnalysis = null;

    _cachedDietSuggestions = [];
    _cachedDietMonth = '';
    _cachedDietWeight = '';

    _cachedLmpDate = '';
    _cachedDueDate = null;

    _completedVaccinations.clear();

    _cachedOvulationLmpDate = null;
    _cachedCycleLength = 28;

    _cachedGovtOption = null;
    _cachedGovtMonth = null;
    _cachedGovtResource = null;

    notifyListeners();
  }
}
