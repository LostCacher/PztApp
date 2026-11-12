import 'package:material_ui/material_ui.dart';

import '../../core/ac_calculations.dart';
import '../../core/calculations.dart';
import '../../core/process_calculations.dart';
import '../../widgets/calculator_page.dart';

class ElectricalScreen extends StatefulWidget {
  const ElectricalScreen({super.key});
  @override
  State<ElectricalScreen> createState() => _ElectricalScreenState();
}

class _ElectricalScreenState extends CalculatorState<ElectricalScreen> {
  String supply = 'Gleichstrom (DC)', pair = 'U + I';
  String connection = 'Stern (Y)', load = 'Induktiv';
  bool get ac => supply != 'Gleichstrom (DC)';
  bool get threePhase => supply == 'Drehstrom (3~)';
  static const dcPairs = ['U + I', 'U + R', 'I + R', 'P + U', 'P + I', 'P + R'];
  static const acPairs = [
    'U + I',
    'U + Z',
    'I + Z',
    'P + U',
    'P + I',
    'P + Z',
    'S + U',
    'S + I',
  ];

  @override
  void initState() {
    super.initState();
    setup({
      'U': '24',
      'I': '2',
      'R': '12',
      'P': '48',
      'Z': '115',
      'S': '460',
      'powerFactor': '0,8',
    });
  }

  void changeSupply(String next) {
    supply = next;
    pair = 'U + I';
    final example = !ac
        ? {'U': '24', 'I': '2', 'P': '48', 'R': '12'}
        : threePhase
        ? {
            'U': '400',
            'I': '10',
            'P': '5542,562584',
            'S': '6928,20323',
            'Z': connection == 'Stern (Y)' ? '23,094010768' : '69,282032303',
          }
        : {'U': '230', 'I': '2', 'P': '368', 'S': '460', 'Z': '115'};
    for (final entry in example.entries) {
      fields[entry.key]!.text = entry.value;
    }
  }

  (String, String) label(String key) => switch (key) {
    'U' => (
      threePhase
          ? 'Außenleiterspannung Uₗ (L–L)'
          : ac
          ? 'Spannung U (Effektivwert)'
          : 'Spannung',
      'V',
    ),
    'I' => (
      threePhase
          ? 'Außenleiterstrom Iₗ'
          : ac
          ? 'Strom I (Effektivwert)'
          : 'Strom',
      'A',
    ),
    'R' => ('Widerstand', 'Ω'),
    'Z' => (threePhase ? 'Strangimpedanz |Z|' : 'Impedanz |Z|', 'Ω'),
    'S' => (threePhase ? 'Gesamtscheinleistung S' : 'Scheinleistung S', 'VA'),
    _ => (
      threePhase
          ? 'Gesamtwirkleistung P'
          : ac
          ? 'Wirkleistung P'
          : 'Leistung',
      'W',
    ),
  };

  Widget dcResult(List<String> keys) {
    final r = ElectricalCalculations.solve(
      pair,
      number(keys[0]),
      number(keys[1]),
    );
    return Column(
      children: [
        ResultCard(
          title: 'SPANNUNG',
          value: formatNumber(r.voltage),
          unit: 'V',
          lines: ['Strom: ${formatNumber(r.current)} A'],
        ),
        ResultCard(
          title: 'WIDERSTAND & LEISTUNG',
          value: formatNumber(r.resistance),
          unit: 'Ω',
          lines: [
            'Leistung: ${formatNumber(r.power)} W',
            'U = R × I · P = U × I',
          ],
        ),
      ],
    );
  }

  Widget acResult(List<String> keys) {
    final factor = number('powerFactor');
    final r = AcCalculations.solve(
      pair,
      number(keys[0]),
      number(keys[1]),
      system: threePhase ? AcSystem.threePhase : AcSystem.singlePhase,
      connection: connection == 'Stern (Y)'
          ? AcConnection.star
          : AcConnection.delta,
      powerFactor: factor,
      capacitive: load == 'Kapazitiv',
    );
    return Column(
      children: [
        ResultCard(
          title: threePhase ? 'AUSSENLEITERWERTE' : 'SPANNUNG & STROM',
          value: formatNumber(r.lineVoltage),
          unit: 'V',
          lines: [
            '${threePhase ? 'Außenleiterstrom Iₗ' : 'Strom I'}: ${formatNumber(r.lineCurrent)} A',
            if (threePhase) ...[
              'Strangspannung: ${formatNumber(r.phaseVoltage)} V',
              'Strangstrom: ${formatNumber(r.phaseCurrent)} A',
              connection == 'Stern (Y)'
                  ? 'Stern: Uₛ = Uₗ / √3 · Iₛ = Iₗ'
                  : 'Dreieck: Uₛ = Uₗ · Iₛ = Iₗ / √3',
            ],
          ],
        ),
        ResultCard(
          title: threePhase ? 'GESAMTWIRKLEISTUNG P' : 'WIRKLEISTUNG P',
          value: formatNumber(r.activePower),
          unit: 'W',
          lines: [
            'Scheinleistung S: ${formatNumber(r.apparentPower)} VA',
            'Blindleistung Q: ${formatNumber(r.reactivePower)} var',
            'cos φ: ${formatNumber(factor)} · φ: ${formatNumber(r.phaseAngle)}°',
            threePhase ? 'S = √3 × Uₗ × Iₗ' : 'S = U × I',
            'P = S × cos φ · Q = S × sin φ',
          ],
        ),
        ResultCard(
          title: threePhase ? 'IMPEDANZ PRO STRANG' : 'IMPEDANZ',
          value: formatNumber(r.impedance),
          unit: 'Ω',
          lines: [
            'Wirkwiderstand R: ${formatNumber(r.resistance)} Ω',
            'Blindwiderstand X: ${formatNumber(r.reactance)} Ω',
            '|Z| = Uₛ / Iₛ · R = |Z| × cos φ',
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = pair.split(' + ');
    return CalculatorPage(
      title: 'Elektrische Grundlagen',
      children: [
        menu('Stromart', supply, [
          'Gleichstrom (DC)',
          'Wechselstrom (1~)',
          'Drehstrom (3~)',
        ], changeSupply),
        if (threePhase)
          menu('Schaltung', connection, [
            'Stern (Y)',
            'Dreieck (Δ)',
          ], (v) => connection = v),
        KeyedSubtree(
          key: ValueKey('pairs-$supply'),
          child: menu(
            'Bekannte Größen',
            pair,
            ac ? acPairs : dcPairs,
            (v) => pair = v,
          ),
        ),
        for (final key in keys) input(key, label(key).$1, label(key).$2),
        if (ac) ...[
          input('powerFactor', 'Leistungsfaktor cos φ', ''),
          menu('Lastcharakter', load, [
            'Induktiv',
            'Kapazitiv',
          ], (v) => load = v),
        ],
        result(() => ac ? acResult(keys) : dcResult(keys)),
        ToolNote(
          !ac
              ? 'Für Gleichstrom und rein ohmsche Lasten. Beide Eingabewerte müssen > 0 sein.'
              : '${threePhase ? 'Für symmetrischen Drehstrom: Uₗ ist die Außenleiterspannung zwischen zwei Phasen, Iₗ der Außenleiterstrom. Z, R und X gelten pro Strang; P, Q und S für alle drei Phasen zusammen. ' : 'Spannung und Strom als Effektivwerte. '}'
                    'Sinusförmige Spannung und sinusförmiger Strom; cos φ = P / S. Induktiv: Q und X positiv, kapazitiv: negativ. Beide Eingabewerte müssen > 0 sein. Bei P als Eingabe muss cos φ > 0 sein.',
        ),
        if (ac)
          const ToolNote(
            'Die Wirkleistung ist die elektrische Leistung der Last. Für mechanische Wellenleistung oder Motordrehmoment mit Wirkungsgrad das Werkzeug „Drehmoment & Leistung“ verwenden.',
          ),
      ],
    );
  }
}
