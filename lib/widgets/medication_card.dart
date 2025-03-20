import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/utils/app_theme.dart';

class MedicationCard extends StatefulWidget {
  final Medication medication;
  final VoidCallback? onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.medication.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final newValue = !_isFavorite;
    setState(() {
      _isFavorite = newValue;
    });

    try {
      await DatabaseService.instance.toggleFavorite(
        widget.medication.id!,
        newValue,
      );
    } catch (e) {
      // Revert state if operation fails
      setState(() {
        _isFavorite = !newValue;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث المفضلة'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medication = widget.medication;
    
    // Calculate price difference for display
    final priceDiff = medication.priceDifferencePercentage.abs().toStringAsFixed(1);
    final priceIncreased = medication.hasPriceIncreased;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withValues(alpha: 26),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication icon or image placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Medication details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trade name
                        Text(
                          medication.tradeName,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Arabic name
                        Text(
                          medication.arabicName,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Active ingredient
                        Text(
                          medication.active,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Unit information if available
                        if (medication.unit.isNotEmpty) ...[  
                          const SizedBox(height: 4),
                          Text(
                            'الوحدة: ${medication.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Category and dosage form
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
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              const Divider(),
              // Price information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر الحالي',
                        style: theme.textTheme.bodySmall,
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
                          style: theme.textTheme.bodySmall,
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
                  if (medication.oldPrice > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priceIncreased ? Colors.red.withValues(alpha: 26) : Colors.green.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priceIncreased ? '+$priceDiff%' : '-$priceDiff%',
                        style: TextStyle(
                          color: priceIncreased ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}