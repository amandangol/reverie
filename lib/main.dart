import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'features/gallery/pages/gallery_page.dart';
import 'features/journal/pages/journal_screen.dart';
import 'features/permissions/provider/permission_provider.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/gallery/provider/media_provider.dart';
import 'features/gallery/provider/photo_operations_provider.dart';
import 'theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/gallery_preferences_provider.dart';
import 'features/gallery/pages/flashbacks_screen.dart';
import 'features/journal/widgets/journal_entry_form.dart';
import 'features/discover/pages/discover_screen.dart';
import 'features/onboarding/pages/onboarding_screen.dart';
import 'features/onboarding/provider/onboarding_provider.dart';
import 'features/backup/provider/backup_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => GalleryPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => PhotoOperationsProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reverie',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/flashbacks': (context) => const FlashbacksScreen(),
        '/journal/new': (context) => JournalEntryForm(
              onSave: (title, content, mediaIds, mood, tags, {lastEdited}) {
                // Handle saving new journal entry
                Navigator.pop(context);
              },
            ),
        '/journal/edit': (context) => JournalEntryForm(
              initialTitle: '', // Pass the entry to edit
              initialContent: '',
              initialMediaIds: const [],
              initialMood: '',
              initialTags: const [],
              onSave: (title, content, mediaIds, mood, tags, {lastEdited}) {
                // Handle updating journal entry
                Navigator.pop(context);
              },
              onDelete: () {
                // Handle deleting journal entry
                Navigator.pop(context);
              },
            ),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const GalleryPage(),
    const JournalScreen(),
    const QuicFeatureScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
