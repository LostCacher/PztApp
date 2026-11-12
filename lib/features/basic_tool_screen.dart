import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';
import '../core/calculations.dart';
import '../widgets/brand.dart';

enum BasicToolKind { signal, percent, temperature, motor, torque }

class BasicToolScreen extends StatefulWidget {
  const BasicToolScreen({super.key, required this.kind, required this.title});
  final BasicToolKind kind;
  final String title;
  @override
  State<BasicToolScreen> createState() => _BasicToolScreenState();
}

class _BasicToolScreenState extends State<BasicToolScreen> {
  final fields = <String, TextEditingController>{};
  String mode = '';
  String signal = '4–20 mA';
  String sensor = 'Pt100';
  int poles = 4;
  bool useSlip = false;
  String supply = 'Drehstrom (3~)';

  String get processUnit => fields['unit']?.text.trim() ?? '';
  double get signalLow => signal == '4–20 mA' ? 4 : 0;
  double get signalHigh => signal == '0–10 V' ? 10 : 20;
  String get signalUnit => signal == '0–10 V' ? 'V' : 'mA';
  bool get signalPercentInput => mode.startsWith('Prozent →');
  String get signalInputUnit => signalPercentInput
      ? '%'
      : mode.startsWith('Signal')
      ? signalUnit
      : processUnit;

  @override
  void initState() {
    super.initState();
    final defaults = switch (widget.kind) {
      BasicToolKind.signal => {
        'value': '12',
        'min': '0',
        'max': '100',
        'unit': 'bar',
      },
      BasicToolKind.percent => {'base': '200', 'part': '50', 'rate': '25'},
      BasicToolKind.temperature => {'value': '100'},
      BasicToolKind.motor => {'value': '50', 'slip': '3'},
      BasicToolKind.torque => {
        'shaftPower': '7,5',
        'rpm': '1450',
        'voltage': '400',
        'current': '15',
        'powerFactor': '0,85',
        'efficiency': '90',
      },
    };
    for (final entry in defaults.entries) {
      fields[entry.key] = TextEditingController(text: entry.value);
    }
    mode = switch (widget.kind) {
      BasicToolKind.signal => 'Signal → Prozesswert',
      BasicToolKind.percent => 'Prozentwert',
      BasicToolKind.temperature => '°C → Ω',
      BasicToolKind.motor => 'Hz → U/min',
      BasicToolKind.torque => 'Wellenleistung P₂',
    };
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  double number(String key) {
    final value = parseNumber(fields[key]!.text);
    if (value == null) throw ArgumentError('Bitte gültige Zahlen eingeben.');
    return value;
  }

  Widget input(String key, String label, String unit) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextField(
      key: ValueKey('input-$key'),
      controller: fields[key],
      onChanged: (_) => setState(() {}),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(labelText: label, suffixText: unit),
    ),
  );

  Widget select<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<T>(
      key: ValueKey('select-$label'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text('$item')))
          .toList(),
      onChanged: (next) {
        if (next != null) setState(() => change(next));
      },
    ),
  );

  void changeMode(String next) {
    mode = next;
    // Reset the unit-dependent input to a valid, clear example.
    if (widget.kind == BasicToolKind.signal) {
      fields['value']!.text = next.startsWith('Signal')
          ? (signal == '0–10 V'
                ? '5'
                : signal == '0–20 mA'
                ? '10'
                : '12')
          : signalPercentInput
          ? '50'
          : formatNumber(
              ((parseNumber(fields['min']!.text) ?? 0) +
                      (parseNumber(fields['max']!.text) ?? 100)) /
                  2,
            );
    } else if (widget.kind == BasicToolKind.temperature) {
      fields['value']!.text = next.startsWith('°C')
          ? '100'
          : (sensor == 'Pt100' ? '100' : '1000');
    } else if (widget.kind == BasicToolKind.motor) {
      fields['value']!.text = next.startsWith('Hz') ? '50' : '1500';
    }
  }

  List<Widget> controls() => switch (widget.kind) {
    BasicToolKind.signal => [
      select('Richtung', mode, [
        'Signal → Prozesswert',
        'Prozesswert → Signal',
        'Prozent → Signal & Prozesswert',
      ], changeMode),
      select('Signalbereich', signal, ['0–20 mA', '4–20 mA', '0–10 V'], (v) {
        signal = v;
        changeMode(mode);
      }),
      input(
        'value',
        signalPercentInput
            ? 'Prozent des Messbereichs'
            : mode.startsWith('Signal')
            ? 'Eingangssignal'
            : 'Prozesswert',
        signalInputUnit,
      ),
      Row(
        children: [
          Expanded(child: input('min', 'Prozessminimum', processUnit)),
          const SizedBox(width: 12),
          Expanded(child: input('max', 'Prozessmaximum', processUnit)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextField(
          key: const ValueKey('input-unit'),
          controller: fields['unit'],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Prozesseinheit',
            hintText: 'z. B. bar, °C, l/min',
          ),
        ),
      ),
      signalSlider(),
    ],
    BasicToolKind.percent => [
      select('Gesucht', mode, [
        'Prozentwert',
        'Prozentsatz',
        'Grundwert',
      ], changeMode),
      if (mode != 'Grundwert') input('base', 'Grundwert', ''),
      if (mode != 'Prozentwert') input('part', 'Prozentwert / Anteil', ''),
      if (mode != 'Prozentsatz') input('rate', 'Prozentsatz', '%'),
    ],
    BasicToolKind.temperature => [
      select('Sensor', sensor, ['Pt100', 'Pt1000'], (v) {
        sensor = v;
        changeMode(mode);
      }),
      select('Richtung', mode, ['°C → Ω', 'Ω → °C'], changeMode),
      input(
        'value',
        mode.startsWith('°C') ? 'Temperatur' : 'Widerstand',
        mode.startsWith('°C') ? '°C' : 'Ω',
      ),
    ],
    BasicToolKind.motor => [
      select('Richtung', mode, ['Hz → U/min', 'U/min → Hz'], changeMode),
      select('Polzahl (nicht Polpaarzahl)', poles, [
        2,
        4,
        6,
        8,
        10,
        12,
      ], (v) => poles = v),
      input(
        'value',
        mode.startsWith('Hz')
            ? 'Elektrische Frequenz'
            : useSlip
            ? 'Motordrehzahl'
            : 'Synchrondrehzahl',
        mode.startsWith('Hz') ? 'Hz' : 'U/min',
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Schlupf berücksichtigen'),
        subtitle: const Text('Optional für Asynchronmotoren'),
        value: useSlip,
        onChanged: (value) => setState(() => useSlip = value),
      ),
      if (useSlip) input('slip', 'Schlupf', '%'),
    ],
    BasicToolKind.torque => [
      select('Berechnungsgrundlage', mode, [
        'Wellenleistung P₂',
        'Elektrische Motordaten',
      ], changeMode),
      if (mode == 'Wellenleistung P₂')
        input('shaftPower', 'Mechanische Leistung P₂', 'kW')
      else ...[
        select('Motorart', supply, [
          'Drehstrom (3~)',
          'Wechselstrom (1~)',
          'Gleichstrom (DC)',
        ], (v) => supply = v),
        input(
          'voltage',
          supply == 'Drehstrom (3~)' ? 'Außenleiterspannung' : 'Spannung',
          'V',
        ),
        input(
          'current',
          supply == 'Drehstrom (3~)' ? 'Außenleiterstrom' : 'Strom',
          'A',
        ),
        if (supply != 'Gleichstrom (DC)')
          input('powerFactor', 'Leistungsfaktor cos φ', ''),
        input('efficiency', 'Wirkungsgrad η', '%'),
      ],
      input('rpm', 'Nenndrehzahl / Betriebsdrehzahl', 'U/min'),
    ],
  };

  Widget signalSlider() {
    final min = parseNumber(fields['min']!.text);
    final max = parseNumber(fields['max']!.text);
    final inputValue = parseNumber(fields['value']!.text);
    final forward = mode.startsWith('Signal');
    final enabled =
        min != null && max != null && min != max && (max - min).isFinite;
    final low = signalPercentInput
        ? 0.0
        : forward
        ? signalLow
        : min ?? 0;
    final high = signalPercentInput
        ? 100.0
        : forward
        ? signalHigh
        : max ?? 1;
    final fraction = enabled && inputValue != null
        ? (inputValue - low) / (high - low)
        : 0.5;
    final value = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wert verschieben',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Slider(
            key: const ValueKey('signal-slider'),
            value: value,
            label:
                '${formatNumber(low + value * (high - low))} $signalInputUnit',
            semanticFormatterCallback: (v) =>
                '${formatNumber(low + v * (high - low))} $signalInputUnit',
            onChanged: enabled
                ? (v) => setState(() {
                    fields['value']!.text = formatNumber(
                      low + v * (high - low),
                    );
                  })
                : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatNumber(low)} $signalInputUnit',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                '${formatNumber(high)} $signalInputUnit',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          if (enabled && inputValue != null && (fraction < 0 || fraction > 1))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Eingabe außerhalb des Sliderbereichs; der eingegebene Wert wird berechnet.',
                style: TextStyle(color: AppColors.pink, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  ({String value, String unit, String detail, double? progress}) calculate() {
    double result;
    var unit = '';
    var detail = '';
    double? progress;
    switch (widget.kind) {
      case BasicToolKind.signal:
        final low = signalLow;
        final high = signalHigh;
        final min = number('min');
        final max = number('max');
        if (min == max) {
          throw ArgumentError(
            'Prozessminimum und -maximum müssen verschieden sein.',
          );
        }
        final forward = mode.startsWith('Signal');
        progress = signalPercentInput
            ? number('value') / 100
            : forward
            ? (number('value') - low) / (high - low)
            : (number('value') - min) / (max - min);
        result = signalPercentInput
            ? Calculations.scale(number('value'), 0, 100, low, high)
            : forward
            ? Calculations.scale(number('value'), low, high, min, max)
            : Calculations.scale(number('value'), min, max, low, high);
        unit = forward ? processUnit : signalUnit;
        detail = forward
            ? 'Signal: ${formatNumber(number('value'))} $signalUnit'
            : 'Prozesswert (absolut): ${formatNumber(signalPercentInput ? Calculations.scale(number('value'), 0, 100, min, max) : number('value'))} $processUnit';
        detail += '\n${formatNumber(progress * 100)} % des Messbereichs';
        if (progress < 0 || progress > 1) {
          detail += '\nAußerhalb des Messbereichs · linear extrapoliert';
        }
        break;
      case BasicToolKind.percent:
        if (mode == 'Prozentwert') {
          result = number('base') * number('rate') / 100;
          detail = 'Anteil = Grundwert × Prozentsatz / 100';
        } else if (mode == 'Prozentsatz') {
          if (number('base') == 0) {
            throw ArgumentError('Der Grundwert darf nicht 0 sein.');
          }
          result = number('part') / number('base') * 100;
          unit = '%';
          detail = 'Prozentsatz = Anteil / Grundwert × 100';
        } else {
          if (number('rate') == 0) {
            throw ArgumentError('Der Prozentsatz darf nicht 0 sein.');
          }
          result = number('part') / number('rate') * 100;
          detail = 'Grundwert = Anteil / Prozentsatz × 100';
        }
        break;
      case BasicToolKind.temperature:
        final r0 = sensor == 'Pt100' ? 100.0 : 1000.0;
        result = mode.startsWith('°C')
            ? Calculations.resistance(number('value'), r0)
            : Calculations.temperature(number('value'), r0);
        unit = mode.startsWith('°C') ? 'Ω' : '°C';
        detail =
            '$sensor · α = 0,00385 · −200 bis +850 °C\nCallendar-Van-Dusen-Kennlinie (IEC 60751)';
        break;
      case BasicToolKind.motor:
        final slip = useSlip ? number('slip') : 0.0;
        final forward = mode.startsWith('Hz');
        result = forward
            ? Calculations.motorRpm(number('value'), poles, slipPercent: slip)
            : Calculations.motorFrequency(
                number('value'),
                poles,
                slipPercent: slip,
              );
        unit = forward ? 'U/min' : 'Hz';
        final hz = forward ? number('value') : result;
        final synchronous = Calculations.synchronousRpm(hz, poles);
        detail = useSlip
            ? 'Schlupf: ${formatNumber(slip)} %\nSynchrondrehzahl: ${formatNumber(synchronous)} U/min\nn = (120 × f / Polzahl) × (1 − s / 100)'
            : 'n = 120 × f / Polzahl\nSynchrondrehzahl ohne Schlupf.';
        break;
      case BasicToolKind.torque:
        double shaftPower;
        if (mode == 'Wellenleistung P₂') {
          shaftPower = number('shaftPower');
          detail = 'Wellenleistung P₂: ${formatNumber(shaftPower)} kW';
        } else {
          final motorSupply = switch (supply) {
            'Drehstrom (3~)' => MotorSupply.threePhase,
            'Wechselstrom (1~)' => MotorSupply.singlePhase,
            _ => MotorSupply.dc,
          };
          final inputPower = Calculations.electricalPowerKw(
            number('voltage'),
            number('current'),
            motorSupply,
            powerFactor: motorSupply == MotorSupply.dc
                ? 1
                : number('powerFactor'),
          );
          shaftPower = Calculations.shaftPowerKw(
            inputPower,
            number('efficiency'),
          );
          detail =
              'Aufnahmeleistung P₁: ${formatNumber(inputPower)} kW\nWellenleistung P₂: ${formatNumber(shaftPower)} kW\nP₂ = P₁ × η / 100';
          detail += switch (motorSupply) {
            MotorSupply.threePhase => '\nP₁ = √3 × U × I × cos φ / 1000',
            MotorSupply.singlePhase => '\nP₁ = U × I × cos φ / 1000',
            MotorSupply.dc => '\nP₁ = U × I / 1000',
          };
        }
        result = Calculations.torque(shaftPower, number('rpm'));
        unit = 'Nm';
        detail +=
            '\nDrehzahl: ${formatNumber(number('rpm'))} U/min\nM = P₂ × 60000 / (2π × n)';
        break;
    }
    if (!result.isFinite || (progress != null && !progress.isFinite)) {
      throw ArgumentError('Wert zu groß. Bitte kleinere Zahlen verwenden.');
    }
    return (
      value: formatNumber(result),
      unit: unit,
      detail: detail,
      progress: progress,
    );
  }

  Widget resultCard() {
    try {
      final result = calculate();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E2145), Color(0xFF251B31)],
          ),
          border: Border.all(color: const Color(0xFF60427E)),
        ),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.kind == BasicToolKind.signal
                    ? mode.startsWith('Signal')
                          ? 'PROZESSWERT · ABSOLUT'
                          : 'AUSGANGSSIGNAL'
                    : widget.kind == BasicToolKind.motor &&
                          mode.startsWith('Hz')
                    ? useSlip
                          ? 'MOTORDREHZAHL'
                          : 'SYNCHRONDREHZAHL'
                    : 'ERGEBNIS',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                '${result.value} ${result.unit}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              if (result.progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: result.progress!.clamp(0, 1),
                    minHeight: 6,
                    color: AppColors.pink,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                result.detail,
                style: const TextStyle(
                  color: Color(0xFFCEC0DE),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    } on ArgumentError catch (error) {
      return Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${error.message}',
            style: const TextStyle(color: AppColors.pink),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WERKZEUG',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Werte eingeben. Ergebnis direkt ablesen.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 28),
                      ...controls(),
                      resultCard(),
                      if (widget.kind == BasicToolKind.temperature)
                        const Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Text(
                            'Idealwerte der Platin-Kennlinie. Leitungswiderstand, Eigenerwärmung und Sensortoleranzen sind nicht eingerechnet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      if (widget.kind == BasicToolKind.torque)
                        const Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Text(
                            'Für das Nenndrehmoment P₂ und Nenndrehzahl vom Typenschild verwenden. Elektrische Werte, cos φ und Wirkungsgrad müssen zum selben Betriebspunkt gehören. Bei Drehstrom: symmetrisches Netz, Außenleiterwerte; bei Wechselstrom: Effektivwerte. Aus dieser Leistungsformel lässt sich kein Anlaufmoment bei Stillstand bestimmen.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      if (widget.kind == BasicToolKind.motor)
                        const Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Text(
                            'Bei Asynchronmotoren liegt die tatsächliche Motordrehzahl im Motorbetrieb unter der Synchrondrehzahl.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const DeveloperCredit(),
        ],
      ),
    ),
  );
}
