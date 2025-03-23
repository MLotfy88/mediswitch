import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediswitch/blocs/language_bloc.dart';
import 'package:mediswitch/blocs/theme_bloc.dart';
import 'package:mediswitch/utils/tailwind_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: TailwindUtils.p4,
        children: [
          // Theme settings
          _buildSectionTitle(context, 'المظهر'),
          _buildThemeSelector(context),
          const SizedBox(height: 16),
          
          // Language settings
          _buildSectionTitle(context, 'اللغة'),
          _buildLanguageSelector(context),
          const SizedBox(height: 16),
          
          // App info
          _buildSectionTitle(context, 'معلومات التطبيق'),
          _buildInfoCard(
            context,
            'الإصدار',
            '1.0.0',
            Icons.info_outline,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final themeMode = state is ThemeLoaded ? state.themeMode : ThemeMode.system;
        
        return Card(
          child: Column(
            children: [
              _buildThemeOption(
                context,
                'نظام',
                'استخدام إعدادات النظام',
                Icons.settings_suggest,
                themeMode == ThemeMode.system,
                () => context.read<ThemeBloc>().add(ThemeChanged(themeMode == ThemeMode.system)),
              ),
              const Divider(),
              _buildThemeOption(
                context,
                'فاتح',
                'وضع النهار',
                Icons.light_mode,
                themeMode == ThemeMode.light,
                () => context.read<ThemeBloc>().add(ThemeChanged(false)),
              ),
              const Divider(),
              _buildThemeOption(
                context,
                'داكن',
                'وضع الليل',
                Icons.dark_mode,
                themeMode == ThemeMode.dark,
                () => context.read<ThemeBloc>().add(ThemeChanged(true)),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLanguageSelector(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final locale = state is LanguageLoaded ? state.locale : const Locale('ar');
        
        return Card(
          child: Column(
            children: [
              _buildLanguageOption(
                context,
                'العربية',
                'Arabic',
                Icons.language,
                locale.languageCode == 'ar',
                () => context.read<LanguageBloc>().add(LanguageChanged('ar')),
              ),
              const Divider(),
              _buildLanguageOption(
                context,
                'English',
                'الإنجليزية',
                Icons.language,
                locale.languageCode == 'en',
                () => context.read<LanguageBloc>().add(LanguageChanged('en')),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: onTap,
    );
  }
  
  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: onTap,
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}