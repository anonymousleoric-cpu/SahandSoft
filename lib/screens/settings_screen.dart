import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config_repository.dart';
import '../core/v2ray_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';
import 'about_screen.dart';
import 'blocked_apps_screen.dart';
import 'language_screen.dart';

/// ---------------------------------------------------------------------------
/// SettingsScreen — fully custom SahandSoft settings design.
/// ---------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.service,
    required this.repository,
    required this.themeMode,
  });

  final V2RayService service;
  final ConfigRepository repository;

  /// Shared with the MaterialApp so theme changes apply instantly.
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLanguage =
          prefs.getString('selectedLanguage') ?? 'فارسی';
    });
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('setting'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ---- Appearance ------------------------------------------------
            SectionHeader(title: context.tr('appearance_section')),
            SahandCard(
              child: Column(
                children: [
                  _ThemeModeRow(themeMode: widget.themeMode),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---- Network ---------------------------------------------------
            SectionHeader(title: context.tr('network_section')),
            SahandOptionTile(
              icon: Icons.app_blocking_rounded,
              title: context.tr('block_application'),
              description: context.tr('block_detail_short'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        BlockedAppsScreen(repository: widget.repository),
                  ),
                );
              },
            ),

            // ---- Language ---------------------------------------------------
            SectionHeader(title: context.tr('language_settings')),
            SahandOptionTile(
              icon: Icons.translate_rounded,
              title: context.tr('language'),
              description: _selectedLanguage ?? 'فارسی',
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => LanguageScreen(
                      selectedLanguage:
                          _selectedLanguage ?? 'فارسی',
                    ),
                  ),
                )
                    .then((_) {
                  _loadSelectedLanguage();
                });
              },
            ),

            // ---- About -------------------------------------------------------
            SectionHeader(title: context.tr('about_section')),
            SahandOptionTile(
              icon: Icons.info_outline_rounded,
              title: context.tr('about_app'),
              description: context.tr('about_app_desc'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => AboutScreen(
                      service: widget.service,
                      repository: widget.repository,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                context.tr('settings_footer'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme mode selector row (system / light / dark) — persisted + reactive.
class _ThemeModeRow extends StatefulWidget {
  const _ThemeModeRow({required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<_ThemeModeRow> createState() => _ThemeModeRowState();
}

class _ThemeModeRowState extends State<_ThemeModeRow> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String saved = prefs.getString('themeMode') ?? 'system';
    if (!mounted) return;
    widget.themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> _set(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    widget.themeMode.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.contrast_rounded, color: palette.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr('theme_mode'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeMode,
            builder: (BuildContext context, ThemeMode mode, _) {
              return SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                    label: Text(context.tr('theme_system')),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded, size: 18),
                    label: Text(context.tr('theme_light')),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded, size: 18),
                    label: Text(context.tr('theme_dark')),
                  ),
                ],
                selected: <ThemeMode>{mode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  _set(selection.first);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
