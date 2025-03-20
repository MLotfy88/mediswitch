import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Removed unused import: import 'package:google_fonts/google_fonts.dart';
import 'package:mediswitch/blocs/language_bloc.dart';
import 'package:mediswitch/blocs/notification_bloc.dart';
import 'package:mediswitch/blocs/theme_bloc.dart';
import 'package:mediswitch/screens/home_screen.dart';
import 'package:mediswitch/screens/search_screen.dart';
import 'package:mediswitch/screens/favorites_screen.dart';
import 'package:mediswitch/screens/settings_screen.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the path_provider plugin for web
  if (kIsWeb) {
    await getApplicationDocumentsDirectory();
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database
  await DatabaseService.instance.initDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(LoadTheme()),
        ),
        BlocProvider<LanguageBloc>(
          create: (context) => LanguageBloc()..add(LoadLanguage()),
        ),
        BlocProvider<NotificationBloc>(
          create:
              (context) => NotificationBloc()..add(NotificationStatusLoaded()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, languageState) {
              final themeMode =
                  themeState is ThemeLoaded
                      ? themeState.themeMode
                      : ThemeMode.system;
              final locale =
                  languageState is LanguageLoaded
                      ? languageState.locale
                      : const Locale('ar');

              return MaterialApp(
                title: 'MediSwitch',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('ar'), // Arabic
                ],
                home: const MainScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const HomeScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
