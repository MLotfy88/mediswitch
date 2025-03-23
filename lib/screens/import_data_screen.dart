import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mediswitch/services/excel_import_service.dart';
import 'package:mediswitch/services/logging_service.dart';
import 'package:path/path.dart' as path;

/// شاشة استيراد البيانات من ملفات Excel/CSV
class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  // حالة الاستيراد
  bool _isImporting = false;
  bool _importComplete = false;
  bool _hasError = false;
  String _statusMessage = '';
  double _importProgress = 0.0;
  
  // نتائج الاستيراد
  Map<String, dynamic>? _importResult;
  
  // معاينة البيانات
  List<List<dynamic>>? _previewData;
  String? _selectedFilePath;
  String? _selectedFileName;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'استيراد البيانات' : 'Import Data'),
        actions: [
          if (_selectedFilePath != null && !_isImporting && !_importComplete)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _startImport,
              tooltip: isArabic ? 'بدء الاستيراد' : 'Start Import',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة اختيار الملف
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختيار ملف البيانات' : 'Select Data File',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic 
                          ? 'يمكنك استيراد البيانات من ملفات Excel (.xlsx, .xls) أو CSV (.csv)'
                          : 'You can import data from Excel (.xlsx, .xls) or CSV (.csv) files',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedFileName != null
                              ? Text(
                                  _selectedFileName!,
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  isArabic ? 'لم يتم اختيار ملف' : 'No file selected',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_open),
                          label: Text(isArabic ? 'اختيار ملف' : 'Choose File'),
                          onPressed: _isImporting ? null : _pickFile,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // حالة الاستيراد
            if (_isImporting || _importComplete || _hasError)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'حالة الاستيراد' : 'Import Status',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_isImporting)
                        Column(
                          children: [
                            LinearProgressIndicator(value: _importProgress),
                            const SizedBox(height: 8),
                            Text(
                              _statusMessage,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        )
                      else if (_importComplete)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'تم الاستيراد بنجاح' : 'Import Completed Successfully',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildImportResultSummary(isArabic),
                          ],
                        )
                      else if (_hasError)
                        Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // معاينة البيانات
            if (_previewData != null)
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'معاينة البيانات' : 'Data Preview',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildDataPreview(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// اختيار ملف Excel/CSV
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = path.basename(filePath);
        
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = fileName;
          _importComplete = false;
          _hasError = false;
          _statusMessage = '';
          _importResult = null;
        });
        
        // تحميل معاينة البيانات
        await _loadDataPreview(filePath);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'خطأ في اختيار الملف: $e';
      });
      await LoggingService.instance.error('خطأ في اختيار ملف الاستيراد', e);
    }
  }
  
  /// تحميل معاينة البيانات
  Future<void> _loadDataPreview(String filePath) async {
    try {
      setState(() {
        _isImporting = true;
        _statusMessage = 'جاري تحميل معاينة البيانات...';
        _importProgress = 0.2;
      });
      
      // استدعاء خدمة استيراد البيانات للحصول على معاينة
      final previewResult = await ExcelImportService.instance.getDataPreview(filePath);
      
      setState(() {
        _isImporting = false;
        
        if (previewResult['success']) {
          _previewData = previewResult['preview_data'];
        } else {
          _hasError = true;
          _statusMessage = previewResult['message'] ?? 'خطأ في تحميل معاينة البيانات';
        }
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _hasError = true;
        _statusMessage = 'خطأ في تحميل معاينة البيانات: $e';
      });
      await LoggingService.instance.error('خطأ في تحميل معاينة البيانات', e);
    }
  }
  
  /// بدء عملية الاستيراد
  Future<void> _startImport() async {
    if (_selectedFilePath == null) return;
    
    try {
      setState(() {
        _isImporting = true;
        _importComplete = false;
        _hasError = false;
        _statusMessage = 'جاري التحقق من الملف...';
        _importProgress = 0.1;
      });
      
      // التحقق من صحة الملف
      setState(() {
        _statusMessage = 'جاري التحقق من صحة الملف...';
        _importProgress = 0.3;
      });
      
      // بدء الاستيراد
      setState(() {
        _statusMessage = 'جاري استيراد البيانات...';
        _importProgress = 0.5;
      });
      
      // استدعاء خدمة استيراد البيانات
      final importResult = await ExcelImportService.instance.importFromExcel(_selectedFilePath!);
      
      setState(() {
        _isImporting = false;
        _importResult = importResult;
        
        if (importResult['success']) {
          _importComplete = true;
          _hasError = false;
          _statusMessage = 'تم استيراد البيانات بنجاح';
        } else {
          _importComplete = false;
          _hasError = true;
          _statusMessage = importResult['message'] ?? 'حدث خطأ أثناء استيراد البيانات';
        }
      });
    } catch (