import 'package:flutter/material.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/models/weight_dose_calculator.dart';
import 'package:mediswitch/services/database_service.dart';

class ManageWeightDoseCalculatorScreen extends StatefulWidget {
  final Medication medication;
  final WeightDoseCalculator?
  doseCalculator; // إذا كان null، فهذا يعني إضافة جديدة

  const ManageWeightDoseCalculatorScreen({
    super.key,
    required this.medication,
    this.doseCalculator,
  });

  @override
  State<ManageWeightDoseCalculatorScreen> createState() =>
      _ManageWeightDoseCalculatorScreenState();
}

class _ManageWeightDoseCalculatorScreenState
    extends State<ManageWeightDoseCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _minDoseController = TextEditingController();
  final TextEditingController _maxDoseController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _minAgeMonthsController = TextEditingController();
  final TextEditingController _maxAgeMonthsController = TextEditingController();
  final TextEditingController _minWeightController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _maxDailyDosesController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _warningThreshold = 'none';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.doseCalculator != null;

    if (_isEditing) {
      _loadCalculatorData();
    } else {
      // القيم الافتراضية للإضافة الجديدة
      _unitController.text = widget.medication.unit;
      _minAgeMonthsController.text = '0';
      _maxAgeMonthsController.text = '1200'; // 100 سنة
      _minWeightController.text = '0';
      _maxWeightController.text = '500';
      _maxDailyDosesController.text = '4';
      _warningThreshold = 'none';
    }
  }

  void _loadCalculatorData() {
    if (!_isEditing || widget.doseCalculator == null) return;

    final calculator = widget.doseCalculator!;
    _minDoseController.text = calculator.minDosePerKg.toString();
    _maxDoseController.text = calculator.maxDosePerKg.toString();
    _unitController.text = calculator.unit;
    _minAgeMonthsController.text = calculator.minAgeMonths.toString();
    _maxAgeMonthsController.text = calculator.maxAgeMonths.toString();
    _minWeightController.text = calculator.minWeightKg.toString();
    _maxWeightController.text = calculator.maxWeightKg.toString();
    _maxDailyDosesController.text = calculator.maxDailyDoses.toString();
    _notesController.text = calculator.notes;
    _warningThreshold = calculator.warningThreshold;
  }

  @override
  void dispose() {
    _minDoseController.dispose();
    _maxDoseController.dispose();
    _unitController.dispose();
    _minAgeMonthsController.dispose();
    _maxAgeMonthsController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _maxDailyDosesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCalculator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final calculator = {
        if (_isEditing) 'id': widget.doseCalculator!.id,
        'medication_id': widget.medication.id,
        'min_dose_per_kg': double.parse(_minDoseController.text),
        'max_dose_per_kg': double.parse(_maxDoseController.text),
        'unit': _unitController.text,
        'min_age_months': int.parse(_minAgeMonthsController.text),
        'max_age_months': int.parse(_maxAgeMonthsController.text),
        'min_weight_kg': double.parse(_minWeightController.text),
        'max_weight_kg': double.parse(_maxWeightController.text),
        'max_daily_doses': int.parse(_maxDailyDosesController.text),
        'notes': _notesController.text,
        'warning_threshold': _warningThreshold,
      };

      if (_isEditing) {
        await DatabaseService.instance.updateWeightDoseCalculator(calculator);
      } else {
        await DatabaseService.instance.insertWeightDoseCalculator(calculator);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حفظ حاسبة الجرعة بنجاح')));
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حفظ حاسبة الجرعة: $e');
    }
  }

  Future<void> _deleteCalculator() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف حاسبة الجرعة هذه؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('حذف'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseService.instance.deleteWeightDoseCalculator(
        widget.doseCalculator!.id!,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حذف حاسبة الجرعة بنجاح')));
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حذف حاسبة الجرعة: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ), // Cannot use const here because message is a variable
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل حاسبة الجرعة' : 'إضافة حاسبة جرعة'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCalculator,
              tooltip: 'حذف حاسبة الجرعة',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات الدواء
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معلومات الدواء',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('الاسم التجاري: '),
                                  Text(widget.medication.tradeName),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('الاسم العربي: '),
                                  Text(widget.medication.arabicName),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('المادة الفعالة: '),
                                  Text(widget.medication.active),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('الشكل الدوائي: '),
                                  Text(widget.medication.dosageForm),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // معلومات حاسبة الجرعة
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معلومات حاسبة الجرعة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // الجرعة لكل كيلوجرام
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _minDoseController,
                                      decoration: const InputDecoration(
                                        labelText: 'الحد الأدنى للجرعة لكل كجم',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'هذا الحقل مطلوب';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // نطاق الوزن
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _minWeightController,
                                      decoration: const InputDecoration(
                                        labelText: 'الحد الأدنى للوزن (كجم)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'هذا الحقل مطلوب';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _maxWeightController,
                                      decoration: const InputDecoration(
                                        labelText: 'الحد الأقصى للوزن (كجم)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'هذا الحقل مطلوب';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'الرجاء إدخال رقم صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // عدد الجرعات اليومية
                              TextFormField(
                                controller: _maxDailyDosesController,
                                decoration: const InputDecoration(
                                  labelText: 'الحد الأقصى لعدد الجرعات اليومية',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'هذا الحقل مطلوب';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'الرجاء إدخال رقم صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // مستوى التحذير
                              const Text(
                                'مستوى التحذير:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _warningThreshold,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'none',
                                    child: Text('بدون تحذير'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'low',
                                    child: Text('منخفض'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text('متوسط'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'high',
                                    child: Text('مرتفع'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _warningThreshold = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // ملاحظات
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات',
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'ملاحظات إضافية حول حاسبة الجرعة (اختياري)',
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر الحفظ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveCalculator,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _isEditing ? 'حفظ التغييرات' : 'إضافة حاسبة الجرعة',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
