import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/app_theme.dart';
import 'package:pzt_app/features/temperature/thermocouple_screen.dart';
import 'package:pzt_app/widgets/calculator_page.dart';

void main() {
  testWidgets(
    'Comparison-junction presets update input and calculated voltage',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildTheme(), home: const ThermocoupleScreen()),
      );
      for (final sample in [(20, 3.298110), (25, 3.095988), (0, 4.096230)]) {
        final chip = find.widgetWithText(ChoiceChip, '${sample.$1} °C');
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        final input = tester.widget<TextField>(
          find.byKey(const ValueKey('input-reference')),
        );
        expect(input.controller!.text, '${sample.$1}');
        final result = tester.widget<ResultCard>(find.byType(ResultCard));
        expect(
          double.parse(result.value.replaceAll(',', '.')),
          closeTo(sample.$2, .000002),
        );
        expect(result.unit, 'mV');
        expect(
          result.lines.any(
            (line) => line.startsWith('Vergleichsstelle: ${sample.$1} °C ·'),
          ),
          isTrue,
        );
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      }
    },
  );
  testWidgets(
    'Zero measured voltage returns the selected comparison-junction temperature',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildTheme(), home: const ThermocoupleScreen()),
      );
      final direction = find.byKey(const ValueKey('select-Richtung'));
      await tester.tap(direction);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spannung → Temperatur').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('input-value')), '0');
      await tester.pump();
      for (final reference in [20, 25, 0]) {
        final chip = find.widgetWithText(ChoiceChip, '$reference °C');
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        final result = tester.widget<ResultCard>(find.byType(ResultCard));
        expect(result.value, '$reference');
        expect(result.unit, '°C');
        expect(
          result.lines.any(
            (line) => line.startsWith('Vergleichsstelle: $reference °C ·'),
          ),
          isTrue,
        );
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      }
    },
  );
}
