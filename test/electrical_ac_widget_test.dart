import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/app_theme.dart';
import 'package:pzt_app/features/electrical/electrical_screen.dart';

Future<void> choose(WidgetTester tester, String label, String option) async {
  final field = find.byKey(ValueKey('select-$label'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(theme: buildTheme(), home: const ElectricalScreen()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'DC, single-phase AC and capacitive load calculate live on mobile',
    (tester) async {
      await open(tester);
      expect(find.text('24 V'), findsOneWidget);
      expect(find.byKey(const ValueKey('input-powerFactor')), findsNothing);
      await choose(tester, 'Stromart', 'Wechselstrom (1~)');
      expect(find.text('230 V'), findsOneWidget);
      expect(find.text('368 W'), findsOneWidget);
      expect(find.text('Blindleistung Q: 276 var'), findsOneWidget);
      await choose(tester, 'Lastcharakter', 'Kapazitiv');
      expect(find.text('Blindleistung Q: -276 var'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('input-powerFactor')),
        '1,1',
      );
      await tester.pump();
      expect(find.text('EINGABE PRÜFEN'), findsOneWidget);
      await choose(tester, 'Stromart', 'Gleichstrom (DC)');
      expect(find.text('24 V'), findsOneWidget);
      expect(find.byKey(const ValueKey('input-powerFactor')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Three-phase star/delta show line and branch values with total powers',
    (tester) async {
      await open(tester);
      await choose(tester, 'Stromart', 'Drehstrom (3~)');
      expect(find.text('400 V'), findsOneWidget);
      expect(find.text('5542,563 W'), findsOneWidget);
      expect(find.text('Strangspannung: 230,94 V'), findsOneWidget);
      expect(find.text('Strangstrom: 10 A'), findsOneWidget);
      expect(find.text('23,094 Ω'), findsOneWidget);
      await choose(tester, 'Schaltung', 'Dreieck (Δ)');
      expect(find.text('5542,563 W'), findsOneWidget);
      expect(find.text('Strangspannung: 400 V'), findsOneWidget);
      expect(find.text('Strangstrom: 5,774 A'), findsOneWidget);
      expect(find.text('69,282 Ω'), findsOneWidget);
      await choose(tester, 'Bekannte Größen', 'P + U');
      await tester.enterText(
        find.byKey(const ValueKey('input-P')),
        '5542,562584',
      );
      await tester.pump();
      expect(find.text('Außenleiterstrom Iₗ: 10 A'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('input-powerFactor')),
        '0',
      );
      await tester.pump();
      expect(
        find.textContaining('Bei Wirkleistung als Eingabe'),
        findsOneWidget,
      );
      await choose(tester, 'Bekannte Größen', 'S + U');
      expect(find.text('0 W'), findsOneWidget);
      expect(find.text('EINGABE PRÜFEN'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'All AC pairs and switching from DC resistance to AC are supported',
    (tester) async {
      await open(tester);
      await choose(tester, 'Bekannte Größen', 'U + R');
      await choose(tester, 'Stromart', 'Drehstrom (3~)');
      expect(find.byKey(const ValueKey('input-R')), findsNothing);
      expect(find.byKey(const ValueKey('input-I')), findsOneWidget);
      for (final pair in [
        'U + Z',
        'I + Z',
        'P + U',
        'P + I',
        'P + Z',
        'S + U',
        'S + I',
        'U + I',
      ]) {
        await choose(tester, 'Bekannte Größen', pair);
        expect(find.text('EINGABE PRÜFEN'), findsNothing);
        expect(find.text('GESAMTWIRKLEISTUNG P'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
