import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataScreen extends StatefulWidget {
  const UserDataScreen({super.key});

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  late Future<List<Map<String, dynamic>>> _dataFuture;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchUserData();
  }

  // Fetch data from Firebase Firestore instead of Supabase
  Future<List<Map<String, dynamic>>> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Doctor is not logged in.');
      }

      // Query the 'appointments' collection where doctorId matches the logged-in doctor
      final snapshot =
          await _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: user.uid)
              .get();

      List<Map<String, dynamic>> appointments =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['patientName'] ?? 'Unknown Patient',
              'date': data['date'] ?? 'No Date',
              'time': data['time'] ?? 'No Time',
            };
          }).toList();

      // Sort appointments locally by date to avoid requiring a composite index in Firestore
      appointments.sort((a, b) {
        return (a['date'] as String).compareTo(b['date'] as String);
      });

      return appointments;
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      throw Exception('Failed to fetch data: $e');
    }
  }

  // Refresh data
  void _refreshData() {
    setState(() {
      _dataFuture = _fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Schedule',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return _buildErrorState(theme, snapshot.error.toString());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(theme);
              } else {
                final userData = snapshot.data!;
                return RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: () async {
                    _refreshData();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    itemCount: userData.length,
                    itemBuilder: (context, index) {
                      final user = userData[index];
                      return _buildAppointmentCard(theme, user);
                    },
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(ThemeData theme, Map<String, dynamic> user) {
    final String name = user['name']?.toString() ?? 'No Name';
    final String initial =
        name.isNotEmpty && name != 'No Name'
            ? name.substring(0, 1).toUpperCase()
            : '?';
    final String date = user['date']?.toString() ?? 'No Date';
    final String time = user['time']?.toString() ?? 'No Time';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: $name'),
              duration: const Duration(seconds: 2),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.3),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 80,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No Upcoming Appointments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You currently have no scheduled visits.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Schedule'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    // Stripping the "Exception:" text out of the UI for a cleaner look
    final cleanError = error.replaceAll('Exception: ', '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cleanError,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade800,
                elevation: 0,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
