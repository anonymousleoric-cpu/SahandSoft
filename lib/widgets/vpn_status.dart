import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// VpnCard — live session statistics.
/// ---------------------------------------------------------------------------
/// Every value shown here comes from the real V2RayStatus stream or a real
/// IP lookup; nothing is fabricated.
class VpnCard extends StatelessWidget {
  const VpnCard({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.download,
    required this.upload,
    required this.selectedServer,
    required this.duration,
    this.delayMs,
  });

  final int downloadSpeed;
  final int uploadSpeed;
  final int download;
  final int upload;
  final String selectedServer;
  final String duration;
  final int? delayMs;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Column(
      children: [
        // --- session banner -------------------------------------------------
        SahandCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              IconBadge(
                icon: Icons.schedule_rounded,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('session_duration'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr('connected_server'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: 2),
                  _DelayChip(delayMs: delayMs),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // --- throughput grid ------------------------------------------------
        SahandCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _StatRow(
                icon: Icons.south_rounded,
                iconColor: palette.success,
                title: context.tr('download_speed'),
                value: FormatUtils.speed(downloadSpeed),
              ),
              Divider(
                height: AppSpacing.xl,
                color: palette.outline,
              ),
              _StatRow(
                icon: Icons.north_rounded,
                iconColor: palette.primary,
                title: context.tr('upload_speed'),
                value: FormatUtils.speed(uploadSpeed),
              ),
              Divider(
                height: AppSpacing.xl,
                color: palette.outline,
              ),
              _StatRow(
                icon: Icons.data_usage_rounded,
                iconColor: palette.warning,
                title: context.tr('total_usage'),
                value:
                    '${FormatUtils.bytes(download)}  ▾   ${FormatUtils.bytes(upload)}  ▴',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _IpCheckTile(serverLabel: selectedServer),
      ],
    );
  }
}

class _DelayChip extends StatelessWidget {
  const _DelayChip({required this.delayMs});

  final int? delayMs;

  Color _color(SahandPalette palette) {
    final int? ms = delayMs;
    if (ms == null) return palette.muted;
    if (ms < 0) return palette.danger;
    if (ms < 300) return palette.success;
    if (ms < 800) return palette.warning;
    return palette.danger;
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: _color(palette).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 14, color: _color(palette)),
          const SizedBox(width: 4),
          Text(
            FormatUtils.delayMs(delayMs),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _color(palette),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.muted),
          ),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _IpCheckTile extends StatefulWidget {
  const _IpCheckTile({required this.serverLabel});

  final String serverLabel;

  @override
  State<_IpCheckTile> createState() => _IpCheckTileState();
}

class _IpCheckTileState extends State<_IpCheckTile> {
  String? _ip;
  String? _flag;
  bool _loading = false;

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      final Response<Map<String, dynamic>> response = await Dio()
          .get<Map<String, dynamic>>(
        'https://freeipapi.com/api/json',
        options: Options(
          headers: <String, String>{'X-Content-Type-Options': 'nosniff'},
        ),
      );
      final Map<String, dynamic> data =
          response.data ?? <String, dynamic>{};
      String ip = (data['ipAddress'] ?? 'Unknown IP') as String;
      // privacy: mask most of the address, same policy as upstream
      if (ip.contains('.')) {
        final List<String> parts = ip.split('.');
        if (parts.length == 4) ip = '${parts[0]}.*.*.${parts[3]}';
      } else if (ip.contains(':')) {
        final List<String> parts = ip.split(':');
        if (parts.length > 4) {
          ip = '${parts[0]}:${parts[1]}:****:${parts.last}';
        }
      }
      if (!mounted) return;
      setState(() {
        _ip = ip;
        _flag = _flagEmoji((data['countryCode'] ?? '') as String);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ip = context.tr('ip_unknown');
        _flag = null;
        _loading = false;
      });
    }
  }

  String _flagEmoji(String countryCode) {
    final String code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    return code.codeUnits
        .map((int unit) => String.fromCharCode(0x1F1E6 + unit - 0x41))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return SahandCard(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: _loading ? null : _check,
        leading: IconBadge(
          icon: Icons.public_rounded,
          color: palette.primary,
        ),
        title: Text(
          _ip ?? context.tr('show_ip'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: _flag == null
            ? Text(
                context.tr('ip_check_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              )
            : Text('$_flag  ${widget.serverLabel}',
                style: Theme.of(context).textTheme.bodySmall),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.refresh_rounded, color: palette.muted),
      ),
    );
  }
}
