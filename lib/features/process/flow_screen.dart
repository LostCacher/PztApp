import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});
  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends CalculatorState<FlowScreen> {
  String direction = 'Differenzdruck → Durchfluss', pressureUnit = 'mbar';
  @override
  void initState() {
    super.initState();
    setup({'value': '25', 'dpMax': '100', 'flowMax': '100', 'unit': 'm³/h'});
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'Differenzdruck & Durchfluss',
    children: [
      menu(
        'Richtung',
        direction,
        ['Differenzdruck → Durchfluss', 'Durchfluss → Differenzdruck'],
        (v) {
          direction = v;
          fields['value']!.text = v.startsWith('Differenzdruck') ? '25' : '50';
        },
      ),
      menu(
        'Druckeinheit',
        pressureUnit,
        pressureFactors.keys.toList(),
        (v) => pressureUnit = v,
      ),
      input(
        'value',
        direction.startsWith('Differenzdruck')
            ? 'Differenzdruck Δp'
            : 'Durchfluss Q',
        direction.startsWith('Differenzdruck')
            ? pressureUnit
            : fields['unit']!.text,
      ),
      input('dpMax', 'Differenzdruck bei maximalem Durchfluss', pressureUnit),
      input('flowMax', 'Maximaler Durchfluss Qmax', fields['unit']!.text),
      input('unit', 'Durchflusseinheit', '', text: true),
      result(() {
        final forward = direction.startsWith('Differenzdruck');
        final value = forward
            ? ProcessCalculations.flow(
                number('value'),
                number('dpMax'),
                number('flowMax'),
              )
            : ProcessCalculations.differentialPressure(
                number('value'),
                number('dpMax'),
                number('flowMax'),
              );
        final fraction = forward
            ? number('value') / number('dpMax')
            : number('value') / number('flowMax');
        return ResultCard(
          value: formatNumber(value),
          unit: forward ? fields['unit']!.text : pressureUnit,
          lines: [
            'Q = Qmax × √(Δp / Δpmax)',
            'Δp = Δpmax × (Q / Qmax)²',
            if (fraction > 1) 'Oberhalb des konfigurierten Messbereichs · Kennlinie extrapoliert',
          ],
        );
      }),
      const ToolNote(
        'Für Wirkdruckmessungen mit Nullpunkt 0 und konstanten Stoff-/Betriebsdaten. Die Wurzel nur einmal anwenden: Ein bereits auf Durchfluss radiziertes Transmittersignal darf nicht nochmals radiziert werden. Keine Dichte-, Gasdruck- oder Temperaturkompensation.',
      ),
    ],
  );
}
