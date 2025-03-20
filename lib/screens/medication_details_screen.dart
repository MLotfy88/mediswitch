import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/widgets/medication_card.dart';
import 'package:share_plus/share_plus.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailsScreen({super.key, required this.medication});

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  List<Medication> _alternatives = [];
  bool _isLoading = true;
  // متغير محلي لتخزين حالة المفضلة
  late Medication _medication;

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    try {
      final alternatives = await DatabaseService.instance.getAlternatives(
        _medication.active,
      );
      
      // Filter out the current medication from alternatives
      final filteredAlternatives = alternatives.where(
        (med) => med.id != _medication.id
      ).toList();
      
      if (!mounted) return;
      
      setState(() {
        _alternatives = filteredAlternatives;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحميل البدائل'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medication = _medication;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(medication.tradeName),
        centerTitle: true,
        actions: [
          // Favorite button
          IconButton(
            icon: Icon(
              medication.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: medication.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              try {
                final newStatus = !medication.isFavorite;
                await DatabaseService.instance.toggleFavorite(medication.id!, newStatus);
                if (!mounted) return;
                
                setState(() {
                  _medication = medication.copyWith(isFavorite: newStatus);
                });
                
                // Store message and color before the async gap
                final message = newStatus 
                    ? 'تمت إضافة الدواء إلى المفضلة' 
                    : 'تمت إزالة الدواء من المفضلة';
                final backgroundColor = theme.colorScheme.primary;
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: backgroundColor,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('حدث خطأ أثناء تحديث المفضلة'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareMedicationInfo(medication);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication header with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.tradeName,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        medication.arabicName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              medication.mainCategoryAr,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              medication.dosageFormAr,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSecondary,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.secondary,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Price information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات السعر',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السعر الحالي',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${medication.price.toStringAsFixed(2)} جنيه',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (medication.oldPrice > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'السعر القديم',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '${medication.oldPrice.toStringAsFixed(2)} جنيه',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 153),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (medication.oldPrice > 0) ...[  
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            medication.hasPriceIncreased 
                                ? Icons.arrow_upward 
                                : Icons.arrow_downward,
                            color: medication.hasPriceIncreased 
                                ? Colors.red 
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تغير السعر: ${medication.priceDifferencePercentage.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: medication.hasPriceIncreased 
                                  ? Colors.red 
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'آخر تحديث: ${medication.lastPriceUpdate}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Medication details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الدواء',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildDetailRow('المادة الفعالة', medication.active),
                    _buildDetailRow('الشركة المنتجة', medication.company),
                    _buildDetailRow('الفئة', medication.categoryAr),
                    _buildDetailRow('الفئة الرئيسية', medication.mainCategoryAr),
                    _buildDetailRow('شكل الدواء', medication.dosageFormAr),
                    _buildDetailRow('طريقة الاستخدام', medication.usageAr),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            if (medication.description.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوصف',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Divider(),
                      Text(
                        medication.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Alternatives section
            Text(
              'البدائل المتاحة',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_alternatives.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'لا توجد بدائل متاحة',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alternatives.length,
                itemBuilder: (context, index) {
                  final alternative = _alternatives[index];
                  return MedicationCard(
                    medication: alternative,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicationDetailsScreen(
                            medication: alternative,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'غير متوفر' : value),
          ),
        ],
      ),
    );
  }
  
  // Share medication information
  void _shareMedicationInfo(Medication medication) {
    final String shareText = '''
${medication.tradeName} (${medication.arabicName})

السعر الحالي: ${medication.price.toStringAsFixed(2)} جنيه
${medication.oldPrice > 0 ? 'السعر القديم: ${medication.oldPrice.toStringAsFixed(2)} جنيه' : ''}

المادة الفعالة: ${medication.active}
الشركة المنتجة: ${medication.company}
الفئة: ${medication.categoryAr}

تم مشاركة هذه المعلومات من تطبيق ميديسويتش
''';    
    
    Share.share(shareText);
  }
}