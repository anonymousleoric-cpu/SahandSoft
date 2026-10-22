import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/models.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// ServerSelectionModal — profile picker shown as a modal bottom sheet.
/// 'Automatic' = measure every profile with the real V2Ray delay probe and
/// connect to the fastest one. Delays shown are REAL measured values.
/// ---------------------------------------------------------------------------
class ServerSelectionModal extends StatelessWidget {
  const ServerSelectionModal({
    super.key,
    required this.profiles,
    required this.selectedId,
    required this.onProfileSelected,
    required this.onManageProfiles,
  });

  final List<VpnProfile> profiles;
  final String? selectedId; // null == Automatic
  final void Function(String? id) onProfileSelected;
  final VoidCallback onManageProfiles;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.sm,
              ),
              child: Text(
                context.tr('select_server'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AutoTile(
              selected: selectedId == null,
              onTap: () => onProfileSelected(null),
            ),
            if (profiles.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('no_profiles_hint'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.muted),
                textAlign: TextAlign.center,
              ),
            ] else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      for (final VpnProfile p in profiles)
                        _ProfileTile(
                          profile: p,
                          selected: selectedId == p.id,
                          onTap: () => onProfileSelected(p.id),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onManageProfiles,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(context.tr('manage_servers')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoTile extends StatelessWidget {
  const _AutoTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return _TileShell(
      selected: selected,
      onTap: onTap,
      leading: IconBadge(
        icon: Icons.auto_awesome_rounded,
        color: palette.primary,
      ),
      title: context.tr('auto_select'),
      subtitle: context.tr('auto_select_desc'),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: palette.primary, size: 22)
          : null,
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final VpnProfile profile;
  final bool selected;
  final VoidCallback onTap;

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
    return _TileShell(
      selected: selected,
      onTap: onTap,
      leading: IconBadge(
        icon: Icons.dns_rounded,
        color: palette.primary,
      ),
      title: profile.label,
      subtitle: delay == null ? null : FormatUtils.delayMs(delay),
      trailing: delay != null
          ? Text(
              FormatUtils.delayMs(delay),
              style: TextStyle(
                fontFamily: 'Sahand',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: delayColor,
              ),
            )
          : null,
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? palette.primary.withValues(alpha: 0.10)
            : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? palette.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
