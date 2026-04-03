import 'package:adscloneia/config/supabase_config.dart';
import 'package:adscloneia/screens/auth/login_screen.dart';
import 'package:adscloneia/screens/auth/register_screen.dart';
import 'package:adscloneia/screens/create_screen.dart';
import 'package:adscloneia/screens/gallery_screen.dart';
import 'package:adscloneia/screens/home_screen.dart';
import 'package:adscloneia/screens/settings_screen.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_theme.dart';
import 'package:adscloneia/theme/theme_prefs.dart';
import 'package:adscloneia/widgets/saas_sidebar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.anonKey.isEmpty) {
    throw StateError(
      'SUPABASE_ANON_KEY não definida. Use '
      '--dart-define=SUPABASE_ANON_KEY=<anon_key> ao rodar ou compilar.',
    );
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const AdscloneiaApp());
}

class AdscloneiaApp extends StatefulWidget {
  const AdscloneiaApp({super.key});

  @override
  State<AdscloneiaApp> createState() => _AdscloneiaAppState();
}

class _AdscloneiaAppState extends State<AdscloneiaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    ThemePrefs.load().then((m) {
      if (mounted) setState(() => _themeMode = m);
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await ThemePrefs.save(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'adscloneia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      navigatorKey: rootNavigatorKey,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            return const _AuthFlowShell();
          }
          return _MainShell(
            generationService: GenerationService(),
            themeMode: _themeMode,
            onThemeModeChanged: _setThemeMode,
          );
        },
      ),
    );
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Login ↔ registro antes da sessão existir.
class _AuthFlowShell extends StatefulWidget {
  const _AuthFlowShell();

  @override
  State<_AuthFlowShell> createState() => _AuthFlowShellState();
}

class _AuthFlowShellState extends State<_AuthFlowShell> {
  bool _register = false;

  @override
  Widget build(BuildContext context) {
    if (_register) {
      return RegisterScreen(
        onNavigateToLogin: () => setState(() => _register = false),
      );
    }
    return LoginScreen(
      onNavigateToRegister: () => setState(() => _register = true),
    );
  }
}

/// Largura mínima (web) para menu lateral em vez da barra inferior.
const double kWebSidebarBreakpoint = 840;

bool useWebSidebarLayout(BuildContext context) {
  if (!kIsWeb) return false;
  return MediaQuery.sizeOf(context).width >= kWebSidebarBreakpoint;
}

class _MainShell extends StatefulWidget {
  const _MainShell({
    required this.generationService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final GenerationService generationService;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    void goCreate() => setState(() => _index = 1);

    final pages = [
      HomeScreen(
        service: widget.generationService,
        onNavigateToCreate: goCreate,
      ),
      CreateScreen(service: widget.generationService),
      GalleryScreen(
        service: widget.generationService,
        onNavigateToCreate: goCreate,
      ),
      SettingsScreen(
        generationService: widget.generationService,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ];

    final sidebar = useWebSidebarLayout(context);

    if (sidebar) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaaSSidebar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: IndexedStack(
                  index: _index,
                  children: pages,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_photo_alternate_outlined),
            selectedIcon: Icon(Icons.add_photo_alternate_rounded),
            label: 'Criar',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Galeria',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
