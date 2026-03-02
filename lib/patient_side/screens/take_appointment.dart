import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TakeAppointmentPage extends StatefulWidget {
  const TakeAppointmentPage({super.key});

  @override
  State<TakeAppointmentPage> createState() => _TakeAppointmentPageState();
}

class _TakeAppointmentPageState extends State<TakeAppointmentPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // State variables to hold the automatically fetched data
  String? _assignedDoctorId;
  String? _assignedDoctorName;
  String? _patientName;

  bool _isLoadingData = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Automatically fetches both the patient's name and their linked doctor
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Get the patient's profile
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Grab the patient's name silently
        String fetchedPatientName =
            userData['name'] ?? userData['fullName'] ?? 'Patient';

        String? fetchedDoctorId;
        String? fetchedDoctorName;

        // Check for assigned doctor
        if (userData.containsKey('assignedDoctors')) {
          final assignedDoctors = userData['assignedDoctors'] as List;

          if (assignedDoctors.isNotEmpty) {
            fetchedDoctorId = assignedDoctors.first;

            // Fetch the doctor's name for the UI
            final doctorDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(fetchedDoctorId)
                    .get();

            if (doctorDoc.exists) {
              fetchedDoctorName =
                  doctorDoc.data()!['fullName'] ??
                  doctorDoc.data()!['name'] ??
                  'Your Provider';
            }
          }
        }

        if (mounted) {
          setState(() {
            _patientName = fetchedPatientName;
            _assignedDoctorId = fetchedDoctorId;
            _assignedDoctorName = fetchedDoctorName;
            _isLoadingData = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingData = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a date and a time.')),
      );
      return;
    }

    if (_assignedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No provider linked. Please update your profile.'),
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Patient is not logged in.');

      // Format date and time
      final String formattedDate =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final String formattedTime =
          "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      // Create the Appointment Document using the silently fetched patient name
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': user.uid,
        'patientName': _patientName ?? 'Unknown Patient',
        'doctorId': _assignedDoctorId,
        'date': formattedDate,
        'time': formattedTime,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              _isLoadingData
                  ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Icon
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Schedule a Visit',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        // Subtle Patient Name Display
                        if (_patientName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Booking for: $_patientName',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Assigned Doctor Locked Card
                        _assignedDoctorId == null
                            ? _buildNoDoctorError(theme)
                            : _buildAssignedDoctorCard(theme),

                        const SizedBox(height: 32),

                        // Date Picker Card
                        _buildPickerCard(
                          theme: theme,
                          title: 'Select Date',
                          value:
                              _selectedDate == null
                                  ? 'Not selected'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          icon: Icons.calendar_today_rounded,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 16),

                        // Time Picker Card
                        _buildPickerCard(
                          theme: theme,
                          title: 'Select Time',
                          value:
                              _selectedTime == null
                                  ? 'Not selected'
                                  : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          icon: Icons.access_time_rounded,
                          onTap: _pickTime,
                        ),
                        const SizedBox(height: 40),

                        // Submit Button
                        ElevatedButton(
                          onPressed:
                              _isBooking || _assignedDoctorId == null
                                  ? null
                                  : _bookAppointment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isBooking
                                  ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.surface,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Confirm Appointment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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

  // Read-only card displaying the linked doctor
  Widget _buildAssignedDoctorCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Care Physician',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _assignedDoctorName ?? 'Loading...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Error state if no doctor was found
  Widget _buildNoDoctorError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No provider is linked to your account. Please update your profile before booking.',
              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Date/Time selection
  Widget _buildPickerCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.secondary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            value == 'Not selected'
                                ? Colors.grey
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
