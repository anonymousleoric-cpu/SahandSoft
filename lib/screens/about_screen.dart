import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config_repository.dart';
import '../core/v2ray_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// AboutScreen — SahandSoft identity + builder credit + legal attribution.
/// ---------------------------------------------------------------------------
class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    required this.service,
    required this.repository,
  });

  final V2RayService service;
  final ConfigRepository repository;

  static const String kTelegramDevUrl = 'https://t.me/SahandSoft';
  static const String kUpstreamRepoUrl =
      'https://github.com/Begzar/BegzarApp';

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;
  String? _coreVersion;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String? core = await widget.service.coreVersion();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _coreVersion = core;
    });
  }

  Future<void> _launch(String url) async {
    final Uri uri = Uri.parse(url);
    // externalApplication: opens Telegram (if installed) or a browser.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('link_open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('about'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // ---- Brand ---------------------------------------------------
            Center(
              child: TweenAnimationBuilder<double>(
                duration: AppDurations.slow,
                tween: Tween<double>(begin: 0.9, end: 1),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: const SahandLogo(size: 108),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                context.tr('app_title'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                context.tr('about_tagline'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.muted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: StatusPill(
                label: context.tr(
                  'version_with_value',
                  args: <String>[_version ?? '—'],
                ),
                color: palette.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ---- Developer credit (exact required text) -------------------
            SahandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: Iconsax.profile_tick,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.tr('developer_section'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.9),
                      children: <InlineSpan>[
                        TextSpan(text: '${context.tr('developer_line')} '),
                        TextSpan(
                          text: context.tr('developer_telegram_name'),
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: palette.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _launch(AboutScreen.kTelegramDevUrl),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _launch(AboutScreen.kTelegramDevUrl),
                    icon: const Icon(Iconsax.send_1, size: 18),
                    label: Text(context.tr('developer_telegram_name')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---- Technical info ------------------------------------------
            SahandCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Iconsax.setting_2,
                    label: context.tr('engine_label'),
                    value: 'flutter_v2ray',
                  ),
                  if (_coreVersion != null)
                    _InfoRow(
                      icon: Iconsax.cpu,
                      label: context.tr('core_label'),
                      value: _coreVersion!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---- Open source attribution (legal requirement) --------------
            SahandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: Iconsax.code,
                        color: palette.muted,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          context.tr('open_source_section'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.tr('attribution_body'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.8),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launch(
                              AboutScreen.kUpstreamRepoUrl),
                          icon: const Icon(Iconsax.code_1, size: 18),
                          label: Text(context.tr('upstream_repo')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showLicensePage(
                            context: context,
                            applicationName: context.tr('app_title'),
                            applicationVersion: _version,
                          ),
                          icon: const Icon(Iconsax.document, size: 18),
                          label: Text(context.tr('licenses_link')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                context.tr('copyright_sahandsoft'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.muted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.muted),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
