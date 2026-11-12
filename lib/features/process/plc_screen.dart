import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class PlcScreen extends StatefulWidget {
  const PlcScreen({super.key});
  @override
  State<PlcScreen> createState() => _PlcScreenState();
}

class _PlcScreenState extends CalculatorState<PlcScreen> {
  String direction = 'Rohwert → Prozesswert', preset = 'Siemens 0 … 27648';
  static const presets = {
    'Siemens 0 … 27648': (0, 27648),
    'Bipolar −27648 … 27648': (-27648, 27648),
    '12 Bit 0 … 4095': (0, 4095),
    '16 Bit 0 … 65535': (0, 65535),
    'Eigener Bereich': (0, 27648),
  };
  @override
  void initState() {
    super.initState();
    setup({
      'value': '13824',
      'rawMin': '0',
      'rawMax': '27648',
      'min': '0',
      'max': '100',
      'unit': '°C',
    });
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'SPS-Rohwertskalierung',
    children: [
      menu(
        'Richtung',
        direction,
        ['Rohwert → Prozesswert', 'Prozesswert → Rohwert'],
        (v) {
          direction = v;
          fields['value']!.text = v.startsWith('Rohwert')
              ? fields['rawMin']!.text
              : fields['min']!.text;
        },
      ),
      menu('Rohwert-Vorlage', preset, presets.keys.toList(), (v) {
        preset = v;
        if (v != 'Eigener Bereich') {
          fields['rawMin']!.text = '${presets[v]!.$1}';
          fields['rawMax']!.text = '${presets[v]!.$2}';
        }
      }),
      input(
        'value',
        direction.startsWith('Rohwert') ? 'Rohwert' : 'Prozesswert',
        direction.startsWith('Rohwert') ? '' : fields['unit']!.text,
      ),
      input('rawMin', 'Rohwert Minimum', ''),
      input('rawMax', 'Rohwert Maximum', ''),
      input('min', 'Prozessminimum', ''),
      input('max', 'Prozessmaximum', ''),
      input('unit', 'Prozesseinheit', '', text: true),
      result(() {
        final forward = direction.startsWith('Rohwert');
        final inMin = number(forward ? 'rawMin' : 'min'),
            inMax = number(forward ? 'rawMax' : 'max');
        final outMin = number(forward ? 'min' : 'rawMin'),
            outMax = number(forward ? 'max' : 'rawMax');
        final value = ProcessCalculations.scale(
          number('value'),
          inMin,
          inMax,
          outMin,
          outMax,
        );
        final percent = ProcessCalculations.scale(
          number('value'),
          inMin,
          inMax,
          0,
          100,
        );
        return ResultCard(
          title: forward ? 'PROZESSWERT' : 'ROHWERT',
          value: formatNumber(value),
          unit: forward ? fields['unit']!.text : '',
          lines: [
            '${formatNumber(percent)} % des Messbereichs',
            if (!forward) 'Auf ganze Zählwerte gerundet: ${value.round()}',
            if (percent < 0 || percent > 100)
              'Außerhalb des Nennbereichs · linear extrapoliert',
          ],
        );
      }),
      const ToolNote(
        'Rohwertgrenzen bleiben frei editierbar. Vorlage und Messbereich müssen zur Kanalkonfiguration und zum Modul passen. Diagnose-, Überlauf- und Fehlercodes sind keine gültigen Messwerte und werden hier nicht automatisch erkannt.',
      ),
    ],
  );
}
