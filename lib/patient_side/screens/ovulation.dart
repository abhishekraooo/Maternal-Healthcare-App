import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

class OvulationCalculatorPage extends StatefulWidget {
  const OvulationCalculatorPage({super.key});

  @override
  State<OvulationCalculatorPage> createState() =>
      _OvulationCalculatorPageState();
}

class _OvulationCalculatorPageState extends State<OvulationCalculatorPage> {
  final TextEditingController _dateController = TextEditingController();
  DateTime? lastPeriodDate;
  int cycleLength = 28;

  // Results
  DateTime? fertileStart;
  DateTime? fertileEnd;
  DateTime? ovulationDay;
  DateTime? nextPeriod;
  DateTime? pregnancyTestDay;
  DateTime? dueDate;

  final dateFormat = DateFormat("MMMM d, yyyy");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      if (provider.cachedOvulationLmpDate != null) {
        setState(() {
          lastPeriodDate = provider.cachedOvulationLmpDate;
          cycleLength = provider.cachedCycleLength;
          _dateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(lastPeriodDate!);
        });
        calculate();
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void calculate() {
    if (lastPeriodDate == null) return;

    ovulationDay = lastPeriodDate!.add(Duration(days: cycleLength - 14));
    fertileStart = ovulationDay!.subtract(const Duration(days: 5));
    fertileEnd = ovulationDay;
    nextPeriod = lastPeriodDate!.add(Duration(days: cycleLength));
    pregnancyTestDay = nextPeriod!.add(const Duration(days: 1));
    dueDate = lastPeriodDate!.add(const Duration(days: 280));

    setState(() {});

    if (mounted) {
      Provider.of<PatientDataProvider>(
        context,
        listen: false,
      ).saveOvulationCache(lastPeriodDate, cycleLength);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastPeriodDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        lastPeriodDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      calculate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cycle Tracker",
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

                if (ovulationDay != null) _buildResultsSection(theme),
                if (ovulationDay != null) const SizedBox(height: 32),

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
            "Enter Your Details",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: 'First Day of Last Period',
              hintText: 'YYYY-MM-DD',
              prefixIcon: Icon(
                Icons.water_drop_outlined,
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

          Text(
            "Cycle Length: $cycleLength days",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.secondary.withOpacity(0.5),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withOpacity(0.2),
              valueIndicatorColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: cycleLength.toDouble(),
              min: 21,
              max: 35,
              divisions: 14,
              label: "$cycleLength",
              onChanged: (val) {
                setState(() {
                  cycleLength = val.toInt();
                });
                if (lastPeriodDate != null) {
                  calculate();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Your Projections",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme,
          "Fertile Window",
          "${dateFormat.format(fertileStart!)} - ${dateFormat.format(fertileEnd!)}",
          Icons.favorite_border,
        ),
        _buildInfoCard(
          theme,
          "Approximate Ovulation",
          dateFormat.format(ovulationDay!),
          Icons.egg_outlined,
        ),
        _buildInfoCard(
          theme,
          "Next Period",
          dateFormat.format(nextPeriod!),
          Icons.water_drop_outlined,
        ),
        _buildInfoCard(
          theme,
          "Pregnancy Test Day",
          dateFormat.format(pregnancyTestDay!),
          Icons.medical_information_outlined,
        ),
        _buildInfoCard(
          theme,
          "Estimated Due Date",
          dateFormat.format(dueDate!),
          Icons.child_care_outlined,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: theme.colorScheme.secondary.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                "About Ovulation",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Text(
            "Common signs of ovulation include:",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            theme,
            "Rise in basal body temperature (0.5 to 1°F), measured with a thermometer.",
          ),
          _buildBulletPoint(
            theme,
            "Higher levels of luteinizing hormone (LH), detected by a home ovulation kit.",
          ),
          _buildBulletPoint(
            theme,
            "Cervical mucus may become clear, thin, and stretchy (like raw egg whites).",
          ),
          _buildBulletPoint(theme, "Breast tenderness or bloating."),
          _buildBulletPoint(theme, "Slight pain or cramping in your side."),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: 18,
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
      ),
    );
  }
}
