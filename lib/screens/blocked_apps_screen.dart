import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// BlockedAppsScreen — apps excluded from the VPN tunnel.
/// Same behavior as upstream: selection is persisted and passed to
/// startV2Ray(blockedApps: ...) so the engine really excludes them.
/// ---------------------------------------------------------------------------
class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key, required this.repository});

  final ConfigRepository repository;

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  List<AppInfo>? _apps;
  List<AppInfo>? _filtered;
  List<String> _blockedApps = <String>[];
  bool _isLoading = true;
  bool _isSearchReady = false;
  bool _isLoadSystemApps = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(ConfigRepository.kBlockedApps) ?? <String>[];
    final bool systemApps = prefs.getBool('isLoadSystemApps') ?? false;
    if (!mounted) return;
    setState(() {
      _blockedApps = saved;
      _isLoadSystemApps = systemApps;
    });
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    // installed_apps v2 API: named options. excludeNonLaunchableApps is
    // disabled to preserve the upstream behavior of listing every app.
    final List<AppInfo> installed = await InstalledApps.getInstalledApps(
      excludeSystemApps: !_isLoadSystemApps,
      excludeNonLaunchableApps: false,
      withIcon: true,
    );
    if (!mounted) return;
    setState(() {
      _apps = installed
        ..sort((AppInfo a, AppInfo b) {
          final bool aBlocked = _blockedApps.contains(a.packageName);
          final bool bBlocked = _blockedApps.contains(b.packageName);
          return (bBlocked ? 1 : 0).compareTo(aBlocked ? 1 : 0);
        });
      _filtered = _apps;
      _isLoading = false;
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _isSearchReady = true);
      });
    });
  }

  void _filterApps() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _apps
          ?.where((AppInfo app) =>
              app.name.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query))
          .toList();
      _filtered?.sort((AppInfo a, AppInfo b) {
        final bool aBlocked = _blockedApps.contains(a.packageName);
        final bool bBlocked = _blockedApps.contains(b.packageName);
        return (bBlocked ? 1 : 0).compareTo(aBlocked ? 1 : 0);
      });
    });
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        ConfigRepository.kBlockedApps, _blockedApps);
    await prefs.setBool('isLoadSystemApps', _isLoadSystemApps);
  }

  void _toggle(String packageName) {
    setState(() {
      if (_blockedApps.contains(packageName)) {
        _blockedApps.remove(packageName);
      } else {
        _blockedApps.add(packageName);
      }
    });
    _persist();
  }

  void _toggleSystemApps() {
    setState(() {
      _isLoading = true;
      _isLoadSystemApps = !_isLoadSystemApps;
    });
    _persist();
    _loadApps();
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _isSearchReady ? 1.0 : 0.0,
          duration: AppDurations.normal,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.tr('search_application'),
              border: InputBorder.none,
              filled: false,
            ),
            enabled: _isSearchReady,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'toggleSystemApps') _toggleSystemApps();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              CheckedPopupMenuItem<String>(
                value: 'toggleSystemApps',
                checked: _isLoadSystemApps,
                child: Text(context.tr('show_system_apps')),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                  ),
                  child: SahandCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: Icons.app_blocking_rounded,
                          color: palette.warning,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            context.tr(
                              'excluded_count',
                              args: <String>['${_blockedApps.length}'],
                            ),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: (_filtered ?? <AppInfo>[]).isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: context.tr('no_apps_found'),
                          body: context.tr('no_apps_found_body'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _filtered!.length,
                          itemBuilder: (BuildContext context, int index) {
                            final AppInfo app = _filtered![index];
                            final bool isBlocked =
                                _blockedApps.contains(app.packageName);
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? palette.primary
                                        .withValues(alpha: 0.08)
                                    : palette.surface,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.md),
                                border: Border.all(
                                  color: isBlocked
                                      ? palette.primary
                                          .withValues(alpha: 0.4)
                                      : palette.outline,
                                ),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                onTap: () => _toggle(app.packageName),
                                leading: app.icon != null &&
                                        app.icon!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                        child: Image.memory(
                                          app.icon!,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : IconBadge(
                                        icon: Icons.android_rounded,
                                        color: palette.muted,
                                        size: 36,
                                      ),
                                title: Text(
                                  app.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                subtitle: Text(
                                  app.packageName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                                trailing: Checkbox(
                                  value: isBlocked,
                                  onChanged: (bool? value) =>
                                      _toggle(app.packageName),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
