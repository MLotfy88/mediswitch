import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/widgets/medication_card.dart';
import 'package:mediswitch/screens/medication_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  List<Medication> _recentMedications = [];
  List<Medication> _popularMedications = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more data when reaching the end of the list
      _loadMorePopularMedications();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load recent medications (latest added or updated)
      final recentMeds = await DatabaseService.instance.getMedications(
        limit: 10,
        offset: 0,
      );
      
      // Load popular medications
      final popularMeds = await DatabaseService.instance.getMedications(
        limit: 20,
        offset: 0,
      );
      
      // Load categories
      final categories = await DatabaseService.instance.getCategories();
      
      setState(() {
        _recentMedications = recentMeds;
        _popularMedications = popularMeds;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل البيانات');
    }
  }
  
  Future<void> _loadMorePopularMedications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medications = await DatabaseService.instance.getMedications(
        limit: 10, 
        offset: _popularMedications.length,
      );
      
      if (medications.isNotEmpty) {
        setState(() {
          _popularMedications.addAll(medications);
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
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ميديسويتش'),
        centerTitle: true,
      ),
      body: _isLoading && _recentMedications.isEmpty && _popularMedications.isEmpty
          ? _buildLoadingShimmer()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    
                    // Categories section
                    _buildCategoriesSection(),
                    const SizedBox(height: 24),
                    
                    // Recent medications section
                    _buildRecentMedicationsSection(),
                    const SizedBox(height: 24),
                    
                    // Popular medications section
                    _buildPopularMedicationsSection(),
                    
                    // Loading indicator at the bottom when loading more
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            
            // Categories shimmer
            Container(
              height: 20,
              width: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Recent medications shimmer
            Container(
              height: 20,
              width: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 160,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Popular medications shimmer
            Container(
              height: 20,
              width: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك في ميديسويتش',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابحث عن الأدوية وقارن الأسعار واعرف البدائل',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 230),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التصنيفات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) => _buildCategoryChip(category['main_category'])).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryChip(String category) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 179),
        label: Text(
          category,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        onPressed: () {
          // Navigate to search screen with category filter
          Navigator.pushNamed(
            context,
            '/search',
            arguments: {'category': category},
          );
        },
      ),
    );
  }
  
  Widget _buildRecentMedicationsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أحدث الأدوية',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _recentMedications.map((medication) => _buildRecentMedicationCard(medication)).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentMedicationCard(Medication medication) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicationDetailsScreen(medication: medication),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication icon
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 26),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.medication_rounded,
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
              ),
            ),
            // Medication details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.tradeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.arabicName,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${medication.price.toStringAsFixed(2)} جنيه',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
  
  Widget _buildPopularMedicationsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأدوية الشائعة',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _popularMedications.length,
          itemBuilder: (context, index) {
            return MedicationCard(
              medication: _popularMedications[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationDetailsScreen(
                      medication: _popularMedications[index],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}