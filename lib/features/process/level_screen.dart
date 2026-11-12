import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});
  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends CalculatorState<LevelScreen> {
  String direction = 'Druck → Füllhöhe', unit = 'mbar';
  @override
  void initState() {
    super.initState();
    setup({'value': '98,0665', 'density': '1000'});
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'Hydrostatischer Füllstand',
    children: [
      menu('Richtung', direction, ['Druck → Füllhöhe', 'Füllhöhe → Druck'], (
        v,
      ) {
        direction = v;
        fields['value']!.text = v.startsWith('Druck')
            ? formatNumber(ProcessCalculations.pressure(9806.65, 'Pa', unit))
            : '1';
      }),
      menu(
        'Druckeinheit',
        unit,
        pressureFactors.keys.toList(),
        (v) => unit = v,
      ),
      input(
        'value',
        direction.startsWith('Druck')
            ? 'Hydrostatischer Differenzdruck'
            : 'Füllhöhe über dem Messpunkt',
        direction.startsWith('Druck') ? unit : 'm',
      ),
      input('density', 'Dichte des Mediums', 'kg/m³'),
      result(() {
        final forward = direction.startsWith('Druck');
        final value = forward
            ? ProcessCalculations.level(
                ProcessCalculations.pressure(number('value'), unit, 'Pa'),
                number('density'),
              )
            : ProcessCalculations.pressure(
                ProcessCalculations.hydrostaticPressure(
                  number('value'),
                  number('density'),
                ),
                'Pa',
                unit,
              );
        return ResultCard(
          value: formatNumber(value),
          unit: forward ? 'm' : unit,
          lines: [
            'p = ρ × g × h',
            'g = 9,80665 m/s²',
            if (forward) '${formatNumber(value * 1000)} mm',
          ],
        );
      }),
      const ToolNote(
        'Der Druck muss der Flüssigkeitssäule entsprechen: Bodendruck minus Druck über der Flüssigkeit. Bei offenen Tanks relativ zur Atmosphäre, bei geschlossenen Tanks Gasraumdruck abziehen. Konstante Dichte; keine Korrektur für Messleitungsfüllungen oder Sensorhöhenversatz.',
      ),
    ],
  );
}
