import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/widgets/medication_card.dart';
import 'package:mediswitch/screens/medication_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ScrollController _scrollController = ScrollController();
  
  List<Medication> _favoriteMedications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final favorites = await DatabaseService.instance.getFavorites();
      
      setState(() {
        _favoriteMedications = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل المفضلة');
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
        title: const Text('المفضلة'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: _favoriteMedications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _favoriteMedications.length,
                      itemBuilder: (context, index) {
                        final medication = _favoriteMedications[index];
                        return MedicationCard(
                          medication: medication,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicationDetailsScreen(
                                  medication: medication,
                                ),
                              ),
                            ).then((_) => _loadFavorites());
                          },
                        );
                      },
                    ),
            ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أدوية في المفضلة',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إضافة الأدوية إلى المفضلة بالضغط على أيقونة القلب',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}