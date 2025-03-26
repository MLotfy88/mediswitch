import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mediswitch/services/medication_service.dart';
import 'package:mediswitch/utils/animation_utils.dart';
import 'package:mediswitch/utils/tailwind_utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Medication> _searchResults = [];
  bool _isLoading = false;
  final MedicationService _medicationService = MedicationService();

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    await _medicationService.loadMedicationsFromCSV();
    setState(() {
      _isLoading = false;
    });
  }

  void _performSearch(String query) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
        _searchResults = _medicationService.searchMedications(query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث الأدوية'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: TailwindUtils.p4,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الدواء أو المادة الفعالة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TailwindUtils.roundedLg),
                ),
              ),
              onChanged: _performSearch,
            ),
          )
              .animate()
              .fadeIn(duration: AnimationUtils.durationNormal)
              .slideY(begin: -10, end: 0),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Search results or empty state
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TablerIcons.search,
                          size: 64,
                          color: TailwindUtils.gray400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ابحث عن الأدوية بالاسم أو المادة الفعالة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: TailwindUtils.gray600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: TailwindUtils.p4,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final medication = _searchResults[index];
                      return Card(
                        child: ListTile(
                          title: Text(medication.tradeName),
                          subtitle: Text(medication.active),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
