import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/thermocouples.dart';
import '../../widgets/calculator_page.dart';

String formatMillivolts(double value) => (value.abs() < 0.0000005 ? 0.0 : value)
    .toStringAsFixed(6)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

class ThermocoupleScreen extends StatefulWidget {
  const ThermocoupleScreen({super.key});
  @override
  State<ThermocoupleScreen> createState() => _ThermocoupleScreenState();
}

class _ThermocoupleScreenState extends CalculatorState<ThermocoupleScreen> {
  String type = 'K', direction = 'Temperatur → Spannung';
  bool get forward => direction.startsWith('Temperatur');
  @override
  void initState() {
    super.initState();
    setup({'value': '100', 'reference': '0'});
  }

  void resetInput() {
    fields['value']!.text = forward ? (type == 'B' ? '500' : '100') : '10';
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'Thermoelemente',
    children: [
      menu('Typ', type, Thermocouples.types, (v) {
        type = v;
        resetInput();
      }),
      menu(
        'Richtung',
        direction,
        ['Temperatur → Spannung', 'Spannung → Temperatur'],
        (v) {
          direction = v;
          resetInput();
        },
      ),
      input(
        'value',
        forward ? 'Temperatur der Messstelle' : 'Gemessene Thermospannung',
        forward ? '°C' : 'mV',
      ),
      input('reference', 'Vergleichsstellentemperatur', '°C'),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Wrap(
          spacing: 8,
          children: [
            for (final t in [0, 20, 25])
              ChoiceChip(
                selected: parseNumber(fields['reference']!.text) == t,
                showCheckmark: false,
                label: Text('$t °C'),
                onSelected: (_) =>
                    setState(() => fields['reference']!.text = '$t'),
              ),
          ],
        ),
      ),
      result(() {
        final reference = number('reference');
        final referenceEmf = Thermocouples.emf(type, reference);
        final value = forward
            ? Thermocouples.millivolts(
                type,
                number('value'),
                reference: reference,
              )
            : Thermocouples.temperature(
                type,
                number('value'),
                reference: reference,
              );
        final hot = forward ? number('value') : value;
        return ResultCard(
          title: forward
              ? 'THERMOSPANNUNG · TYP $type'
              : 'MESSSTELLENTEMPERATUR · TYP $type',
          value: forward ? formatMillivolts(value) : formatNumber(value),
          unit: forward ? 'mV' : '°C',
          lines: [
            'Messstelle: ${formatNumber(hot)} °C · E₀ = ${formatMillivolts(Thermocouples.emf(type, hot))} mV',
            'Vergleichsstelle: ${formatNumber(reference)} °C · E₀ = ${formatMillivolts(referenceEmf)} mV',
            'Egemessen = E(Messstelle) − E(Vergleichsstelle)',
          ],
        );
      }),
      ToolNote(
        '${type == 'A' || type == 'C' ? 'BIPM / IEC 60584-1' : 'NIST ITS-90'}: Typ $type, Kennlinienbereich ${formatNumber(Thermocouples.minTemperature(type))} … ${formatNumber(Thermocouples.maxTemperature(type))} °C. Spannung in mV. E₀ bezeichnet die Kennlinienspannung mit festem Bezug auf 0 °C. Auch die Vergleichsstelle muss im Kennlinienbereich liegen.',
      ),
      if (type == 'B')
        const ToolNote(
          'Typ B: Rückrechnung auf 250 … 1820 °C begrenzt. Im unteren Bereich ist die Kennlinie nicht überall eindeutig und die Thermospannung sehr klein.',
        ),
      const ToolNote(
        'Idealwerte ohne Sensortoleranz, Leitungsfehler oder Messgerätefehler. Bei bereits kompensierter, auf 0 °C bezogener mV-Anzeige die Vergleichsstelle hier auf 0 °C setzen. Der Kennlinienbereich ist keine Zusage für den Einsatzbereich eines konkreten Fühlers.',
      ),
    ],
  );
}
