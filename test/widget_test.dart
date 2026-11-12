import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:pzt_app/main.dart';
import 'package:pzt_app/features/tool_screen.dart';
import 'package:pzt_app/core/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('Home fits mobile and desktop and search filters tools', (
    tester,
  ) async {
    for (final width in [360.0, 1100.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(const PztApp());
      await tester.pumpAndSettle();
      expect(find.text('PztApp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(find.byType(TextField), 'pt100');
    await tester.pumpAndSettle();
    expect(find.text('Pt100 / Pt1000'), findsOneWidget);
    expect(find.text('Prozentrechner'), findsNothing);
    await tester.tap(find.text('Pt100 / Pt1000'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.pump();
    expect(find.text('100 Ω'), findsOneWidget);
    expect(find.text('@by LostCacher'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'Recent tool shortcut updates, reopens and survives home recreation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const PztApp());
      await tester.pumpAndSettle();
      expect(find.text('BETA'), findsNothing);
      expect(find.text('Noch kein Werkzeug geöffnet'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'prozent');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Prozentrechner'));
      await tester.tap(find.text('Prozentrechner'));
      await tester.pumpAndSettle();
      expect(
        await SharedPreferencesAsync().getString('last_used_tool'),
        'percent',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      final recent = find.byKey(const ValueKey('recent-tool'));
      expect(
        find.descendant(of: recent, matching: find.text('Prozentrechner')),
        findsOneWidget,
      );
      await tester.ensureVisible(recent);
      await tester.tap(recent);
      await tester.pumpAndSettle();
      expect(find.byType(ToolScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const PztApp());
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: recent, matching: find.text('Prozentrechner')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Pt100');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pt100 / Pt1000'));
      await tester.tap(find.text('Pt100 / Pt1000'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: recent, matching: find.text('Pt100 / Pt1000')),
        findsOneWidget,
      );
      expect(
        await SharedPreferencesAsync().getString('last_used_tool'),
        'temperature',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Signal converts live and handles invalid input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const ToolScreen(
          kind: ToolKind.signal,
          title: 'Signal-Converter',
        ),
      ),
    );
    expect(find.text('50 bar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '20');
    await tester.pump();
    expect(find.text('100 bar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    expect(find.text('Bitte gültige Zahlen eingeben.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Signal slider follows input and reverse/inverted ranges', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const ToolScreen(
          kind: ToolKind.signal,
          title: 'Signal-Converter',
        ),
      ),
    );
    expect(find.text('50 bar'), findsOneWidget);
    expect(find.textContaining('Signal: 12 mA'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('input-max')), '10');
    await tester.pump();
    expect(find.text('5 bar'), findsOneWidget);
    final sliderFinder = find.byKey(const ValueKey('signal-slider'));
    await tester.ensureVisible(sliderFinder);
    await tester.drag(sliderFinder, const Offset(80, 0));
    await tester.pump();
    expect(tester.widget<Slider>(sliderFinder).value, greaterThan(.5));
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('input-value')),
    );
    expect(
      double.parse(input.controller!.text.replaceAll(',', '.')),
      greaterThan(12),
    );
    await choose(tester, 'Richtung', 'Prozesswert → Signal');
    await tester.enterText(find.byKey(const ValueKey('input-min')), '10');
    await tester.enterText(find.byKey(const ValueKey('input-max')), '0');
    await tester.enterText(find.byKey(const ValueKey('input-value')), '2,5');
    await tester.pump();
    expect(find.text('16 mA'), findsOneWidget);
    expect(
      find.textContaining('Prozesswert (absolut): 2,5 bar'),
      findsOneWidget,
    );
    expect(tester.widget<Slider>(sliderFinder).value, .75);
    await tester.enterText(find.byKey(const ValueKey('input-max')), '10');
    await tester.pump();
    expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
    expect(
      find.textContaining(
        'Prozessminimum und -maximum müssen verschieden sein.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Percentage input converts all signal ranges and synchronizes slider',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const ToolScreen(
            kind: ToolKind.signal,
            title: 'Signal-Converter',
          ),
        ),
      );
      await choose(tester, 'Richtung', 'Prozent → Signal & Prozesswert');
      await tester.enterText(find.byKey(const ValueKey('input-max')), '10');
      await tester.pump();
      expect(find.text('12 mA'), findsOneWidget);
      expect(
        find.textContaining('Prozesswert (absolut): 5 bar'),
        findsOneWidget,
      );
      final slider = find.byKey(const ValueKey('signal-slider'));
      for (final range in ['4–20 mA', '0–20 mA', '0–10 V']) {
        await choose(tester, 'Signalbereich', range);
        for (final percent in ['0', '50', '100']) {
          await tester.enterText(
            find.byKey(const ValueKey('input-value')),
            percent,
          );
          await tester.pump();
          final expected = switch ((range, percent)) {
            ('4–20 mA', '0') => '4 mA',
            ('4–20 mA', '50') => '12 mA',
            ('4–20 mA', '100') => '20 mA',
            ('0–20 mA', '0') => '0 mA',
            ('0–20 mA', '50') => '10 mA',
            ('0–20 mA', '100') => '20 mA',
            ('0–10 V', '0') => '0 V',
            ('0–10 V', '50') => '5 V',
            _ => '10 V',
          };
          expect(find.text(expected), findsOneWidget);
          expect(
            tester.widget<Slider>(slider).value,
            double.parse(percent) / 100,
          );
        }
      }
      await tester.enterText(find.byKey(const ValueKey('input-min')), '10');
      await tester.enterText(find.byKey(const ValueKey('input-max')), '0');
      await tester.enterText(find.byKey(const ValueKey('input-value')), '12,5');
      await tester.pump();
      expect(find.text('1,25 V'), findsOneWidget);
      expect(
        find.textContaining('Prozesswert (absolut): 8,75 bar'),
        findsOneWidget,
      );
      await tester.ensureVisible(slider);
      await tester.drag(slider, const Offset(80, 0));
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, greaterThan(.125));
      await tester.enterText(find.byKey(const ValueKey('input-value')), '125');
      await tester.pump();
      expect(find.text('12,5 V'), findsOneWidget);
      expect(find.textContaining('linear extrapoliert'), findsOneWidget);
      expect(tester.widget<Slider>(slider).value, 1);
      await tester.enterText(find.byKey(const ValueKey('input-value')), 'abc');
      await tester.pump();
      expect(find.text('Bitte gültige Zahlen eingeben.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Slip is optional, validated and works in reverse', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const ToolScreen(
          kind: ToolKind.motor,
          title: 'Drehzahl & Frequenz',
        ),
      ),
    );
    expect(find.text('1500 U/min'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('1455 U/min'), findsOneWidget);
    await choose(tester, 'Richtung', 'U/min → Hz');
    await tester.enterText(find.byKey(const ValueKey('input-value')), '1455');
    await tester.pump();
    expect(find.text('50 Hz'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('input-slip')), '100');
    await tester.pump();
    expect(find.textContaining('Schlupf muss zwischen'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('48,5 Hz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Torque supports shaft power and electrical supply modes on mobile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const ToolScreen(
            kind: ToolKind.torque,
            title: 'Drehmoment & Leistung',
          ),
        ),
      );
      expect(find.text('49,393 Nm'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('input-rpm')), '0');
      await tester.pump();
      expect(
        find.textContaining('Die Drehzahl muss größer als 0'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('input-rpm')), '1450');
      await choose(tester, 'Berechnungsgrundlage', 'Elektrische Motordaten');
      expect(
        find.textContaining('Aufnahmeleistung P₁: 8,833 kW'),
        findsOneWidget,
      );
      expect(find.textContaining('Wellenleistung P₂: 7,95 kW'), findsOneWidget);
      await choose(tester, 'Motorart', 'Wechselstrom (1~)');
      await tester.enterText(
        find.byKey(const ValueKey('input-voltage')),
        '230',
      );
      await tester.enterText(find.byKey(const ValueKey('input-current')), '10');
      await tester.enterText(
        find.byKey(const ValueKey('input-powerFactor')),
        '0,8',
      );
      await tester.pump();
      expect(
        find.textContaining('Aufnahmeleistung P₁: 1,84 kW'),
        findsOneWidget,
      );
      await choose(tester, 'Motorart', 'Gleichstrom (DC)');
      expect(find.byKey(const ValueKey('input-powerFactor')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('input-voltage')), '24');
      await tester.pump();
      expect(
        find.textContaining('Aufnahmeleistung P₁: 0,24 kW'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('input-efficiency')),
        '101',
      );
      await tester.pump();
      expect(
        find.textContaining('Wirkungsgrad muss größer als 0'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> choose(WidgetTester tester, String label, String option) async {
  final field = find.byKey(ValueKey('select-$label'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
