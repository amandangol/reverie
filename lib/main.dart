import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/gallery/pages/albums/album_page.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:reverie/widgets/app_drawer.dart';
import 'features/about/pages/features_screen.dart';
import 'features/gallery/pages/gallery_page.dart';
import 'features/gallery/pages/media_detail_view.dart';
import 'features/gallery/pages/recap/recap_screen.dart';
import 'features/gallery/pages/smart_search_screen.dart';
import 'features/journal/models/journal_entry.dart';
import 'features/journal/pages/all_journals_screen.dart';
import 'features/journal/pages/journal_detail_screen.dart';
import 'features/journal/pages/journal_screen.dart';
import 'features/permissions/provider/permission_provider.dart';
import 'features/quickaccess/pages/quickaccess_screen.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/gallery/provider/media_provider.dart';
import 'features/gallery/provider/photo_operations_provider.dart';
import 'features/gallery/provider/flashback_provider.dart';
import 'theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/gallery_preferences_provider.dart';
import 'features/gallery/pages/flashbacks/flashbacks_screen.dart';
import 'features/journal/widgets/journal_entry_form.dart';
import 'features/onboarding/pages/onboarding_screen.dart';
import 'features/onboarding/provider/onboarding_provider.dart';
import 'features/backupdrive/provider/backup_provider.dart';

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
        ChangeNotifierProvider(create: (_) => FlashbackProvider()),
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
        '/recap': (context) => const RecapScreen(),
        '/journal/new': (context) => JournalEntryForm(
              onSave: (title, content, mediaIds, mood, tags, {lastEdited}) {
                // Handle saving new journal entry
                Navigator.pop(context);
              },
            ),
        '/journal/edit': (context) => JournalEntryForm(
              initialTitle: '',
              initialContent: '',
              initialMediaIds: const [],
              initialMood: '',
              initialTags: const [],
              onSave: (title, content, mediaIds, mood, tags, {lastEdited}) {
                Navigator.pop(context);
              },
              onDelete: () {
                Navigator.pop(context);
              },
            ),
        '/media/detail': (context) => MediaDetailView(),
        '/journal/detail': (context) => JournalDetailScreen(
              entry: JournalEntry(
                id: '',
                title: '',
                content: '',
                date: DateTime.now(),
                mediaIds: const [],
                mood: '',
                tags: const [],
                lastEdited: DateTime.now(),
              ),
            ),
        '/journals': (context) => const AllJournalsScreen(),
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
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onNavigation: (page) {
          _scaffoldKey.currentState?.closeDrawer();
          if (page is QuickAccessScreen ||
              page is FlashbacksScreen ||
              page is SettingsPage ||
              page is FeaturesScreen) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          }
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          GalleryPage(
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          JournalScreen(
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_rounded),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_rounded),
            label: 'Journal',
          ),
        ],
      ),
    );
  }
}
