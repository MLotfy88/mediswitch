import 'package:flutter/material.dart';
import 'package:mediswitch/models/dose_equivalent.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';

class ManageDoseEquivalentScreen extends StatefulWidget {
  final Medication medication;
  final DoseEquivalent? doseEquivalent; // إذا كان null، فهذا يعني إضافة جديدة

  const ManageDoseEquivalentScreen({
    super.key,
    required this.medication,
    this.doseEquivalent,
  });

  @override
  State<ManageDoseEquivalentScreen> createState() => _ManageDoseEquivalentScreenState();
}

class _ManageDoseEquivalentScreenState extends State<ManageDoseEquivalentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _conversionFactorController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _efficacyController = TextEditingController();
  final TextEditingController _toxicityController = TextEditingController();

  Medication? _equivalentMedication;
  List<Medication> _searchResults = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.doseEquivalent != null;

    if (_isEditing) {
      _loadEquivalentMedication();
      _conversionFactorController.text = widget.doseEquivalent!.conversionFactor.toString();
      _unitController.text = widget.doseEquivalent!.unit;
      _notesController.text = widget.doseEquivalent!.notes;
      _efficacyController.text = widget.doseEquivalent!.efficacyPercentage.toString();
      _toxicityController.text = widget.doseEquivalent!.toxicityPercentage.toString();
    } else {
      _unitController.text = widget.medication.unit;
      _efficacyController.text = '100.0';
      _toxicityController.text = '0.0';
    }
  }

  Future<void> _loadEquivalentMedication() async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = await DatabaseService.instance
          .getMedicationById(widget.doseEquivalent!.equivalentMedicationId);

      setState(() {
        _equivalentMedication = medication;
        if (medication != null) {
          _searchController.text = medication.tradeName;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل بيانات الدواء المكافئ: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _conversionFactorController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _efficacyController.dispose();
    _toxicityController.dispose();
    super.dispose();
  }

  Future<void> _searchMedications(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await DatabaseService.instance.searchMedications(query);
      // استبعاد الدواء الحالي من نتائج البحث
      results.removeWhere((med) => med.id == widget.medication.id);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء البحث: $e');
    }
  }

  void _selectMedication(Medication medication) {
    setState(() {
      _equivalentMedication = medication;
      _searchResults = [];
      _searchController.text = medication.tradeName;
    });
  }

  Future<void> _saveDoseEquivalent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_equivalentMedication == null) {
      _showErrorSnackBar('الرجاء اختيار الدواء المكافئ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doseEquivalent = {
        if (_isEditing) 'id': widget.doseEquivalent!.id,
        'medication_id': widget.medication.id,
        'equivalent_medication_id': _equivalentMedication!.id,
        'conversion_factor': double.parse(_conversionFactorController.text),
        'unit': _unitController.text,
        'notes': _notesController.text,
        'efficacy_percentage': double.parse(_efficacyController.text),
        'toxicity_percentage': double.parse(_toxicityController.text),
      };

      if (_isEditing) {
        await DatabaseService.instance.updateDoseEquivalent(doseEquivalent);
      } else {
        await DatabaseService.instance.insertDoseEquivalent(doseEquivalent);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مكافئ الجرعة بنجاح')),
        );
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حفظ مكافئ الجرعة: $e');
    }
  }

  Future<void> _deleteDoseEquivalent() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف مكافئ الجرعة هذا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseService.instance.deleteDoseEquivalent(widget.doseEquivalent!.id!);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف مكافئ الجرعة بنجاح')),
        );
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حذف مكافئ الجرعة: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل مكافئ الجرعة' : 'إضافة مكافئ جرعة'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteDoseEquivalent,
              tooltip: 'حذف مكافئ الجرعة',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الدواء الأصلي
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الدواء الأصلي',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('الاسم التجاري: ${widget.medication.tradeName}'),
                            Text('الاسم العربي: ${widget.medication.arabicName}'),
                            Text('المادة الفعالة: ${widget.medication.active}'),
                            Text('الشكل الدوائي: ${widget.medication.dosageForm}'),
                            Text('الوحدة: ${widget.medication.unit}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // اختيار الدواء المكافئ
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اختر الدواء المكافئ',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'ابحث عن الدواء المكافئ',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _searchMedications,
                            ),
                            if (_searchResults.isNotEmpty) ...[  
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final medication = _searchResults[index];
                                    return ListTile(
                                      title: Text(medication.tradeName),
                                      subtitle: Text(medication.active),
                                      onTap: () => _selectMedication(medication),
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (_equivalentMedication != null) ...[  
                              const SizedBox(height: 16),
                              const Text(
                                'الدواء المكافئ المحدد:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('الاسم التجاري: ${_equivalentMedication!.tradeName}'),
                              Text('المادة الفعالة: ${_equivalentMedication!.active}'),
                              Text('الشكل الدوائي: ${_equivalentMedication!.dosageForm}'),
                              Text('الوحدة: ${_equivalentMedication!.unit}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // معلومات مكافئ الجرعة
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات مكافئ الجرعة',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _conversionFactorController,
                              decoration: const InputDecoration(
                                labelText: 'معامل التحويل',
                                border: OutlineInputBorder(),
                                helperText: 'مثال: 2.0 يعني أن 1 وحدة من الدواء الأصلي تعادل 2 وحدة من الدواء المكافئ',
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
                            const SizedBox(height: 16),
                            
                            // وحدة القياس
                            TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'وحدة القياس',
                                border: OutlineInputBorder(),
                                helperText: 'مثال: mg, mcg, ml, etc.',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // نسبة الفعالية
                            TextFormField(
                              controller: _efficacyController,
                              decoration: const InputDecoration(
                                labelText: 'نسبة الفعالية (%)',
                                border: OutlineInputBorder(),
                                helperText: 'نسبة فعالية الدواء المكافئ مقارنة بالدواء الأصلي',
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
                            const SizedBox(height: 16),
                            
                            // نسبة الآثار الجانبية
                            TextFormField(
                              controller: _toxicityController,
                              decoration: const InputDecoration(
                                labelText: 'نسبة الآثار الجانبية (%)',
                                border: OutlineInputBorder(),
                                helperText: 'نسبة احتمالية الآثار الجانبية للدواء المكافئ مقارنة بالدواء الأصلي',
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
                            const SizedBox(height: 16),
                            
                            // ملاحظات
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات',
                                border: OutlineInputBorder(),
                                helperText: 'ملاحظات إضافية حول مكافئ الجرعة (اختياري)',
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
                        onPressed: _saveDoseEquivalent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'حفظ التغييرات' : 'إضافة مكافئ الجرعة',
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