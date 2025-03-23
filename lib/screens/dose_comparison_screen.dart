import 'package:flutter/material.dart';
import 'package:mediswitch/models/dose_equivalent.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/database_update.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Chart data class for visualization
class _ChartData {
  final String x;
  final double y;

  _ChartData(this.x, this.y);
}

class DoseComparisonScreen extends StatefulWidget {
  const DoseComparisonScreen({Key? key}) : super(key: key);

  @override
  State<DoseComparisonScreen> createState() => _DoseComparisonScreenState();
}

class _DoseComparisonScreenState extends State<DoseComparisonScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();

  Medication? _selectedMedication;
  List<Medication> _searchResults = [];
  List<DoseEquivalent> _equivalents = [];
  Map<int, Medication> _equivalentMedications = {};
  bool _isLoading = false;
  String _selectedUnit = 'mg';
  double _enteredDose = 0.0;
  bool _showComparisonChart = false;

  // تبويبات لعرض المقارنة بطرق مختلفة
  late TabController _tabController;

  final List<String> _availableUnits = [
    'mg',
    'mcg',
    'g',
    'ml',
    'IU',
    'mmol',
    'مل',
    'وحدة'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _doseController.dispose();
    _tabController.dispose();
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
      _showErrorSnackBar('حدث خطأ أثناء البحث: \$e');
    }
  }

  Future<void> _selectMedication(Medication medication) async {
    setState(() {
      _isLoading = true;
      _selectedMedication = medication;
      _searchResults = [];
      _searchController.text = medication.tradeName;
    });

    try {
      // الحصول على مكافئات الجرعات للدواء المحدد
      final equivalentsData =
          await DatabaseUpdate.instance.getDoseEquivalents(medication.id!);

      final List<DoseEquivalent> equivalents = [];
      final Map<int, Medication> equivalentMeds = {};

      for (final data in equivalentsData) {
        final equivalent = DoseEquivalent.fromJson(data);
        equivalents.add(equivalent);

        // الحصول على معلومات الدواء المكافئ
        final eqMed =
            await DatabaseService.instance.getMedicationById(equivalent.equivalentMedicationId);
        if (eqMed != null) {
          equivalentMeds[equivalent.equivalentMedicationId] = eqMed;
        }
      }

      setState(() {
        _equivalents = equivalents;
        _equivalentMedications = equivalentMeds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل بيانات المكافئات: \$e');
    }
  }

  void _calculateEquivalentDoses() {
    if (_doseController.text.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال الجرعة');
      return;
    }

    try {
      final enteredDose = double.parse(_doseController.text);
      setState(() {
        _enteredDose = enteredDose;
        _showComparisonChart = true;
        // التمرير لأسفل لعرض النتائج
        Future.delayed(const Duration(milliseconds: 300), () {
          Scrollable.ensureVisible(
            _resultsKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      });
      // إخفاء لوحة المفاتيح
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showErrorSnackBar('الرجاء إدخال قيمة رقمية صحيحة');
    }
  }

  // مفتاح عالمي للوصول إلى قسم النتائج
  final GlobalKey _resultsKey = GlobalKey();

  void _shareResults() {
    if (_selectedMedication == null || _equivalents.isEmpty) {
      return;
    }

    final stringBuilder = StringBuffer();
    stringBuilder.writeln('مقارنة الجرعات المكافئة - MediSwitch');
    stringBuilder.writeln('الدواء: \${_selectedMedication!.tradeName}');
    stringBuilder.writeln('المادة الفعالة: \${_selectedMedication!.active}');
    stringBuilder.writeln('الجرعة: \$_enteredDose \$_selectedUnit');
    stringBuilder.writeln('\nالمكافئات:');

    for (final equivalent in _equivalents) {
      final eqMed = _equivalentMedications[equivalent.equivalentMedicationId];
      if (eqMed != null) {
        final eqDose = equivalent.calculateEquivalentDose(_enteredDose);
        stringBuilder.writeln(
            '\${eqMed.tradeName}: \${eqDose.toStringAsFixed(2)} \${equivalent.unit}');
        stringBuilder.writeln('المادة الفعالة: \${eqMed.active}');
        stringBuilder.writeln('معامل التحويل: \${equivalent.conversionFactor}');
        stringBuilder.writeln('الفعالية: \${equivalent.efficacyPercentage}%');
        stringBuilder
            .writeln('احتمالية الآثار الجانبية: \${equivalent.toxicityPercentage}%');
        if (equivalent.notes.isNotEmpty) {
          stringBuilder.writeln('ملاحظات: \${equivalent.notes}');
        }
        stringBuilder.writeln('');
      }
    }

    stringBuilder.writeln('\nتم إنشاء هذه المقارنة بواسطة تطبيق MediSwitch');

    Share.share(stringBuilder.toString());
  }

  // فتح صفحة معلومات عن الدواء على الإنترنت
  void _openMedicationInfo(String medicationName) async {
    final url =
        Uri.parse('https://www.drugs.com/search.php?searchterm=\$medicationName');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('لا يمكن فتح الرابط');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة الجرعات المكافئة'),
        actions: [
          if (_selectedMedication != null && _equivalents.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
              tooltip: 'مشاركة النتائج',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () =>
                  _openMedicationInfo(_selectedMedication!.tradeName),
              tooltip: 'معلومات عن الدواء',
            ),
          ],
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
                            'اختر الدواء الأصلي',
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
                  // قسم إدخال الجرعة
                  if (_selectedMedication != null)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدواء المحدد: \${_selectedMedication!.tradeName}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text('أدخل الجرعة:'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _doseController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'الجرعة',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedUnit,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _availableUnits.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedUnit = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _calculateEquivalentDoses,
                                child: const Text('حساب الجرعات المكافئة'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // قسم عرض النتائج
                  if (_selectedMedication != null &&
                      _enteredDose > 0 &&
                      _equivalents.isNotEmpty)
                    Card(
                      key: _resultsKey,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'الجرعات المكافئة',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: Icon(_showComparisonChart
                                      ? Icons.bar_chart
                                      : Icons.show_chart),
                                  onPressed: () {
                                    setState(() {
                                      _showComparisonChart = !_showComparisonChart;
                                    });
                                  },
                                  tooltip: 'عرض/إخفاء الرسم البياني المقارن',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // تبويبات لعرض المقارنة بطرق مختلفة
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'قائمة'),
                                Tab(text: 'مخطط'),
                                Tab(text: 'جدول'),
                              ],
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorSize: TabBarIndicatorSize.tab,
                            ),
                            SizedBox(
                              height: _equivalents.length *
                                  280.0, // ارتفاع ديناميكي حسب عدد الأدوية
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // عرض القائمة
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _equivalents.length,
                                    itemBuilder: (context, index) {
                                      final equivalent = _equivalents[index];
                                      final eqMed = _equivalentMedications[
                                          equivalent.equivalentMedicationId];
                                      if (eqMed == null) {
                                        return const SizedBox.shrink();
                                      }

                                      final equivalentDose =
                                          equivalent.calculateEquivalentDose(_enteredDose);

                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Content for the card
                                              ListTile(
                                                title: Text(eqMed.tradeName),
                                                subtitle: Text(eqMed.arabicName),
                                                trailing: Text(
                                                  '\$equivalentDose \${equivalent.unit}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // عرض المخطط
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _equivalents.length,
                                    itemBuilder: (context, index) {
                                      final equivalent = _equivalents[index];
                                      final eqMed = _equivalentMedications[
                                          equivalent.equivalentMedicationId];
                                      if (eqMed == null) {
                                        return const SizedBox.shrink();
                                      }

                                      final equivalentDose =
                                          equivalent.calculateEquivalentDose(_enteredDose);

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            title: Text(eqMed.tradeName),
                                            subtitle: Text(eqMed.arabicName),
                                            trailing: Text(
                                              '\$equivalentDose \${equivalent.unit}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'معامل التحويل: \${equivalent.conversionFactor}'),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text('الفعالية:'),
                                                          LinearProgressIndicator(
                                                            value: equivalent.efficacyPercentage / 100,
                                                            backgroundColor:
                                                                Colors.grey[300]!,
                                                            valueColor:
                                                                const AlwaysStoppedAnimation<Color>(
                                                                    Colors.green),
                                                          ),
                                                          Text(
                                                              '\${equivalent.efficacyPercentage.toStringAsFixed(1)}%'),
                                                          const SizedBox(height: 8),
                                                          SizedBox(
                                                            height: 120,
                                                            child: SfCircularChart(
                                                              margin: EdgeInsets.zero,
                                                              annotations: const [
                                                                CircularChartAnnotation(
                                                                  widget: Text(
                                                                    '\${equivalent.efficacyPercentage.toStringAsFixed(0)}%',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold),
                                                                  ),
                                                                ),
                                                              ],
                                                              series: <CircularSeries>[
                                                                DoughnutSeries<_ChartData,
                                                                    String>(
                                                                  dataSource: const [
                                                                    _ChartData('فعالية',
                                                                        100),
                                                                    _ChartData('غير فعال',
                                                                        0),
                                                                  ],
                                                                  xValueMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.x,
                                                                  yValueMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.y,
                                                                  pointColorMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.x == 'فعالية'
                                                                              ? Colors.green
                                                                              : Colors.grey[
                                                                                  300]!,
                                                                  innerRadius:
                                                                      '60%',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              'احتمالية الآثار الجانبية:'),
                                                          LinearProgressIndicator(
                                                            value: equivalent
                                                                    .toxicityPercentage /
                                                                100,
                                                            backgroundColor:
                                                                Colors.grey[300]!,
                                                            valueColor:
                                                                const AlwaysStoppedAnimation<
                                                                    Color>(
                                                              Colors.red,
                                                            ),
                                                          ),
                                                          Text(
                                                              '\${equivalent.toxicityPercentage.toStringAsFixed(1)}%'),
                                                          const SizedBox(height: 8),
                                                          SizedBox(
                                                            height: 120,
                                                            child: SfCircularChart(
                                                              margin: EdgeInsets.zero,
                                                              annotations: [
                                                                CircularChartAnnotation(
                                                                  widget: Text(
                                                                    '\${equivalent.toxicityPercentage.toStringAsFixed(0)}%',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold),
                                                                  ),
                                                                ),
                                                              ],
                                                              series: <CircularSeries>[
                                                                DoughnutSeries<_ChartData,
                                                                    String>(
                                                                  dataSource: const [
                                                                    _ChartData('آثار جانبية',
                                                                        0),
                                                                    _ChartData('آمن',
                                                                        100),
                                                                  ],
                                                                  xValueMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.x,
                                                                  yValueMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.y,
                                                                  pointColorMapper:
                                                                      (_ChartData data,
                                                                              _) =>
                                                                          data.x == 'آثار جانبية'
                                                                              ? Colors.red
                                                                              : Colors.grey[
                                                                                  300]!,
                                                                  innerRadius:
                                                                      '60%',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (equivalent.notes.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text('ملاحظات: \${equivalent.notes}'),
                                          ],
                                          const Divider(height: 24),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // عرض المخطط البياني المقارن
                                  _showComparisonChart
                                      ? _buildComparisonChart()
                                      : Container(),
                                  // عرض الجدول
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.all(Colors.grey[200]),
                                      columns: const [
                                        DataColumn(label: Text('الدواء')),
                                        DataColumn(label: Text('الجرعة المكافئة')),
                                        DataColumn(label: Text('معامل التحويل')),
                                        DataColumn(label: Text('الفعالية')),
                                        DataColumn(label: Text('الآثار الجانبية')),
                                      ],
                                      rows: _equivalents.map((equivalent) {
                                        final eqMed = _equivalentMedications[
                                            equivalent.equivalentMedicationId];
                                        if (eqMed == null) {
                                          return const DataRow(cells: []);
                                        }

                                        final equivalentDose =
                                            equivalent.calculateEquivalentDose(_enteredDose);

                                        return DataRow(cells: [
                                          DataCell(Text(eqMed.tradeName)),
                                          DataCell(Text(
                                              '\${equivalentDose.toStringAsFixed(2)} \${equivalent.unit}')),
                                          DataCell(Text('\${equivalent.conversionFactor}')),
                                          DataCell(
                                            Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                  ),
                                                  child: LinearProgressIndicator(
                                                    value: equivalent
                                                            .efficacyPercentage /
                                                        100,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                            Color>(Colors.green),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                    '\${equivalent.efficacyPercentage.toStringAsFixed(0)}%'),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                  ),
                                                  child: LinearProgressIndicator(
                                                    value: equivalent
                                                            .toxicityPercentage /
                                                        100,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                            Color>(Colors.red),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                    '\${equivalent.toxicityPercentage.toStringAsFixed(0)}%'),
                                              ],
                                            ),
                                          )
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
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

  // إظهار مربع حوار إضافة مكافئ جرعة جديد
   _showAddEquivalentDialog() {
    if (_selectedMedication == null) return;

    final TextEditingController searchController = TextEditingController();
    final TextEditingController conversionFactorController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    double efficacyPercentage = 100.0;
    double toxicityPercentage = 0.0;
    String selectedUnit = 'mg';
    List<Medication> searchResults = [];
    Medication? selectedEquivalentMedication;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة مكافئ جرعة جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الدواء الأصلي:'),
                  Text(
                    _selectedMedication!.tradeName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('ابحث عن الدواء المكافئ:'),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'اسم الدواء المكافئ',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) async {
                      if (query.isEmpty) {
                        setState(() {
                          searchResults = [];
                        });
                        return;
                      }

                      final results =
                          await DatabaseService.instance.searchMedications(query);
                      setState(() {
                        searchResults = results;
                      });
                    },
                  ),
                  if (searchResults.isNotEmpty)
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final medication = searchResults[index];
                          return ListTile(
                            title: Text(medication.tradeName),
                            subtitle: Text(medication.arabicName),
                            onTap: () {
                              setState(() {
                                selectedEquivalentMedication = medication;
                                searchController.text = medication.tradeName;
                                searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  if (selectedEquivalentMedication != null) ...[
                    const SizedBox(height: 16),
                    const Text('معامل التحويل:'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: conversionFactorController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'معامل التحويل',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedUnit,
                          items: _availableUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedUnit = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('الفعالية (%):'),
                    Slider(
                      value: efficacyPercentage,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: efficacyPercentage.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          efficacyPercentage = value;
                        });
                      },
                    ),
                    Text('\$efficacyPercentage%'),
                    const SizedBox(height: 16),
                    const Text('احتمالية الآثار الجانبية (%):'),
                    Slider(
                      value: toxicityPercentage,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: toxicityPercentage.toStringAsFixed(0),
                      activeColor: Colors.red,
                      onChanged: (value) {
                        setState(() {
                          toxicityPercentage = value;
                        });
                      },
                    ),
                    Text('\$toxicityPercentage%'),
                    const SizedBox(height: 16),
                    const Text('ملاحظات:'),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'ملاحظات إضافية',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedEquivalentMedication == null
                    ? null
                    : () async {
                      if (conversionFactorController.text.isEmpty) {
                        _showErrorSnackBar('الرجاء إدخال معامل التحويل');
                        return;
                      }

                      try {
                        final conversionFactor =
                            double.parse(conversionFactorController.text);

                        // إنشاء مكافئ جرعة جديد
                        final newEquivalent = {
                          'medication_id': _selectedMedication!.id,
                          'equivalent_medication_id':
                              selectedEquivalentMedication!.id,
                          'conversion_factor': conversionFactor,
                          'unit': selectedUnit,
                          'notes': notesController.text,
                          'efficacy_percentage': efficacyPercentage,
                          'toxicity_percentage': toxicityPercentage,
                        };

                        // حفظ في قاعدة البيانات
                        await DatabaseUpdate.instance
                            .insertDoseEquivalent(newEquivalent);

                        // إعادة تحميل البيانات
                        if (_selectedMedication != null) {
                          await _selectMedication(_selectedMedication!);
                        }

                        Navigator.pop(context);
                        _showErrorSnackBar('تمت إضافة المكافئ بنجاح');
                      } catch (e) {
                        _showErrorSnackBar('حدث خطأ: $e');
                      }
                    },
              ),
            ],
          );
        },
      ),
    );
  }
}
