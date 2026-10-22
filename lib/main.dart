import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:safe_device/safe_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config_repository.dart';
import 'core/v2ray_service.dart';
import 'screens/about_screen.dart';
import 'screens/home_screen.dart';
import 'screens/servers_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';
import 'widgets/navigation_rail_widget.dart';

/// ---------------------------------------------------------------------------
/// SahandSoft — secure VPN client (flutter_v2ray engine).
/// ---------------------------------------------------------------------------
/// Persian is the default language; English, Chinese and Russian are also
/// supported. Light & dark themes follow the system unless overridden in
/// Settings. The app refuses to run on jailbroken/rooted devices (same
/// security policy as the upstream project).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isJailBroken = await SafeDeviceGuard.isJailBroken;
  if (!isJailBroken) {
    await EasyLocalization.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    runApp(
      EasyLocalization(
        supportedLocales: const <Locale>[
          Locale('fa', 'IR'), // default
          Locale('en', 'US'),
          Locale('zh', 'CN'),
          Locale('ru', 'RU'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        startLocale: const Locale('fa', 'IR'),
        saveLocale: true,
        child: const SahandSoftApp(),
      ),
    );
  }
}

/// Isolated root-detection guard so the check stays swappable.
class SafeDeviceGuard {
  static Future<bool> get isJailBroken async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      return false;
    }
  }
}

class SahandSoftApp extends StatefulWidget {
  const SahandSoftApp({super.key});

  @override
  State<SahandSoftApp> createState() => _SahandSoftAppState();
}

class _SahandSoftAppState extends State<SahandSoftApp> {
  /// App-wide theme mode; SettingsScreen writes into it and persists it.
  final ValueNotifier<ThemeMode> _themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String saved = prefs.getString('themeMode') ?? 'system';
    _themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (BuildContext context, ThemeMode mode, _) {
        return MaterialApp(
          title: 'SahandSoft',
          debugShowCheckedModeBanner: false,
          theme: SahandTheme.light(),
          darkTheme: SahandTheme.dark(),
          themeMode: mode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: RootShell(themeMode: _themeMode),
        );
      },
    );
  }
}

/// Bottom navigation (phones) / side rail (wide screens) shell.
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;
  late final V2RayService _service;
  final ConfigRepository _repository = ConfigRepository();
  bool _serviceReady = false;

  @override
  void initState() {
    super.initState();
    _service = V2RayService();
    _initService();
  }

  Future<void> _initService() async {
    try {
      await _service.initialize();
      if (!mounted) return;
      setState(() => _serviceReady = true);
    } catch (e) {
      debugPrint('V2Ray init failed: $e');
      if (mounted) setState(() => _serviceReady = false);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.sizeOf(context).width > 800;

    if (!_serviceReady) {
      return const _BootScreen();
    }

    final List<Widget> pages = <Widget>[
      HomePage(service: _service, repository: _repository),
      ServersScreen(
        service: _service,
        repository: _repository,
      ),
      SettingsScreen(
        service: _service,
        repository: _repository,
        themeMode: widget.themeMode,
      ),
      AboutScreen(service: _service, repository: _repository),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
          if (isWideScreen)
            NavigationRailWidget(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
            ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              destinations: <Widget>[
                NavigationDestination(
                  icon: Icon(Iconsax.home,
                      color: _navIconColor(context, 0)),
                  selectedIcon: Icon(Iconsax.home,
                      color: _navSelectedColor(context)),
                  label: context.tr('nav_home'),
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.setting,
                      color: _navIconColor(context, 1)),
                  selectedIcon: Icon(Iconsax.setting,
                      color: _navSelectedColor(context)),
                  label: context.tr('nav_servers'),
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.setting_2,
                      color: _navIconColor(context, 2)),
                  selectedIcon: Icon(Iconsax.setting_2,
                      color: _navSelectedColor(context)),
                  label: context.tr('setting'),
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.info_circle,
                      color: _navIconColor(context, 3)),
                  selectedIcon: Icon(Iconsax.info_circle,
                      color: _navSelectedColor(context)),
                  label: context.tr('about'),
                ),
              ],
            ),
    );
  }

  Color _navIconColor(BuildContext context, int index) {
    if (_selectedIndex == index) return _navSelectedColor(context);
    return SahandPalette.of(context).muted;
  }

  Color _navSelectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.brandBright
        : AppColors.brandDeep;
  }
}

/// Minimal splash-style boot screen while the V2Ray core initializes.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBg
              : AppColors.lightBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/images/sahand_logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('boot_loading'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
