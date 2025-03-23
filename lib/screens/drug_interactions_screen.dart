import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediswitch/models/drug_interaction.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/database_update.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DrugInteractionsScreen extends StatefulWidget {
  const DrugInteractionsScreen({super.key});

  @override
  State<DrugInteractionsScreen> createState() => _DrugInteractionsScreenState();
}

class _DrugInteractionsScreenState extends State<DrugInteractionsScreen> {
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  
  Medication? _selectedMedication1;
  Medication? _selectedMedication2;
  List<Medication> _searchResults1 = [];
  List<Medication> _searchResults2 = [];
  List<DrugInteraction> _interactions = [];
  final Map<int, Medication> _interactingMedications = {};
  bool _isLoading = false;
  bool _isSearching1 = false;
  bool _isSearching2 = false;
  
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
    _searchController1.dispose();
    _searchController2.dispose();
    super.dispose();
  }
  
  Future<void> _searchMedications(String query, bool isFirstMedication) async {
    if (query.isEmpty) {
      setState(() {
        if (isFirstMedication) {
          _searchResults1 = [];
        } else {
          _searchResults2 = [];
        }
      });
      return;
    }
    
    setState(() {
      if (isFirstMedication) {
        _isSearching1 = true;
      } else {
        _isSearching2 = true;
      }
    });
    
    try {
      final results = await DatabaseService.instance.searchMedications(query);
      setState(() {
        if (isFirstMedication) {
          _searchResults1 = results;
          _isSearching1 = false;
        } else {
          _searchResults2 = results;
          _isSearching2 = false;
        }
      });
    } catch (e) {
      setState(() {
        if (isFirstMedication) {
          _isSearching1 = false;
        } else {
          _isSearching2 = false;
        }
      });
      _showErrorSnackBar('حدث خطأ أثناء البحث: $e');
    }
  }
  
  Future<void> _selectMedication(Medication medication, bool isFirstMedication) async {
    setState(() {
      if (isFirstMedication) {
        _selectedMedication1 = medication;
        _searchResults1 = [];
        _searchController1.text = medication.tradeName;
      } else {
        _selectedMedication2 = medication;
        _searchResults2 = [];
        _searchController2.text = medication.tradeName;
      }
    });
    
    // إذا تم اختيار دواءين، ابحث عن التفاعلات بينهما
    if (_selectedMedication1 != null && _selectedMedication2 != null) {
      await _findInteractions();
    }
  }
  
  Future<void> _findInteractions() async {
    if (_selectedMedication1 == null || _selectedMedication2 == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _interactions = [];
    });
    
    try {
      // البحث عن التفاعلات بين الدواءين
      final interactionsData = await DatabaseUpdate.instance.findInteractionsBetweenMedications(
        _selectedMedication1!.id!,
        _selectedMedication2!.id!
      );
      
      final List<DrugInteraction> interactions = [];
      
      for (final data in interactionsData) {
        final interaction = DrugInteraction.fromJson(data);
        interactions.add(interaction);
      }
      
      setState(() {
        _interactions = interactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء البحث عن التفاعلات: $e');
    }
  }
  
  void _shareResults() {
    if (_selectedMedication1 == null || _selectedMedication2 == null || _interactions.isEmpty) {
      return;
    }
    
    final StringBuilder = StringBuffer();
    StringBuilder.writeln('تفاعلات الأدوية - MediSwitch');
    StringBuilder.writeln('الدواء الأول: ${_selectedMedication1!.tradeName}');
    StringBuilder.writeln('المادة الفعالة: ${_selectedMedication1!.active}');
    StringBuilder.writeln('الدواء الثاني: ${_selectedMedication2!.tradeName}');
    StringBuilder.writeln('المادة الفعالة: ${_selectedMedication2!.active}');
    StringBuilder.writeln('\nالتفاعلات:');
    
    for (final interaction in _interactions) {
      StringBuilder.writeln('مستوى الخطورة: ${_getSeverityLevelArabic(interaction.severityLevel)}');
      StringBuilder.writeln('التأثير: ${interaction.effectAr}');
      StringBuilder.writeln('آلية التفاعل: ${interaction.mechanismAr}');
      StringBuilder.writeln('كيفية التعامل: ${interaction.managementAr}');
      if (interaction.reference.isNotEmpty) {
        StringBuilder.writeln('المرجع: ${interaction.reference}');
      }
      StringBuilder.writeln('');
    }
    
    StringBuilder.writeln('\nتم إنشاء هذا التقرير بواسطة تطبيق MediSwitch');
    
    Share.share(StringBuilder.toString());
  }
  
  String _getSeverityLevelArabic(String level) {
    switch (level) {
      case 'minor':
        return 'بسيط';
      case 'moderate':
        return 'متوسط';
      case 'major':
        return 'شديد';
      case 'contraindicated':
        return 'ممنوع الاستخدام المشترك';
      default:
        return level;
    }
  }
  
  Color _getSeverityColor(String level) {
    switch (level) {
      case 'minor':
        return Colors.green;
      case 'moderate':
        return Colors.amber;
      case 'major':
        return Colors.deepOrange;
      case 'contraindicated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاعلات الأدوية'),
        actions: [
          if (_interactions.isNotEmpty)
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الدواء الأول
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الدواء الأول',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController1,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن الدواء الأول',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: _searchController1.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController1.clear();
                                          _searchResults1 = [];
                                          _selectedMedication1 = null;
                                          _interactions = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) => _searchMedications(value, true),
                          ),
                          if (_isSearching1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (_searchResults1.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults1.length,
                                itemBuilder: (context, index) {
                                  final medication = _searchResults1[index];
                                  return ListTile(
                                    title: Text(medication.tradeName),
                                    subtitle: Text(medication.active),
                                    onTap: () => _selectMedication(medication, true),
                                  );
                                },
                              ),
                            ),
                          if (_selectedMedication1 != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الدواء المحدد: ${_selectedMedication1!.tradeName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('المادة الفعالة: ${_selectedMedication1!.active}'),
                                  Text('الشركة المصنعة: ${_selectedMedication1!.company}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // الدواء الثاني
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الدواء الثاني',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController2,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن الدواء الثاني',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: _searchController2.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController2.clear();
                                          _searchResults2 = [];
                                          _selectedMedication2 = null;
                                          _interactions = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) => _searchMedications(value, false),
                          ),
                          if (_isSearching2)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (_searchResults2.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults2.length,
                                itemBuilder: (context, index) {
                                  final medication = _searchResults2[index];
                                  return ListTile(
                                    title: Text(medication.tradeName),
                                    subtitle: Text(medication.active),
                                    onTap: () => _selectMedication(medication, false),
                                  );
                                },
                              ),
                            ),
                          if (_selectedMedication2 != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الدواء المحدد: ${_selectedMedication2!.tradeName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('المادة الفعالة: ${_selectedMedication2!.active}'),
                                  Text('الشركة المصنعة: ${_selectedMedication2!.company}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // نتائج التفاعلات
                  if (_interactions.isNotEmpty)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'التفاعلات الدوائية',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(_interactions.length, (index) {
                              final interaction = _interactions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(interaction.severityLevel).withOpacity(0.1),
                                  border: Border.all(
                                    color: _getSeverityColor(interaction.severityLevel),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getSeverityColor(interaction.severityLevel),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getSeverityLevelArabic(interaction.severityLevel),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'التأثير:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(interaction.effectAr),
                                    const SizedBox(height: 8),
                                    Text(
                                      'آلية التفاعل:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(interaction.mechanismAr),
                                    const SizedBox(height: 8),
                                    Text(
                                      'كيفية التعامل:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(interaction.managementAr),
                                    if (interaction.reference.isNotEmpty) ...[  
                                      const SizedBox(height: 8),
                                      Text(
                                        'المرجع:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(interaction.reference),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    )
                  else if (_selectedMedication1 != null && _selectedMedication2 != null)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد تفاعلات دوائية معروفة بين هذين الدواءين',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ملاحظة: هذا لا يعني بالضرورة أنه لا توجد تفاعلات، يرجى استشارة الطبيب أو الصيدلي دائمًا',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }