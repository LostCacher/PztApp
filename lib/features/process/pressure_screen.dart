import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class PressureScreen extends StatefulWidget {
  const PressureScreen({super.key});
  @override
  State<PressureScreen> createState() => _PressureScreenState();
}

class _PressureScreenState extends CalculatorState<PressureScreen> {
  String from = 'bar', to = 'mbar';
  @override
  void initState() {
    super.initState();
    setup({'value': '1'});
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'Druckeinheiten',
    children: [
      input('value', 'Druck', from),
      menu('Von', from, pressureFactors.keys.toList(), (v) => from = v),
      menu('Nach', to, pressureFactors.keys.toList(), (v) => to = v),
      result(
        () => ResultCard(
          value: formatNumber(
            ProcessCalculations.pressure(number('value'), from, to),
          ),
          unit: to,
          lines: pressureFactors.keys
              .where((u) => u != to)
              .map(
                (u) =>
                    '${formatNumber(ProcessCalculations.pressure(number('value'), from, u))} $u',
              )
              .toList(),
        ),
      ),
      const ToolNote(
        'Reine Einheitenumrechnung. Absolutdruck und Relativdruck behalten ihren jeweiligen Bezug. mWS: konventionelle Wassersäule mit ρ = 1000 kg/m³ und g = 9,80665 m/s².',
      ),
    ],
  );
}
