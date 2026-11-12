import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});
  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends CalculatorState<CalibrationScreen> {
  String signal = '4–20 mA';
  static const points = [0, 25, 50, 75, 100];
  @override
  void initState() {
    super.initState();
    setup({
      'min': '0',
      'max': '100',
      'unit': 'bar',
      'tolerance': '0,5',
      for (final p in points) 'actual$p': '',
    });
  }

  Widget table() {
    final min = number('min'),
        max = number('max'),
        tolerance = number('tolerance');
    positive(tolerance, 'Toleranz', zero: true);
    // Validate both bounds even if no actual values have been entered.
    ProcessCalculations.scale(0, 0, 100, min, max);
    final signalMin = signal == '4–20 mA' ? 4.0 : 0.0,
        signalMax = signal == '0–10 V' ? 10.0 : 20.0;
    final unit = fields['unit']!.text;
    final rows = points.map((p) {
      final nominal = ProcessCalculations.scale(p.toDouble(), 0, 100, min, max);
      final output = ProcessCalculations.scale(
        p.toDouble(),
        0,
        100,
        signalMin,
        signalMax,
      );
      final actual = fields['actual$p']!.text.trim().isEmpty
          ? null
          : number('actual$p');
      final deviation = actual == null
          ? null
          : ProcessCalculations.deviation(actual, nominal, min, max);
      final passed = deviation != null && deviation.abs() <= tolerance + 1e-10;
      return DataRow(
        cells: [
          DataCell(Text('$p %')),
          DataCell(Text(formatNumber(output))),
          DataCell(Text(formatNumber(nominal))),
          DataCell(Text(actual == null ? '—' : formatNumber(actual))),
          DataCell(Text(actual == null ? '—' : formatNumber(actual - nominal))),
          DataCell(Text(deviation == null ? '—' : formatNumber(deviation))),
          DataCell(
            Text(
              deviation == null
                  ? 'Offen'
                  : passed
                  ? 'i. O.'
                  : 'Außerhalb',
              style: TextStyle(
                color: deviation == null
                    ? AppColors.muted
                    : passed
                    ? const Color(0xFF65D9CC)
                    : AppColors.pink,
              ),
            ),
          ),
        ],
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRÜFPUNKTE',
          style: TextStyle(
            color: AppColors.purple,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            columns: [
              const DataColumn(label: Text('Punkt')),
              DataColumn(
                label: Text('Soll ${signal == '0–10 V' ? 'V' : 'mA'}'),
              ),
              DataColumn(label: Text('Soll $unit')),
              DataColumn(label: Text('Ist $unit')),
              DataColumn(label: Text('Δ $unit')),
              const DataColumn(label: Text('Δ % Spanne')),
              const DataColumn(label: Text('Bewertung')),
            ],
            rows: rows,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bewertung mit ±${formatNumber(tolerance)} % der Messspanne.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    title: '5-Punkt-Kalibrierhelfer',
    children: [
      menu('Signalbereich', signal, [
        '0–20 mA',
        '4–20 mA',
        '0–10 V',
      ], (v) => signal = v),
      input('min', 'Prozessminimum', ''),
      input('max', 'Prozessmaximum', ''),
      input('unit', 'Prozesseinheit', '', text: true),
      input('tolerance', 'Zulässige Abweichung ±', '% Spanne'),
      const ToolNote(
        'Optional: tatsächliche Prozessanzeige zu jedem Sollsignal eintragen. Die Tabelle lässt sich seitlich verschieben.',
      ),
      for (final p in points)
        input('actual$p', 'Ist-Prozesswert bei $p %', fields['unit']!.text),
      result(table),
      const ToolNote(
        'Abweichung = Ist − Soll; Prozentabweichung bezogen auf den Betrag der Messspanne. Die Toleranz ist deine Vorgabe und keine automatische Geräte- oder Normfreigabe. Hier wird eine lineare Kennlinie geprüft.',
      ),
    ],
  );
}
