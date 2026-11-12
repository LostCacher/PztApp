import 'package:material_ui/material_ui.dart';

import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class TankScreen extends StatefulWidget {
  const TankScreen({super.key});
  @override
  State<TankScreen> createState() => _TankScreenState();
}

class _TankScreenState extends CalculatorState<TankScreen> {
  String shape = 'Zylinder liegend';
  @override
  void initState() {
    super.initState();
    setup({
      'fill': '0,5',
      'height': '2',
      'length': '3',
      'width': '2',
      'diameter': '1',
    });
  }

  bool get diameterHeight => shape == 'Zylinder liegend' || shape == 'Kugel';
  Widget slider() {
    final max = parseNumber(
      fields[diameterHeight ? 'diameter' : 'height']!.text,
    );
    final fill = parseNumber(fields['fill']!.text);
    final enabled = max != null && max > 0;
    final fraction = enabled && fill != null ? fill / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Slider(
        key: const ValueKey('tank-slider'),
        value: fraction.isFinite ? fraction.clamp(0, 1) : 0,
        semanticFormatterCallback: (v) =>
            '${formatNumber(v * (max ?? 0))} Meter',
        onChanged: enabled
            ? (v) =>
                  setState(() => fields['fill']!.text = formatNumber(v * max))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: 'Tankvolumen',
    children: [
      menu('Tankform', shape, [
        'Quader',
        'Zylinder stehend',
        'Zylinder liegend',
        'Kugel',
      ], (v) => shape = v),
      if (shape != 'Quader') input('diameter', 'Innendurchmesser', 'm'),
      if (shape == 'Quader' || shape == 'Zylinder liegend')
        input('length', 'Innenlänge', 'm'),
      if (shape == 'Quader') input('width', 'Innenbreite', 'm'),
      if (!diameterHeight) input('height', 'Innere Tankhöhe', 'm'),
      input('fill', 'Füllhöhe ab Tankboden', 'm'),
      slider(),
      result(() {
        final r = ProcessCalculations.tank(
          shape,
          number('fill'),
          height: number('height'),
          length: number('length'),
          width: number('width'),
          diameter: number('diameter'),
        );
        return ResultCard(
          title: 'FÜLLVOLUMEN',
          value: formatNumber(r.filled),
          unit: 'm³',
          lines: [
            '${formatNumber(finiteResult(r.filled * 1000))} Liter',
            'Gesamtvolumen: ${formatNumber(r.total)} m³',
            'Volumenfüllgrad: ${formatNumber(finiteResult(r.filled / r.total * 100))} %',
            'Freies Volumen: ${formatNumber(r.total - r.filled)} m³',
          ],
        );
      }),
      const ToolNote(
        'Ideale Geometrien mit Innenmaßen, ebener Einbaulage und ohne Einbauten. Zylinder mit ebenen Stirnflächen; gewölbte Böden sind nicht enthalten. Beim liegenden Zylinder entspricht halbe Füllhöhe halbem Volumen, andere Füllstände sind nicht linear.',
      ),
    ],
  );
}
