import 'package:flutter/material.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/database_helper.dart';

class SearchFilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final String? dosageForm;
  final Function(String?, double?, double?, String?) onApplyFilters;
  final Function()? onResetFilters;

  const SearchFilterSheet({
    super.key,
    this.selectedCategory,
    this.minPrice,
    this.maxPrice,
    this.dosageForm,
    required this.onApplyFilters,
    this.onResetFilters,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedDosageForm;
  
  List<String> _categories = [];
  List<String> _dosageForms = [];
  bool _isLoading = true;
  
  final double _maxPriceValue = 1000.0; // Maximum price value for the slider
  
  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _selectedDosageForm = widget.dosageForm;
    _loadFilterData();
  }
  
  Future<void> _loadFilterData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load categories
      final categoriesData = await DatabaseService.instance.getCategories();
      final categories = categoriesData.map((cat) => cat['main_category_ar'] as String).toList();
      
      // Load dosage forms from database
      final dosageForms = await DatabaseHelper.instance.getDosageForms();
      
      setState(() {
        _categories = categories;
        _dosageForms = dosageForms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error if needed
    }
  }
  
  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedDosageForm = null;
    });
    
    // استدعاء وظيفة إعادة الضبط إذا كانت متوفرة
    if (widget.onResetFilters != null) {
      widget.onResetFilters!();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تصفية النتائج',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة ضبط'),
                    ),
                  ],
                ),
                const Divider(),
                
                // Category filter
                Text(
                  'التصنيف',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) => ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                // Price range filter
                Text(
                  'نطاق السعر',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  min: 0,
                  max: _maxPriceValue,
                  values: RangeValues(
                    _minPrice ?? 0,
                    _maxPrice ?? _maxPriceValue,
                  ),
                  divisions: 20,
                  labels: RangeLabels(
                    '${(_minPrice ?? 0).toStringAsFixed(0)} جنيه',
                    '${(_maxPrice ?? _maxPriceValue).toStringAsFixed(0)} جنيه',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(_minPrice ?? 0).toStringAsFixed(0)} جنيه'),
                    Text('${(_maxPrice ?? _maxPriceValue).toStringAsFixed(0)} جنيه'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Dosage form filter
                Text(
                  'شكل الدواء',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dosageForms.map((form) => ChoiceChip(
                    label: Text(form),
                    selected: _selectedDosageForm == form,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDosageForm = selected ? form : null;
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 24),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(
                        _selectedCategory,
                        _minPrice,
                        _maxPrice,
                        _selectedDosageForm,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('تطبيق التصفية'),
                  ),
                ),
              ],
            ),
    );
  }
}