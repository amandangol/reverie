import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'features/gallery/pages/gallery_page.dart';
import 'features/journal/pages/journal_screen.dart';
import 'features/permissions/provider/permission_provider.dart';
import 'features/quickaccess/pages/quickaccess_screen.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/gallery/provider/media_provider.dart';
import 'features/gallery/provider/photo_operations_provider.dart';
import 'theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/gallery_preferences_provider.dart';
import 'features/gallery/pages/flashbacks_screen.dart';
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

  final List<Widget> _pages = [
    const GalleryPage(),
    const JournalScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleDrawerNavigation(Widget page) {
    _scaffoldKey.currentState?.closeDrawer();
    if (page is QuickAccessScreen ||
        page is FlashbacksScreen ||
        page is SettingsPage) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Reverie',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Digital Memory Keeper',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Quick Access'),
              onTap: () => _handleDrawerNavigation(const QuickAccessScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Flashbacks'),
              onTap: () => _handleDrawerNavigation(const FlashbacksScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () => _handleDrawerNavigation(const SettingsPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About'),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                showAboutDialog(
                  context: context,
                  applicationName: 'Reverie',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/icon/icon.png',
                    width: 48,
                    height: 48,
                  ),
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Reverie is your personal digital memory keeper, helping you preserve and relive your precious moments.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
