import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediswitch/blocs/language_bloc.dart';
import 'package:mediswitch/blocs/notification_bloc.dart';
import 'package:mediswitch/blocs/theme_bloc.dart';
import 'package:mediswitch/screens/privacy_policy_screen.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:in_app_review/in_app_review.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme settings
          _buildSectionHeader('المظهر', theme),
          _buildThemeSettings(theme),
          const Divider(),
          
          // Language settings
          _buildSectionHeader('اللغة', theme),
          _buildLanguageSettings(theme),
          const Divider(),
          
          // Notification settings
          _buildSectionHeader('الإشعارات', theme),
          _buildNotificationSettings(theme),
          const Divider(),
          
          // About section
          _buildSectionHeader('حول التطبيق', theme),
          _buildAboutSettings(theme),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildThemeSettings(ThemeData theme) {
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
      final isDarkMode = state is ThemeLoaded ? state.isDarkMode : false;
      
      return SwitchListTile(
        title: const Text('الوضع الداكن'),
        subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
        value: isDarkMode,
        onChanged: (value) {
          context.read<ThemeBloc>().add(ThemeChanged(value));
        },
        secondary: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: theme.colorScheme.primary,
        ),
      );
    });
  }
  
  Widget _buildLanguageSettings(ThemeData theme) {
    return BlocBuilder<LanguageBloc, LanguageState>(builder: (context, state) {
      final selectedLanguage = state is LanguageLoaded ? state.languageCode : 'ar';
      
      return Column(
        children: [
          RadioListTile<String>(
            title: const Text('العربية'),
            value: 'ar',
            groupValue: selectedLanguage,
            onChanged: (value) {
              if (value != null) {
                context.read<LanguageBloc>().add(LanguageChanged(value));
              }
            },
            secondary: const Icon(Icons.language),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: selectedLanguage,
            onChanged: (value) {
              if (value != null) {
                context.read<LanguageBloc>().add(LanguageChanged(value));
              }
            },
            secondary: const Icon(Icons.language),
          ),
        ],
      );
    });
  }
  
  Widget _buildNotificationSettings(ThemeData theme) {
    return BlocBuilder<NotificationBloc, NotificationState>(builder: (context, state) {
      final notificationsEnabled = state is NotificationLoaded ? state.isEnabled : true;
      
      return SwitchListTile(
        title: const Text('تفعيل الإشعارات'),
        subtitle: const Text('الحصول على إشعارات عند تحديث أسعار الأدوية'),
        value: notificationsEnabled,
        onChanged: (value) {
          context.read<NotificationBloc>().add(NotificationStatusChanged(value));
        },
        secondary: Icon(
          notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: theme.colorScheme.primary,
        ),
      );
    });
  }
  
  Widget _buildAboutSettings(ThemeData theme) {
    return Column(
      children: [
        ListTile(
          title: const Text('عن التطبيق'),
          subtitle: const Text('معلومات عن التطبيق والمطورين'),
          leading: Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          onTap: () {
            _showAboutDialog();
          },
        ),
        ListTile(
          title: const Text('سياسة الخصوصية'),
          subtitle: const Text('قراءة سياسة الخصوصية للتطبيق'),
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: theme.colorScheme.primary,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            );
          },
        ),
        ListTile(
          title: const Text('تقييم التطبيق'),
          subtitle: const Text('قم بتقييم التطبيق على متجر التطبيقات'),
          leading: Icon(
            Icons.star_outline,
            color: theme.colorScheme.primary,
          ),
          onTap: () {
            // Implement app rating
            final InAppReview inAppReview = InAppReview.instance;
            inAppReview.openStoreListing(
              appStoreId: '123456789', // Replace with your iOS App Store ID when available
            );
          },
        ),
        ListTile(
          title: const Text('الإصدار'),
          subtitle: const Text('1.0.0'),
          leading: Icon(
            Icons.update,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'ميديسويتش',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(
          Icons.medication_rounded,
          size: 48,
          color: AppTheme.primaryColor,
        ),
        applicationLegalese: '© 2023 ميديسويتش. جميع الحقوق محفوظة.',
        children: [
          const SizedBox(height: 16),
          const Text(
            'تطبيق ميديسويتش هو دليل شامل للأدوية يساعدك على البحث عن الأدوية ومعرفة أسعارها والبدائل المتاحة.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}