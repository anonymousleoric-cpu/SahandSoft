import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahandsoft/theme/app_theme.dart';
import 'package:sahandsoft/theme/app_tokens.dart';
import 'package:sahandsoft/widgets/common/sahand_components.dart';

void main() {
  group('SahandTheme', () {
    test('light and dark themes build from brand tokens', () {
      final ThemeData light = SahandTheme.light();
      final ThemeData dark = SahandTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.scaffoldBackgroundColor, AppColors.lightBg);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBg);
      expect(light.colorScheme.primary, AppColors.brandDeep);
      expect(dark.colorScheme.primary, AppColors.brandBright);
      expect(SahandTheme.fontFamily, AppFont.family);
    });
  });

  group('FormatUtils', () {
    test('formats bytes and speeds consistently', () {
      expect(FormatUtils.bytes(0), '0 B');
      expect(FormatUtils.bytes(1023), '1023 B');
      expect(FormatUtils.bytes(1024), '1.00 KB');
      expect(FormatUtils.bytes(1536 * 1024), '1.50 MB');
      expect(FormatUtils.speed(2048), '2.00 KB/s');
      expect(FormatUtils.delayMs(null), '—');
      expect(FormatUtils.delayMs(120), '120 ms');
    });
  });

  testWidgets('SahandCard and StatusPill render inside themed MaterialApp',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SahandTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              SahandCard(child: Text('sahand-card-body')),
              StatusPill(label: 'Connected', color: AppColors.successLight),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('sahand-card-body'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('EmptyState renders title, body and action',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: SahandTheme.dark(),
        home: Scaffold(
          body: EmptyState(
            icon: Icons.link,
            title: 'empty-title',
            body: 'empty-body',
            actionLabel: 'empty-action',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('empty-title'), findsOneWidget);
    expect(find.text('empty-body'), findsOneWidget);

    await tester.tap(find.text('empty-action'));
    expect(tapped, isTrue);
  });
}
