import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/screens/medication_details_screen.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/widgets/medication_card.dart';
import 'package:mediswitch/widgets/search_filter_sheet.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _currentQuery = '';
  
  // Filter options
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _dosageForm;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    
    // Add listener to search controller for auto-complete
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more data when reaching the end of the list
      if (!_isSearching && _currentQuery.isEmpty) {
        _loadMoreData();
      }
    }
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _currentQuery = '';
        _filteredMedications = _medications;
      });
      return;
    }
    
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    
    // Debounce search to avoid too many database queries
    Future.delayed(const Duration(milliseconds: 300), () {
      if (query == _searchController.text.trim()) {
        _searchMedications(query);
      }
    });
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medications = await DatabaseService.instance.getMedications(limit: 20, offset: 0);
      setState(() {
        _medications = medications;
        _filteredMedications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل البيانات');
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medications = await DatabaseService.instance.getMedications(
        limit: 20, 
        offset: _medications.length,
      );
      
      if (medications.isNotEmpty) {
        setState(() {
          _medications.addAll(medications);
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل المزيد من البيانات');
    }
  }
  
  Future<void> _searchMedications(String query) async {
    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });
    
    try {
      // Get search suggestions
      final medications = await DatabaseService.instance.searchMedications(query, limit: 30);
      
      // Extract unique suggestions from search results
      final suggestions = <String>{};
      for (final med in medications) {
        if (med.tradeName.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(med.tradeName);
        }
        if (med.arabicName.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(med.arabicName);
        }
      }
      
      setState(() {
        _suggestions = suggestions.take(5).toList(); // Limit to 5 suggestions
        _filteredMedications = medications;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء البحث');
    }
  }
  
  void _applyFilters() {
    List<Medication> filtered = _currentQuery.isNotEmpty 
        ? _filteredMedications 
        : List.from(_medications);
    
    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((med) => 
        med.mainCategory == _selectedCategory || 
        med.mainCategoryAr == _selectedCategory
      ).toList();
    }
    
    // Apply price range filter
    if (_minPrice != null) {
      filtered = filtered.where((med) => med.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((med) => med.price <= _maxPrice!).toList();
    }
    
    // Apply dosage form filter
    if (_dosageForm != null && _dosageForm!.isNotEmpty) {
      filtered = filtered.where((med) => 
        med.dosageForm == _dosageForm || 
        med.dosageFormAr == _dosageForm
      ).toList();
    }
    
    setState(() {
      _filteredMedications = filtered;
    });
  }
  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterSheet(
        selectedCategory: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        dosageForm: _dosageForm,
        onApplyFilters: (category, minPrice, maxPrice, dosageForm) {
          setState(() {
            _selectedCategory = category;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _dosageForm = dosageForm;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onResetFilters: () {
          setState(() {
            _selectedCategory = null;
            _minPrice = null;
            _maxPrice = null;
            _dosageForm = null;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث عن الأدوية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'تصفية متقدمة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الدواء...',
                hintTextDirection: TextDirection.rtl,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchMedications(value);
                }
              },
            ),
          ),
          
          // Search suggestions
          if (_suggestions.isNotEmpty)
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(_suggestions[index]),
                    onTap: () {
                      _searchController.text = _suggestions[index];
                      _searchMedications(_suggestions[index]);
                      _searchFocusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          
          // Filter chips
          if (_selectedCategory != null || _minPrice != null || _maxPrice != null || _dosageForm != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text('الفئة: $_selectedCategory'),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    if (_minPrice != null || _maxPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(
                            'السعر: ${_minPrice?.toStringAsFixed(0) ?? '0'} - ${_maxPrice?.toStringAsFixed(0) ?? 'أقصى'}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _minPrice = null;
                              _maxPrice = null;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    if (_dosageForm != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text('الشكل: $_dosageForm'),
                          onDeleted: () {
                            setState(() {
                              _dosageForm = null;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'النتائج: ${_filteredMedications.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_isSearching || _isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Medication list
          Expanded(
            child: _isLoading && _filteredMedications.isEmpty
                ? _buildLoadingShimmer()
                : _filteredMedications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد أدوية مطابقة للبحث',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'حاول تغيير كلمات البحث أو إزالة الفلاتر',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMedications.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredMedications.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          final medication = _filteredMedications[index];
                          return MedicationCard(
                            medication: medication,
                            onTap: () {
                              // Navigate to medication details screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailsScreen(medication: medication),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}