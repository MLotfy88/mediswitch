import 'package:flutter/material.dart';
import 'package:mediswitch/models/drug_interaction.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/database_update.dart';

class ManageDrugInteractionScreen extends StatefulWidget {
  final Medication medication;
  final DrugInteraction? drugInteraction; // إذا كان null، فهذا يعني إضافة جديدة

  const ManageDrugInteractionScreen({
    super.key,
    required this.medication,
    this.drugInteraction,
  });

  @override
  State<ManageDrugInteractionScreen> createState() => _ManageDrugInteractionScreenState();
}

class _ManageDrugInteractionScreenState extends State<ManageDrugInteractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _effectController = TextEditingController();
  final TextEditingController _effectArController = TextEditingController();
  final TextEditingController _mechanismController = TextEditingController();
  final TextEditingController _mechanismArController = TextEditingController();
  final TextEditingController _managementController = TextEditingController();
  final TextEditingController _managementArController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  Medication? _interactingMedication;
  List<Medication> _searchResults = [];
  bool _isLoading = false;
  bool _isEditing = false;
  String _severityLevel = 'minor'; // 'minor', 'moderate', 'major', 'contraindicated'

  @override
  void initState() {
    super.initState();
    _isEditing = widget.drugInteraction != null;

    if (_isEditing) {
      _loadInteractingMedication();
      _severityLevel = widget.drugInteraction!.severityLevel;
      _effectController.text = widget.drugInteraction!.effect;
      _effectArController.text = widget.drugInteraction!.effectAr;
      _mechanismController.text = widget.drugInteraction!.mechanism;
      _mechanismArController.text = widget.drugInteraction!.mechanismAr;
      _managementController.text = widget.drugInteraction!.management;
      _managementArController.text = widget.drugInteraction!.managementAr;
      _referenceController.text = widget.drugInteraction!.reference;
    }
  }

  Future<void> _loadInteractingMedication() async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = await DatabaseService.instance
          .getMedicationById(widget.drugInteraction!.interactingMedicationId);

      setState(() {
        _interactingMedication = medication;
        if (medication != null) {
          _searchController.text = medication.tradeName;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل بيانات الدواء المتفاعل: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _effectController.dispose();
    _effectArController.dispose();
    _mechanismController.dispose();
    _mechanismArController.dispose();
    _managementController.dispose();
    _managementArController.dispose();
    _referenceController.dispose();
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
      _interactingMedication = medication;
      _searchResults = [];
      _searchController.text = medication.tradeName;
    });
  }

  Future<void> _saveDrugInteraction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_interactingMedication == null) {
      _showErrorSnackBar('الرجاء اختيار الدواء المتفاعل');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final drugInteraction = {
        if (_isEditing) 'id': widget.drugInteraction!.id,
        'medication_id': widget.medication.id,
        'interacting_medication_id': _interactingMedication!.id,
        'severity_level': _severityLevel,
        'effect': _effectController.text,
        'effect_ar': _effectArController.text,
        'mechanism': _mechanismController.text,
        'mechanism_ar': _mechanismArController.text,
        'management': _managementController.text,
        'management_ar': _managementArController.text,
        'reference': _referenceController.text,
      };

      if (_isEditing) {
        await DatabaseUpdate.instance.updateDrugInteraction(drugInteraction);
      } else {
        await DatabaseUpdate.instance.insertDrugInteraction(drugInteraction);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التفاعل الدوائي بنجاح')),
        );
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حفظ التفاعل الدوائي: $e');
    }
  }

  Future<void> _deleteDrugInteraction() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التفاعل الدوائي؟'),
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
      await DatabaseUpdate.instance.deleteDrugInteraction(widget.drugInteraction!.id!);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التفاعل الدوائي بنجاح')),
        );
        Navigator.pop(context, true); // العودة مع إشارة إلى أن التغييرات تمت
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء حذف التفاعل الدوائي: $e');
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
        title: Text(_isEditing ? 'تعديل تفاعل دوائي' : 'إضافة تفاعل دوائي'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteDrugInteraction,
              tooltip: 'حذف التفاعل الدوائي',
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // اختيار الدواء المتفاعل
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اختر الدواء المتفاعل',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'ابحث عن الدواء المتفاعل',
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
                            if (_interactingMedication != null) ...[  
                              const SizedBox(height: 16),
                              const Text(
                                'الدواء المتفاعل المحدد:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('الاسم التجاري: ${_interactingMedication!.tradeName}'),
                              Text('المادة الفعالة: ${_interactingMedication!.active}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // معلومات التفاعل الدوائي
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات التفاعل الدوائي',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // مستوى الخطورة
                            const Text(
                              'مستوى الخطورة:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _severityLevel,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'minor', child: Text('بسيط')),
                                DropdownMenuItem(value: 'moderate', child: Text('متوسط')),
                                DropdownMenuItem(value: 'major', child: Text('شديد')),
                                DropdownMenuItem(value: 'contraindicated', child: Text('ممنوع')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _severityLevel = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // تأثير التفاعل
                            TextFormField(
                              controller: _effectController,
                              decoration: const InputDecoration(
                                labelText: 'تأثير التفاعل (بالإنجليزية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // تأثير التفاعل بالعربية
                            TextFormField(
                              controller: _effectArController,
                              decoration: const InputDecoration(
                                labelText: 'تأثير التفاعل (بالعربية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // آلية التفاعل
                            TextFormField(
                              controller: _mechanismController,
                              decoration: const InputDecoration(
                                labelText: 'آلية التفاعل (بالإنجليزية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // آلية التفاعل بالعربية
                            TextFormField(
                              controller: _mechanismArController,
                              decoration: const InputDecoration(
                                labelText: 'آلية التفاعل (بالعربية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // إدارة التفاعل
                            TextFormField(
                              controller: _managementController,
                              decoration: const InputDecoration(
                                labelText: 'إدارة التفاعل (بالإنجليزية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // إدارة التفاعل بالعربية
                            TextFormField(
                              controller: _managementArController,
                              decoration: const InputDecoration(
                                labelText: 'إدارة التفاعل (بالعربية)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'هذا الحقل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // المراجع
                            TextFormField(
                              controller: _referenceController,
                              decoration: const InputDecoration(
                                labelText: 'المراجع',
                                border: OutlineInputBorder(),
                                helperText: 'مراجع علمية للتفاعل الدوائي (اختياري)',
                              ),
                              maxLines: 2,
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
                        onPressed: _saveDrugInteraction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'حفظ التغييرات' : 'إضافة تفاعل دوائي',
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