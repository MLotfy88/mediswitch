import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Removed unused import: import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mediswitch/blocs/language_bloc.dart';
import 'package:mediswitch/blocs/notification_bloc.dart';
import 'package:mediswitch/blocs/theme_bloc.dart';
import 'package:mediswitch/screens/example_screen.dart';
import 'package:mediswitch/screens/search_screen.dart';
import 'package:mediswitch/utils/app_theme.dart';
import 'package:mediswitch/services/database_update.dart';
import 'package:mediswitch/services/csv_import_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mediswitch/services/medication_service.dart';

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

  // Update database with new tables for dose comparison and weight calculator
  await DatabaseUpdate.instance.updateDatabase();

  // Import CSV data into database
  await CsvImportService.importCsvData();

  // Load medications into MedicationService
  final medicationService = MedicationService();
  await medicationService.loadMedicationsFromCSV();

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
                theme: ThemeData.from(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                ),
                darkTheme: ThemeData.from(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                ),
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

  final List<Widget> _screens = [const SearchScreen(), const ExampleScreen()];

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
          NavigationDestination(
            icon: Icon(TablerIcons.components),
            label: 'المكونات',
          ),
        ],
      ),
    );
  }
}
