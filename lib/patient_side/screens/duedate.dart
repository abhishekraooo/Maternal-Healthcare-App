import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

class DueDateCalculator extends StatefulWidget {
  const DueDateCalculator({super.key});

  @override
  State<DueDateCalculator> createState() => _DueDateCalculatorState();
}

class _DueDateCalculatorState extends State<DueDateCalculator> {
  final TextEditingController _dateController = TextEditingController();
  DateTime? _dueDate;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Load cached data from the Provider when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      if (provider.cachedLmpDate.isNotEmpty) {
        setState(() {
          _dateController.text = provider.cachedLmpDate;
          _dueDate = provider.cachedDueDate;
        });
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _calculateDueDate() {
    if (_dateController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a date first.';
        _dueDate = null;
      });
      return;
    }

    try {
      DateTime lmp = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      // Apply Naegele's Rule: LMP + 7 days - 3 months + 1 year
      DateTime calculatedDueDate = DateTime(
        lmp.year + 1,
        lmp.month - 3,
        lmp.day + 7,
      );

      setState(() {
        _dueDate = calculatedDueDate;
        _errorMessage = '';
      });

      // Save to cache
      if (mounted) {
        Provider.of<PatientDataProvider>(
          context,
          listen: false,
        ).saveDueDateCache(_dateController.text, calculatedDueDate);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid date format.';
        _dueDate = null;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        // Ensuring the date picker inherits the global theme gracefully
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _dateController.text = formattedDate;
        _dueDate = null;
        _errorMessage = '';
      });

      // Optionally clear the cache if they pick a new date but haven't calculated yet
      if (mounted) {
        Provider.of<PatientDataProvider>(
          context,
          listen: false,
        ).saveDueDateCache(formattedDate, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Due Date Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(theme),
                const SizedBox(height: 32),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_dueDate != null) _buildResultSection(theme),
                const SizedBox(height: 32),
                _buildInfoSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the First Day of Your Last Menstrual Period (LMP):',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'Select Date',
              hintText: 'YYYY-MM-DD',
              prefixIcon: Icon(
                Icons.calendar_month_outlined,
                color: theme.colorScheme.primary,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.secondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.secondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateDueDate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Calculate Due Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Your Estimated Due Date is:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE\nMMMM dd, yyyy').format(_dueDate!),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Key Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            theme,
            'Pregnancy is calculated from the first day of your last period, which is about 2 weeks before you conceive.',
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
            theme,
            'This is only an estimate. Full-term pregnancy is typically between 37 and 42 weeks.',
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
            theme,
            'Always confirm with your healthcare provider.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
