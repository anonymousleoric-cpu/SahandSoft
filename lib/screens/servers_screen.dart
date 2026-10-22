import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/config_repository.dart';
import '../core/models.dart';
import '../core/v2ray_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// ServersScreen — manage VPN profiles.
/// ---------------------------------------------------------------------------
/// Profiles come from two real sources: a pasted share-URI (vmess / vless /
/// trojan / ss ...) or a standard V2Ray subscription URL. No demo data.
class ServersScreen extends StatefulWidget {
  const ServersScreen({
    super.key,
    required this.service,
    required this.repository,
    this.onProfilesChanged,
  });

  final V2RayService service;
  final ConfigRepository repository;
  final VoidCallback? onProfilesChanged;

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  List<VpnProfile> _profiles = <VpnProfile>[];
  String? _selectedId;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<VpnProfile> profiles =
        await widget.repository.loadProfiles();
    final String? selectedId =
        await widget.repository.getSelectedProfileId();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _selectedId = selectedId;
    });
    widget.onProfilesChanged?.call();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- add flows ----------------------------------------------------------

  Future<void> _addManual() async {
    final TextEditingController controller = TextEditingController();
    final String? uri = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.tr('add_manual_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('add_manual_hint'),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.tr('config_uri_hint'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    if (uri == null || uri.trim().isEmpty) return;
    try {
      final VpnProfile? profile = await widget.repository.addFromUri(uri);
      if (profile == null) {
        _toast(context.tr('invalid_uri'));
        return;
      }
      _toast(context.tr('profile_added'));
    } catch (e) {
      _toast(context.tr('error_generic'));
    }
    await _reload();
  }

  Future<void> _addSubscription() async {
    final TextEditingController controller = TextEditingController();
    final String existing =
        await widget.repository.getSubscriptionUrl() ?? '';
    controller.text = existing;

    final String? url = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.tr('add_subscription_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('add_subscription_hint'),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: context.tr('subscription_url_hint'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    if (url == null) return;
    if (url.trim().isEmpty) {
      await widget.repository.setSubscriptionUrl(null);
      _toast(context.tr('subscription_cleared'));
      return;
    }

    setState(() => _testing = true);
    try {
      final int added = await widget.repository.importSubscription(url);
      _toast(context.tr('import_success', args: <String>['$added']));
    } on SubscriptionException catch (e) {
      _toast(context.tr('sub_error_${e.code}'));
    } on TimeoutException {
      _toast(context.tr('error_timeout'));
    } catch (e) {
      _toast(context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
    await _reload();
  }

  Future<void> _removeProfile(VpnProfile profile) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.tr('delete_title')),
        content: Text(
          context.tr('delete_body', args: <String>[profile.label]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  SahandPalette.of(context).danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.removeProfile(profile.id);
    await _reload();
  }

  // ---- delay test ----------------------------------------------------------

  Future<void> _testDelays() async {
    if (_profiles.isEmpty || _testing) return;
    setState(() => _testing = true);
    try {
      final Map<String, VpnProfile> configToProfile =
          <String, VpnProfile>{};
      for (final VpnProfile p in _profiles) {
        try {
          configToProfile[widget.service.fullConfigFromUri(p.uri)] = p;
        } catch (_) {}
      }
      final Map<String, int> delays =
          await widget.service.allDelays(configToProfile.keys.toList());
      delays.forEach((String config, int delay) {
        final VpnProfile? profile = configToProfile[config];
        if (profile != null) {
          widget.repository.updateDelay(profile.id, delay);
        }
      });
      _toast(context.tr('delay_test_done'));
    } catch (e) {
      _toast(context.tr('delay_test_failed'));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
    await _reload();
  }

  // ---- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('nav_servers'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _profiles.isEmpty
            ? EmptyState(
                icon: Icons.add_link_rounded,
                title: context.tr('empty_profiles_title'),
                body: context.tr('empty_profiles_body'),
                actionLabel: context.tr('add_first_config'),
                onAction: _addManual,
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addManual,
                          icon: const Icon(Icons.paste_rounded, size: 18),
                          label: Text(context.tr('add_manual')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addSubscription,
                          icon: const Icon(Icons.rss_feed_rounded,
                              size: 18),
                          label: Text(context.tr('add_subscription')),
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(
                    title: context.tr('profiles_count',
                        args: <String>['${_profiles.length}']),
                    action: TextButton.icon(
                      onPressed: _testing ? null : _testDelays,
                      icon: _testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.speed_rounded, size: 16),
                      label: Text(context.tr('test_delays')),
                    ),
                  ),
                  for (final VpnProfile profile in _profiles)
                    _ProfileCard(
                      profile: profile,
                      selected: _selectedId == profile.id,
                      onSelect: () {
                        setState(() => _selectedId = profile.id);
                        widget.repository
                            .setSelectedProfileId(profile.id);
                      },
                      onDelete: () => _removeProfile(profile),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      context.tr('profiles_footer'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final VpnProfile profile;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    final int? delay = profile.lastDelayMs;
    final Color delayColor = delay == null
        ? palette.muted
        : delay < 0
            ? palette.danger
            : delay < 300
                ? palette.success
                : delay < 800
                    ? palette.warning
                    : palette.danger;

    return SahandCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: onSelect,
      child: Row(
        children: [
          IconBadge(
            icon: selected
                ? Icons.check_circle_rounded
                : Icons.dns_rounded,
            color: selected ? palette.primary : palette.muted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.uri.split('://').first.toUpperCase() +
                      (profile.source.startsWith('sub')
                          ? '  ·  ${context.tr('from_subscription')}'
                          : ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            delay == null ? '—' : FormatUtils.delayMs(delay),
            style: TextStyle(
              fontFamily: 'Sahand',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: delayColor,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded,
                color: palette.danger, size: 20),
            tooltip: context.tr('delete'),
          ),
        ],
      ),
    );
  }
}
