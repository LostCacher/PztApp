import 'dart:math' as math;

import 'calculations.dart';

const pressureFactors = <String, double>{
  'bar': 100000,
  'mbar': 100,
  'Pa': 1,
  'hPa': 100,
  'kPa': 1000,
  'MPa': 1000000,
  'psi': 6894.757293168,
  'mWS': 9806.65,
  'atm': 101325,
  'Torr': 101325 / 760,
  'mmHg': 133.322387415,
};

double finiteResult(double value) {
  if (!value.isFinite) throw ArgumentError('Werte zu groß für die Berechnung.');
  return value;
}

void positive(double value, String label, {bool zero = false}) {
  if (!value.isFinite || (zero ? value < 0 : value <= 0)) {
    throw ArgumentError(
      '$label muss ${zero ? 'größer oder gleich' : 'größer als'} 0 sein.',
    );
  }
}

abstract final class ProcessCalculations {
  static double pressure(double value, String from, String to) {
    if (!value.isFinite ||
        !pressureFactors.containsKey(from) ||
        !pressureFactors.containsKey(to)) {
      throw ArgumentError('Ungültiger Druckwert oder unbekannte Einheit.');
    }
    return finiteResult(
      value * (pressureFactors[from]! / pressureFactors[to]!),
    );
  }

  static double scale(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (![value, inMin, inMax, outMin, outMax].every((v) => v.isFinite)) {
      throw ArgumentError('Bitte gültige Zahlen eingeben.');
    }
    return finiteResult(
      Calculations.scale(value, inMin, inMax, outMin, outMax),
    );
  }

  static double deviation(
    double actual,
    double nominal,
    double min,
    double max,
  ) {
    if (min == max) {
      throw ArgumentError('Messbereichsgrenzen müssen verschieden sein.');
    }
    return finiteResult((actual - nominal) / (max - min).abs() * 100);
  }

  static double flow(double dp, double dpMax, double flowMax) {
    positive(dp, 'Differenzdruck', zero: true);
    positive(dpMax, 'Maximaler Differenzdruck');
    positive(flowMax, 'Maximaler Durchfluss');
    return finiteResult(flowMax * math.sqrt(dp / dpMax));
  }

  static double differentialPressure(
    double flow,
    double dpMax,
    double flowMax,
  ) {
    positive(flow, 'Durchfluss', zero: true);
    positive(dpMax, 'Maximaler Differenzdruck');
    positive(flowMax, 'Maximaler Durchfluss');
    return finiteResult(dpMax * math.pow(flow / flowMax, 2));
  }

  static double level(double pressurePa, double density) {
    positive(pressurePa, 'Hydrostatischer Druck', zero: true);
    positive(density, 'Dichte');
    return finiteResult(pressurePa / (density * 9.80665));
  }

  static double hydrostaticPressure(double height, double density) {
    positive(height, 'Füllhöhe', zero: true);
    positive(density, 'Dichte');
    return finiteResult(height * density * 9.80665);
  }

  static ({double filled, double total}) tank(
    String shape,
    double fill, {
    required double height,
    required double length,
    required double width,
    required double diameter,
  }) {
    positive(fill, 'Füllhöhe', zero: true);
    double fullHeight, full, content;
    switch (shape) {
      case 'Quader':
        positive(height, 'Tankhöhe');
        positive(length, 'Länge');
        positive(width, 'Breite');
        fullHeight = height;
        full = length * width * height;
        content = length * width * fill;
      case 'Zylinder stehend':
        positive(height, 'Tankhöhe');
        positive(diameter, 'Durchmesser');
        fullHeight = height;
        full = math.pi * diameter * diameter / 4 * height;
        content = math.pi * diameter * diameter / 4 * fill;
      case 'Zylinder liegend':
        positive(length, 'Länge');
        positive(diameter, 'Durchmesser');
        fullHeight = diameter;
        final r = diameter / 2;
        if (fill > fullHeight) {
          throw ArgumentError('Füllhöhe überschreitet den Durchmesser.');
        }
        full = math.pi * r * r * length;
        content =
            (r * r * math.acos(((r - fill) / r).clamp(-1, 1)) -
                (r - fill) *
                    math.sqrt(math.max(0, 2 * r * fill - fill * fill))) *
            length;
      case 'Kugel':
        positive(diameter, 'Durchmesser');
        fullHeight = diameter;
        final r = diameter / 2;
        full = 4 / 3 * math.pi * r * r * r;
        content = math.pi * fill * fill * (r - fill / 3);
      default:
        throw ArgumentError('Unbekannte Tankform.');
    }
    if (fill > fullHeight) {
      throw ArgumentError('Füllhöhe überschreitet die Tankhöhe.');
    }
    return (filled: finiteResult(content), total: finiteResult(full));
  }
}

abstract final class ElectricalCalculations {
  static ({double voltage, double current, double resistance, double power})
  solve(String pair, double a, double b) {
    positive(a, 'Erster Eingabewert');
    positive(b, 'Zweiter Eingabewert');
    double u, i;
    switch (pair) {
      case 'U + I':
        u = a;
        i = b;
      case 'U + R':
        u = a;
        i = a / b;
      case 'I + R':
        u = a * b;
        i = a;
      case 'P + U':
        u = b;
        i = a / b;
      case 'P + I':
        u = a / b;
        i = b;
      case 'P + R':
        u = math.sqrt(a * b);
        i = math.sqrt(a / b);
      default:
        throw ArgumentError('Unbekannte Eingabekombination.');
    }
    return (
      voltage: finiteResult(u),
      current: finiteResult(i),
      resistance: finiteResult(u / i),
      power: finiteResult(u * i),
    );
  }
}
