import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/common/sahand_components.dart';

/// ---------------------------------------------------------------------------
/// LanguageScreen — Persian (default) / English / 中文 / Русский.
/// Selection is persisted with the same 'selectedLanguage' preference key
/// used by upstream so upgrades keep the user's choice.
/// ---------------------------------------------------------------------------
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.selectedLanguage});

  final String selectedLanguage;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLanguage = widget.selectedLanguage;

  Future<void> _save(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  void _changeLocale(BuildContext context, String language) {
    switch (language) {
      case 'English':
        context.setLocale(const Locale('en', 'US'));
      case 'فارسی':
        context.setLocale(const Locale('fa', 'IR'));
      case '中文':
        context.setLocale(const Locale('zh', 'CN'));
      case 'Русский':
        context.setLocale(const Locale('ru', 'RU'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('select_language'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            _buildLanguageTile(context, 'فارسی', 'ایران', 'fa'),
            _buildLanguageTile(context, 'English', 'United States', 'en'),
            _buildLanguageTile(context, '中文', '中国', 'zh'),
            _buildLanguageTile(context, 'Русский', 'Россия', 'ru'),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                context.tr('language_footer'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String language,
    String subtitle,
    String flagEmoji,
  ) {
    final SahandPalette palette = SahandPalette.of(context);
    final bool selected = _selectedLanguage == language;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? palette.primary.withValues(alpha: 0.10)
            : palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () {
            setState(() => _selectedLanguage = language);
            _save(language);
            _changeLocale(context, language);
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? palette.primary.withValues(alpha: 0.5)
                    : palette.outline,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(flagEmoji,
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: palette.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
