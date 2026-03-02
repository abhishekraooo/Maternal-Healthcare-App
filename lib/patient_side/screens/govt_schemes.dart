import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

class GovtSchemes extends StatefulWidget {
  const GovtSchemes({super.key});

  @override
  State<GovtSchemes> createState() => _GovtSchemesState();
}

class _GovtSchemesState extends State<GovtSchemes> {
  String? selectedOption;
  int? selectedMonth;
  String? selectedResourceType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      if (provider.cachedGovtOption != null) {
        setState(() {
          selectedOption = provider.cachedGovtOption;
          selectedMonth = provider.cachedGovtMonth;
          selectedResourceType = provider.cachedGovtResource;
        });
      }
    });
  }

  void _updateState(String? option, int? month, String? resource) {
    setState(() {
      selectedOption = option;
      selectedMonth = month;
      selectedResourceType = resource;
    });
    if (mounted) {
      Provider.of<PatientDataProvider>(
        context,
        listen: false,
      ).saveGovtSchemesCache(option, month, resource);
    }
  }

  // Data maps remain identical
  final Map<String, Map<String, String>> pregnancyResources = {
    '1': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
    },
    '2': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
    },
    '3': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
    },
    '4': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
    },
    '5': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
    },
    '6': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '7': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '8': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Prasoothi Araike':
          'https://studybizz.com/karnataka-prasoothi-araika-scheme.html',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '9': {
      'Pradhan Mantri Mathru Vandhana':
          'https://wcd.delhi.gov.in/wcd/pradhan-mantri-matru-vandana-yojana-pmmvy',
      'Janani Suraksha':
          'https://www.nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Prasoothi Araike':
          'https://studybizz.com/karnataka-prasoothi-araika-scheme.html',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
  };

  final Map<String, Map<String, String>> infantResources = {
    '1': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '2': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Janani Shishu Suraksha': 'https://www.myscheme.gov.in/schemes/jssk',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '3': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '4': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '5': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
      'Thayi Bhagya': 'https://www.myscheme.gov.in/schemes/thayi-bhagya',
    },
    '6': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '7': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '8': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '9': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '10': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '11': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
    '12': {
      'ICDS Scheme': 'https://icds.gov.in/en/about-us',
      'Roshan Abhiyan': 'https://poshanabhiyaan.gov.in/',
      'Mathru Poorna':
          'https://yuvakanaja.in/healthfamily-welfare-dept-en/matru-poorna-scheme/',
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Govt Schemes & Resources',
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
                Text(
                  'Select your current stage',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Options Section
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        theme: theme,
                        title: 'Pregnancy',
                        icon: Icons.pregnant_woman,
                        value: 'pregnancy',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionCard(
                        theme: theme,
                        title: 'Infant Care',
                        icon: Icons.child_care,
                        value: 'infant',
                      ),
                    ),
                  ],
                ),

                if (selectedOption != null) ...[
                  const SizedBox(height: 32),
                  _buildMonthSelector(
                    theme: theme,
                    max: selectedOption == 'pregnancy' ? 9 : 12,
                  ),
                ],

                if (selectedMonth != null) ...[
                  const SizedBox(height: 32),
                  _buildResourceDropdown(theme),
                  if (selectedResourceType != null) ...[
                    const SizedBox(height: 16),
                    _buildUrlPreview(theme),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = selectedOption == value;

    return GestureDetector(
      onTap: () {
        _updateState(value, null, null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color:
                  isSelected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color:
                    isSelected
                        ? theme.colorScheme.surface
                        : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector({required ThemeData theme, required int max}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedOption == 'pregnancy'
              ? 'Select Pregnancy Month'
              : 'Select Infant Age (Months)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: max,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected = selectedMonth == month;

            return GestureDetector(
              onTap: () {
                _updateState(selectedOption, month, null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? theme.colorScheme.secondary.withOpacity(0.3)
                          : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Month $month',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResourceDropdown(ThemeData theme) {
    final resources =
        selectedOption == 'pregnancy'
            ? pregnancyResources[selectedMonth.toString()]
            : infantResources[selectedMonth.toString()];

    if (resources == null || resources.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No resources available for this timeframe.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Schemes & Resources',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedResourceType,
          isExpanded: true,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items:
              resources.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(
                    key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _updateState(selectedOption, selectedMonth, newValue);
            }
          },
          hint: const Text('Tap to view schemes'),
          icon: Icon(
            Icons.arrow_drop_down_circle_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUrlPreview(ThemeData theme) {
    final resources =
        selectedOption == 'pregnancy'
            ? pregnancyResources[selectedMonth.toString()]
            : infantResources[selectedMonth.toString()];

    final url = resources?[selectedResourceType];

    if (url == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.launch_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedResourceType!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the button below to visit the official government portal for more information and application details.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchUrl(url),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Open Official Portal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ); // Better for opening external websites
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch the portal.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
