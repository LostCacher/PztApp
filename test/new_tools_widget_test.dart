import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:pzt_app/core/app_theme.dart';
import 'package:pzt_app/core/thermocouples.dart';
import 'package:pzt_app/features/tool_catalog.dart';
import 'package:pzt_app/features/tool_screen.dart';
import 'package:pzt_app/main.dart';

Future<void> choose(WidgetTester tester, String label, String value) async {
  final field = find.byKey(ValueKey('select-$label'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  final item = find.text(value).last;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, ToolKind kind) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: ToolScreen(kind: kind, title: kind.name),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  final defaults = <ToolKind, String>{
    ToolKind.pressure: '1000 mbar',
    ToolKind.plc: '50 °C',
    ToolKind.electrical: '24 V',
    ToolKind.level: '1 m',
    ToolKind.tank: '1,178 m³',
    ToolKind.flow: '50 m³/h',
    ToolKind.thermocouple: '4,09623 mV',
    ToolKind.calibration: 'PRÜFPUNKTE',
  };
  for (final entry in defaults.entries) {
    testWidgets(
      '${entry.key.name} fits narrow screens and calculates immediately',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await open(tester, entry.key);
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('@by LostCacher'), findsOneWidget);
        // Scroll through the whole form and result, including offscreen content.
        final vertical = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first;
        await tester.fling(vertical, const Offset(0, -2000), 1200);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('All catalog entries are searchable and reachable from home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PztApp());
    await tester.pumpAndSettle();
    expect(find.text('13 TOOLS'), findsOneWidget);
    for (final tool in tools.where((t) => defaults.containsKey(t.kind))) {
      final search = find.byType(TextField);
      await tester.ensureVisible(search);
      await tester.enterText(search, tool.title);
      await tester.pumpAndSettle();
      final title = find.text(tool.title).last;
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(ToolScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Calibration evaluates measured values against the configured tolerance',
    (tester) async {
      await open(tester, ToolKind.calibration);
      await tester.enterText(
        find.byKey(const ValueKey('input-actual50')),
        '50,4',
      );
      await tester.pump();
      expect(find.text('i. O.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('input-actual50')),
        '51',
      );
      await tester.pump();
      expect(find.text('Außerhalb'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('input-max')), '0');
      await tester.pump();
      expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
    },
  );
  testWidgets('Flow and level reverse conversion and invalid limits', (
    tester,
  ) async {
    await open(tester, ToolKind.flow);
    await choose(tester, 'Richtung', 'Durchfluss → Differenzdruck');
    expect(find.text('25 mbar'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('input-value')), '-1');
    await tester.pump();
    expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
    await open(tester, ToolKind.level);
    await choose(tester, 'Richtung', 'Füllhöhe → Druck');
    expect(find.text('98,067 mbar'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('input-density')), '0');
    await tester.pump();
    expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
  });
  testWidgets('Tank shapes, slider synchronization and overfill', (
    tester,
  ) async {
    await open(tester, ToolKind.tank);
    for (final shape in [
      'Quader',
      'Zylinder stehend',
      'Kugel',
      'Zylinder liegend',
    ]) {
      await choose(tester, 'Tankform', shape);
      expect(find.text('FÜLLVOLUMEN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    final slider = find.byKey(const ValueKey('tank-slider'));
    await tester.ensureVisible(slider);
    await tester.drag(slider, const Offset(80, 0));
    await tester.pump();
    expect(tester.widget<Slider>(slider).value, greaterThan(.5));
    await tester.enterText(find.byKey(const ValueKey('input-fill')), '2');
    await tester.pump();
    expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
  });
  testWidgets(
    'Thermocouples select all ten types and compensate the comparison junction',
    (tester) async {
      await open(tester, ToolKind.thermocouple);
      for (final type in Thermocouples.types) {
        await choose(tester, 'Typ', type);
        expect(find.text('THERMOSPANNUNG · TYP $type'), findsOneWidget);
        expect(find.text('EINGABE PRÜFEN'), findsNothing);
      }
      await choose(tester, 'Typ', 'K');
      await tester.enterText(
        find.byKey(const ValueKey('input-reference')),
        '100',
      );
      await tester.pump();
      expect(find.text('0 mV'), findsOneWidget);
      await choose(tester, 'Richtung', 'Spannung → Temperatur');
      await tester.enterText(find.byKey(const ValueKey('input-value')), '0');
      await tester.pump();
      expect(find.text('100 °C'), findsOneWidget);
      await choose(tester, 'Typ', 'B');
      await tester.enterText(
        find.byKey(const ValueKey('input-reference')),
        '0',
      );
      await tester.enterText(find.byKey(const ValueKey('input-value')), '0');
      await tester.pump();
      expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
      expect(find.textContaining('250 … 1820'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
