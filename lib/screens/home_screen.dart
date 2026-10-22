import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/model/v2ray_status.dart';

import '../core/config_repository.dart';
import '../core/models.dart';
import '../core/v2ray_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';
import '../widgets/connection_widget.dart';
import '../widgets/server_selection_modal_widget.dart';
import '../widgets/vpn_status.dart';
import 'servers_screen.dart';

/// ---------------------------------------------------------------------------
/// HomePage — the main connection screen.
/// ---------------------------------------------------------------------------
/// Connect flow (real functionality, no mock data):
///  1. Profiles are loaded from ConfigRepository (user managed configs).
///  2. On connect, every profile URI is parsed by the flutter_v2ray plugin,
///     real delays are measured with getAllServerDelay and the fastest
///     config is used (or the explicitly selected profile).
///  3. The Android VPN permission dialog is requested, then startV2Ray
///     starts the actual VPN service; UI state follows status callbacks.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.service,
    required this.repository,
  });

  final V2RayService service;
  final ConfigRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VpnProfile> _profiles = <VpnProfile>[];
  String? _selectedProfileId; // null = Automatic (best latency)
  bool _busy = false; // fetching configs / measuring delays
  int? _connectedDelay;
  String? _activeLabel;
  List<String> _blockedApps = <String>[];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final List<VpnProfile> profiles =
        await widget.repository.loadProfiles();
    final String? selectedId =
        await widget.repository.getSelectedProfileId();
    final List<String> blockedApps =
        await widget.repository.loadBlockedApps();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _selectedProfileId = selectedId;
      _blockedApps = blockedApps;
      _activeLabel = _labelFor(selectedId);
    });
  }

  String _labelFor(String? id) {
    if (id == null) return context.tr('auto_select');
    for (final VpnProfile p in _profiles) {
      if (p.id == id) return p.label;
    }
    return context.tr('auto_select');
  }

  // ---- connect / disconnect ------------------------------------------------

  Future<void> _handleConnectionTap(V2RayStatus status) async {
    if (status.state == 'CONNECTED' || status.state == 'DISCONNECTING') {
      await _disconnect();
    } else if (status.state == 'DISCONNECTED') {
      await _connect();
    }
  }

  Future<void> _disconnect() async {
    try {
      await widget.service.stop();
    } catch (e) {
      debugPrint('disconnect failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _connectedDelay = null;
    });
  }

  Future<void> _connect() async {
    if (_busy) return;

    final List<VpnProfile> profiles =
        await widget.repository.loadProfiles();
    if (!mounted) return;
    if (profiles.isEmpty) {
      _promptNoProfiles();
      return;
    }

    setState(() => _busy = true);

    try {
      // 1) Parse URIs into full Xray configs via the plugin (real parser).
      final Map<String, VpnProfile> configToProfile =
          <String, VpnProfile>{};
      for (final VpnProfile p in profiles) {
        try {
          final String full = widget.service.fullConfigFromUri(p.uri);
          configToProfile[full] = p;
        } catch (e) {
          debugPrint('skip unparsable profile ${p.id}: $e');
        }
      }
      if (configToProfile.isEmpty) {
        _showError(context.tr('error_invalid_profiles'));
        return;
      }

      // 2) Choose config: selected profile or best measured delay.
      String bestConfig = '';
      VpnProfile? chosen;
      final VpnProfile? explicit = _selectedProfileId == null
          ? null
          : configToProfile.values
              .where((VpnProfile p) => p.id == _selectedProfileId)
              .firstOrNull;
      if (explicit != null) {
        bestConfig = configToProfile.keys
            .firstWhere((String k) => configToProfile[k] == explicit);
        chosen = explicit;
      } else {
        final Map<String, int> delays =
            await widget.service.allDelays(configToProfile.keys.toList());
        int minDelay = 1 << 30;
        delays.forEach((String config, int delay) {
          if (delay >= 0 && delay < minDelay) {
            minDelay = delay;
            bestConfig = config;
          }
        });
        chosen = configToProfile[bestConfig];
        // persist real measured delays for the picker UI
        for (final MapEntry<String, int> entry in delays.entries) {
          final VpnProfile? profile = configToProfile[entry.key];
          if (profile != null) {
            await widget.repository
                .updateDelay(profile.id, entry.value);
          }
        }
        if (chosen != null) {
          await widget.repository.updateDelay(chosen.id, minDelay);
        }
      }

      if (bestConfig.isEmpty || chosen == null) {
        _showError(context.tr('error_no_server_connected'));
        return;
      }

      // 3) Ask for the Android VPN permission, then start the service.
      final bool granted = await widget.service.requestPermission();
      if (!granted) {
        _showError(context.tr('error_permission'));
        return;
      }
      widget.service.notificationDisconnectLabel =
          context.tr('disconnect_btn');
      await widget.service.start(
        remark: context.tr('app_title'),
        config: bestConfig,
        blockedApps: _blockedApps,
      );
      if (!mounted) return;
      setState(() => _activeLabel = chosen.label);

      // 4) Read the real connected-server delay shortly after connecting.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () async {
          if (widget.service.state != 'CONNECTED') return;
          final int? delay =
              await widget.service.connectedDelay();
          if (delay != null && mounted) {
            setState(() => _connectedDelay = delay);
          }
        }),
      );
    } on TimeoutException {
      _showError(context.tr('error_timeout'));
    } catch (e) {
      debugPrint('connect failed: $e');
      _showError(context.tr('error_connect'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _promptNoProfiles() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(
                icon: Icons.add_link_rounded,
                color: AppColors.brandBright,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('empty_profiles_title'),
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('empty_profiles_body'),
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _goToServers();
                },
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: Text(context.tr('add_first_config')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToServers() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ServersScreen(
          service: widget.service,
          repository: widget.repository,
          onProfilesChanged: _loadState,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- server picker ---------------------------------------------------------

  Future<void> _showServerSelectionModal() async {
    if (widget.service.state == 'CONNECTED' ||
        widget.service.state == 'CONNECTING' ||
        widget.service.state == 'DISCONNECTING') {
      _showError(context.tr('error_change_server'));
      return;
    }
    final List<VpnProfile> profiles =
        await widget.repository.loadProfiles();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return ServerSelectionModal(
          profiles: profiles,
          selectedId: _selectedProfileId,
          onProfileSelected: (String? id) {
            Navigator.of(sheetContext).pop();
            setState(() => _selectedProfileId = id);
            widget.repository.setSelectedProfileId(id);
          },
          onManageProfiles: () {
            Navigator.of(sheetContext).pop();
            _goToServers();
          },
        );
      },
    );
  }

  // ---- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadState,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Header(
                activeLabel: _activeLabel ?? context.tr('auto_select'),
                onServerTap: _showServerSelectionModal,
              ),
              const SizedBox(height: AppSpacing.xl),
              ValueListenableBuilder<V2RayStatus>(
                valueListenable: widget.service.status,
                builder: (BuildContext context, V2RayStatus value, _) {
                  final bool connected = value.state == 'CONNECTED';
                  return Column(
                    children: [
                      Center(
                        child: ConnectionWidget(
                          onTap: () => _handleConnectionTap(value),
                          isLoading: _busy,
                          status: value.state,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _StatusLabel(state: value.state, busy: _busy),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedSwitcher(
                        duration: AppDurations.slow,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: connected
                            ? Column(
                                key: const ValueKey<String>('stats'),
                                children: <Widget>[
                                  VpnCard(
                                    downloadSpeed: value.downloadSpeed,
                                    uploadSpeed: value.uploadSpeed,
                                    download: value.download,
                                    upload: value.upload,
                                    selectedServer:
                                        _activeLabel ?? context.tr('auto_select'),
                                    duration: value.duration,
                                    delayMs: _connectedDelay,
                                  ),
                                ],
                              )
                            : _IdleHint(
                                key: const ValueKey<String>('idle'),
                                hasProfiles: _profiles.isNotEmpty,
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.huge),
              Center(
                child: Text(
                  context.tr('core_hint'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top header: brand + active server selector card.
class _Header extends StatelessWidget {
  const _Header({
    required this.activeLabel,
    required this.onServerTap,
  });

  final String activeLabel;
  final VoidCallback onServerTap;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SahandLogo(size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.tr('app_title'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onServerTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: palette.outline),
              ),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.dns_rounded,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('active_server'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: palette.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    color: palette.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Status line under the button — mirrors the real service state.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.state, required this.busy});

  final String state;
  final bool busy;

  (String, Color, bool) _resolve(SahandPalette palette) {
    switch (state) {
      case 'CONNECTED':
        return (context.tr('connected'), palette.success, false);
      case 'CONNECTING':
        return (context.tr('connecting'), palette.warning, true);
      case 'DISCONNECTING':
        return (context.tr('disconnecting'), palette.warning, true);
      default:
        if (busy) {
          return (context.tr('preparing'), palette.warning, true);
        }
        return (context.tr('disconnected'), palette.idle, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    final (String label, Color color, bool pulse) =
        _resolve(palette);
    return StatusPill(label: label, color: color, pulsing: pulse);
  }
}

/// Shown when disconnected: guidance instead of fake stats.
class _IdleHint extends StatelessWidget {
  const _IdleHint({super.key, required this.hasProfiles});

  final bool hasProfiles;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return SahandCard(
      child: Row(
        children: [
          IconBadge(
            icon: hasProfiles
                ? Icons.shield_outlined
                : Icons.info_outline_rounded,
            color: palette.muted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasProfiles
                  ? context.tr('idle_hint_ready')
                  : context.tr('idle_hint_empty'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.7,
                    color: palette.muted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
