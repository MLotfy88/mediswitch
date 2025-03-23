import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/models/weight_dose_calculator.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/database_update.dart';
import 'package:share_plus/share_plus.dart';

class WeightDoseCalculatorScreen extends StatefulWidget {
  const WeightDoseCalculatorScreen({super.key});

  @override
  State<WeightDoseCalculatorScreen> createState() => _WeightDoseCalculatorScreenState();
}

class _WeightDoseCalculatorScreenState extends State<WeightDoseCalculatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageYearsController = TextEditingController();
  final TextEditingController _ageMonthsController = TextEditingController();
  
  Medication? _selectedMedication;
  WeightDoseCalculator? _doseCalculator;
  List<Medication> _searchResults = [];
  bool _isLoading = false;
  final bool _isWeightInKg = true; // true for kg, false for lb
  Map<String, double>? _calculatedDoses;
  String _warningLevel = 'none';
  
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }
  
  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
    });
    
    // تحديث قاعدة البيانات لإضافة الجداول الجديدة إذا لم تكن موجودة
    await DatabaseUpdate.instance.updateDatabase();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
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
  
  Future<void> _selectMedication(Medication medication) async {
    setState(() {
      _isLoading = true;
      _selectedMedication = medication;
      _searchResults = [];
      _searchController.text = medication.tradeName;
      _calculatedDoses = null;
    });
    
    try {
      // الحصول على بيانات حاسبة الجرعة للدواء المحدد
      final calculatorData = await DatabaseUpdate.instance.getWeightDoseCalculator(medication.id!);
      
      if (calculatorData != null) {
        setState(() {
          _doseCalculator = WeightDoseCalculator.fromJson(calculatorData);
        });
      } else {
        setState(() {
          _doseCalculator = null;
        });
        _showErrorSnackBar('لا توجد بيانات حاسبة جرعة لهذا الدواء');
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _doseCalculator = null;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل بيانات حاسبة الجرعة: $e');
    }
  }
  
  void _calculateDose() {
    if (_selectedMedication == null || _doseCalculator == null) {
      _showErrorSnackBar('الرجاء اختيار دواء أولاً');
      return;
    }
    
    if (_weightController.text.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال وزن المريض');
      return;
    }
    
    try {
      // تحويل الوزن إلى كيلوجرام إذا كان بالرطل
      double weightKg = double.parse(_weightController.text);
      if (!_isWeightInKg) {
        weightKg = WeightDoseCalculator.lbToKg(weightKg);
      }
      
      // حساب العمر بالشهور
      int ageMonths = 0;
      if (_ageYearsController.text.isNotEmpty) {
        ageMonths += int.parse(_ageYearsController.text) * 12;
      }
      if (_ageMonthsController.text.isNotEmpty) {
        ageMonths += int.parse(_ageMonthsController.text);
      }
      
      // حساب الجرعة
      final doses = _doseCalculator!.calculateDose(weightKg, ageMonths);
      
      setState(() {
        _calculatedDoses = doses;
        _warningLevel = 'none';
      });
    } catch (e) {
      _showErrorSnackBar('خطأ في حساب الجرعة: $e');
    }
  }
  
  void _shareResults() {
    if (_selectedMedication == null || _doseCalculator == null || _calculatedDoses == null) {
      return;
    }
    
    final StringBuilder = StringBuffer();
    StringBuilder.writeln('حاسبة جرعة الدواء - MediSwitch');
    StringBuilder.writeln('الدواء: ${_selectedMedication!.tradeName}');
    
    // تحويل الوزن إلى كيلوجرام إذا كان بالرطل
    double weightKg = double.parse(_weightController.text);
    if (!_isWeightInKg) {
      weightKg = WeightDoseCalculator.lbToKg(weightKg);
    }
    
    StringBuilder.writeln('وزن المريض: $weightKg كجم');
    
    // حساب العمر بالشهور
    int ageYears = 0;
    int ageMonths = 0;
    if (_ageYearsController.text.isNotEmpty) {
      ageYears = int.parse(_ageYearsController.text);
    }
    if (_ageMonthsController.text.isNotEmpty) {
      ageMonths = int.parse(_ageMonthsController.text);
    }
    
    if (ageYears > 0 || ageMonths > 0) {
      StringBuilder.writeln('عمر المريض: ${ageYears > 0 ? '$ageYears سنة' : ''} ${ageMonths > 0 ? '$ageMonths شهر' : ''}');
    }
    
    StringBuilder.writeln('\nالجرعة المحسوبة:');
    StringBuilder.writeln('الجرعة الفردية: ${_calculatedDoses!['minSingleDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxSingleDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}');
    StringBuilder.writeln('الجرعة اليومية: ${_calculatedDoses!['minDailyDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxDailyDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}');
    StringBuilder.writeln('عدد الجرعات في اليوم: ${_calculatedDoses!['dosesPerDay']?.toInt()}');
    
    if (_doseCalculator!.notes.isNotEmpty) {
      StringBuilder.writeln('\nملاحظات: ${_doseCalculator!.notes}');
    }
    
    Share.share(StringBuilder.toString());
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        title: const Text('حاسبة جرعة الدواء'),
        actions: [
          if (_selectedMedication != null && _calculatedDoses != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
              tooltip: 'مشاركة النتائج',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم البحث عن الدواء
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر الدواء',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن الدواء باسمه التجاري أو المادة الفعالة',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _searchMedications,
                          ),
                          if (_searchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final medication = _searchResults[index];
                                  return ListTile(
                                    title: Text(medication.tradeName),
                                    subtitle: Text(medication.arabicName),
                                    onTap: () => _selectMedication(medication),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة جرعة الدواء'),
        actions: [
          if (_selectedMedication != null && _calculatedDoses != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
              tooltip: 'مشاركة النتائج',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم البحث عن الدواء
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر الدواء',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن الدواء باسمه التجاري أو المادة الفعالة',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _searchMedications,
                          ),
                          if (_searchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final medication = _searchResults[index];
                                  return ListTile(
                                    title: Text(medication.tradeName),
                                    subtitle: Text(medication.arabicName),
                                    onTap: () => _selectMedication(medication),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // قسم إدخال بيانات المريض
                  if (_selectedMedication != null)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدواء المحدد: ${_selectedMedication!.tradeName}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (_doseCalculator == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'لا توجد بيانات حاسبة جرعة لهذا الدواء',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            if (_doseCalculator != null) ...[  
                              const SizedBox(height: 16),
                              const Text('وزن المريض:'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _ageYearsController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'السنوات',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _ageMonthsController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'الشهور',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _calculateDose,
                                child: const Text('حساب الجرعة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // قسم عرض النتائج
                  if (_selectedMedication != null && _calculatedDoses != null)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نتائج حساب الجرعة',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text('الدواء: ${_selectedMedication!.tradeName}'),
                            Text('المادة الفعالة: ${_selectedMedication!.active}'),
                            
                            // تحويل الوزن إلى كيلوجرام إذا كان بالرطل
                            double.parse(_weightController.text).isNaN
                                ? const Text('الوزن: غير محدد')
                                : Text(
                                    'وزن المريض: ${_weightController.text} ${_isWeightInKg ? 'كجم' : 'رطل'} ${!_isWeightInKg ? '(${(double.parse(_weightController.text) * 0.453592).toStringAsFixed(2)} كجم)' : ''}',
                                  ),
                            
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            Text(
                              'الجرعة الفردية: ${_calculatedDoses!['minSingleDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxSingleDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'الجرعة اليومية: ${_calculatedDoses!['minDailyDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxDailyDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}',
                            ),
                            Text(
                              'عدد الجرعات في اليوم: ${_calculatedDoses!['dosesPerDay']?.toInt()}',
                            ),
                            
                            if (_doseCalculator!.notes.isNotEmpty) ...[  
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text('ملاحظات:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_doseCalculator!.notes),
                            ],
                            
                            if (_warningLevel != 'none') ...[  
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'تحذير: ${_getWarningText()}',
                                style: TextStyle(
                                  color: _warningLevel == 'high' ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  String _getWarningText() {
    switch (_warningLevel) {
      case 'low':
        return 'الجرعة المحسوبة منخفضة عن المعدل الطبيعي';
      case 'high':
        return 'الجرعة المحسوبة مرتفعة عن المعدل الطبيعي';
      default:
        return '';
    }
  }
}
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText = 'الوزن',
                                        border = OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width = 8),
                                  Expanded(
                                    flex = 1,
                                    child = DropdownButtonFormField<bool>(
                                      value: _isWeightInKg,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: true,
                                          child: Text('كجم'),
                                        ),
                                        DropdownMenuItem(
                                          value: false,
                                          child: Text('رطل'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _isWeightInKg = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height = 16),
                              Text('عمر المريض (اختياري):'),
                              SizedBox(height = 8),
                              Row(
                                children = [
                                  Expanded(
                                    child: TextField(
                                      controller: _ageYearsController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'السنوات',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _ageMonthsController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'الشهور',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height = 16),
                              ElevatedButton(
                                onPressed = _calculateDose,
                                child = const Text('حساب الجرعة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  SizedBox(height = 16),
                  
                  // قسم عرض النتائج
                  if (selectedMedication != null && _calculatedDoses != null)
                    Card(
                      elevation = 4,
                      child = Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نتائج حساب الجرعة',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text('الدواء: ${_selectedMedication!.tradeName}'),
                            Text('المادة الفعالة: ${_selectedMedication!.active}'),
                            
                            // تحويل الوزن إلى كيلوجرام إذا كان بالرطل
                            double.parse(_weightController.text).isNaN
                                ? const Text('الوزن: غير محدد')
                                : Text(
                                    'وزن المريض: ${_weightController.text} ${_isWeightInKg ? 'كجم' : 'رطل'} ${!_isWeightInKg ? '(${(double.parse(_weightController.text) * 0.453592).toStringAsFixed(2)} كجم)' : ''}',
                                  ),
                            
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            Text(
                              'الجرعة الفردية: ${_calculatedDoses!['minSingleDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxSingleDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'الجرعة اليومية: ${_calculatedDoses!['minDailyDose']?.toStringAsFixed(2)} - ${_calculatedDoses!['maxDailyDose']?.toStringAsFixed(2)} ${_doseCalculator!.unit}',
                            ),
                            Text(
                              'عدد الجرعات في اليوم: ${_calculatedDoses!['dosesPerDay']?.toInt()}',
                            ),
                            
                            if (_doseCalculator!.notes.isNotEmpty) ...[  
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text('ملاحظات:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_doseCalculator!.notes),
                            ],
                            
                            if (_warningLevel != 'none') ...[  
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'تحذير: ${_getWarningText()}',
                                style: TextStyle(
                                  color: _warningLevel == 'high' ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  String _getWarningText() {
    switch (_warningLevel) {
      case 'low':
        return 'الجرعة المحسوبة منخفضة عن المعدل الطبيعي';
      case 'high':
        return 'الجرعة المحسوبة مرتفعة عن المعدل الطبيعي';
      default:
        return '';
    }
  }
}