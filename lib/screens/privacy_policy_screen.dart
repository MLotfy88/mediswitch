import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سياسة الخصوصية',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم تحديث هذه السياسة في: 1 يناير 2023',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              'مقدمة',
              'نحن في ميديسويتش نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك عند استخدام تطبيقنا.',
            ),
            _buildSection(
              theme,
              'المعلومات التي نجمعها',
              'نحن نجمع المعلومات التالية:\n\n- معلومات الجهاز (نوع الجهاز، إصدار نظام التشغيل)\n- سجل البحث داخل التطبيق\n- الأدوية المفضلة\n- إعدادات التطبيق (اللغة، المظهر، إعدادات الإشعارات)',
            ),
            _buildSection(
              theme,
              'كيف نستخدم معلوماتك',
              'نستخدم المعلومات التي نجمعها للأغراض التالية:\n\n- تحسين تجربة المستخدم\n- تخصيص محتوى التطبيق\n- إرسال إشعارات مفيدة (في حال تفعيلها)\n- تحليل استخدام التطبيق لتحسين الخدمات',
            ),
            _buildSection(
              theme,
              'مشاركة البيانات',
              'نحن لا نبيع أو نؤجر أو نتاجر ببياناتك الشخصية مع أطراف ثالثة. قد نشارك بيانات مجهولة المصدر لأغراض تحليلية فقط.',
            ),
            _buildSection(
              theme,
              'أمان البيانات',
              'نحن نتخذ تدابير أمنية مناسبة لحماية معلوماتك من الوصول غير المصرح به أو التعديل أو الإفصاح أو الإتلاف.',
            ),
            _buildSection(
              theme,
              'حقوقك',
              'لديك الحق في:\n\n- الوصول إلى بياناتك الشخصية\n- تصحيح بياناتك غير الدقيقة\n- حذف بياناتك\n- الاعتراض على معالجة بياناتك\n- سحب موافقتك في أي وقت',
            ),
            _buildSection(
              theme,
              'التغييرات على سياسة الخصوصية',
              'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سنخطرك بأي تغييرات جوهرية من خلال إشعار داخل التطبيق.',
            ),
            _buildSection(
              theme,
              'اتصل بنا',
              'إذا كان لديك أي أسئلة حول سياسة الخصوصية، يرجى التواصل معنا على:\n\nالبريد الإلكتروني: privacy@mediswitch.com',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}