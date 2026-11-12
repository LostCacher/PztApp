import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/process_calculations.dart';

void main() {
  test('Pressure factors, negative gauge pressure and inverse conversion', () {
    expect(ProcessCalculations.pressure(1, 'bar', 'Pa'), 100000);
    expect(ProcessCalculations.pressure(1, 'atm', 'Pa'), 101325);
    expect(ProcessCalculations.pressure(-1, 'bar', 'mbar'), -1000);
    expect(ProcessCalculations.pressure(1, 'mWS', 'Pa'), 9806.65);
    expect(
      ProcessCalculations.pressure(1, 'psi', 'Pa'),
      closeTo(6894.757293168, 1e-8),
    );
    for (final unit in pressureFactors.keys) {
      expect(
        ProcessCalculations.pressure(
          ProcessCalculations.pressure(12.5, 'bar', unit),
          unit,
          'bar',
        ),
        closeTo(12.5, 1e-9),
      );
    }
    expect(
      () => ProcessCalculations.pressure(double.nan, 'bar', 'Pa'),
      throwsArgumentError,
    );
  });
  test('Raw scaling and calibration deviation use configured spans', () {
    expect(ProcessCalculations.scale(13824, 0, 27648, -50, 150), 50);
    expect(ProcessCalculations.scale(25, 100, 0, 0, 27648), 20736);
    expect(ProcessCalculations.scale(150, 0, 100, 0, 27648), 41472);
    expect(ProcessCalculations.deviation(50.5, 50, 0, 100), .5);
    expect(ProcessCalculations.deviation(49.5, 50, 100, 0), -.5);
    expect(() => ProcessCalculations.scale(0, 0, 0, 0, 1), throwsArgumentError);
    expect(
      () => ProcessCalculations.deviation(1, 1, 0, 0),
      throwsArgumentError,
    );
  });
  test(
    'Square root flow is invertible, permits overrange and rejects negatives',
    () {
      expect(ProcessCalculations.flow(25, 100, 100), 50);
      expect(ProcessCalculations.differentialPressure(50, 100, 100), 25);
      expect(ProcessCalculations.flow(400, 100, 100), 200);
      expect(ProcessCalculations.flow(0, 100, 100), 0);
      expect(() => ProcessCalculations.flow(-1, 100, 100), throwsArgumentError);
      expect(() => ProcessCalculations.flow(1, 0, 100), throwsArgumentError);
    },
  );
  test(
    'Hydrostatic height depends on density and uses differential pressure',
    () {
      expect(ProcessCalculations.level(9806.65, 1000), closeTo(1, 1e-12));
      expect(ProcessCalculations.level(9806.65, 800), closeTo(1.25, 1e-12));
      expect(ProcessCalculations.hydrostaticPressure(2, 1000), 19613.3);
      expect(() => ProcessCalculations.level(-1, 1000), throwsArgumentError);
      expect(() => ProcessCalculations.level(1, 0), throwsArgumentError);
    },
  );
  test('Ohmic circuit resolves all six independent pairs', () {
    final cases = {
      'U + I': (24.0, 2.0),
      'U + R': (24.0, 12.0),
      'I + R': (2.0, 12.0),
      'P + U': (48.0, 24.0),
      'P + I': (48.0, 2.0),
      'P + R': (48.0, 12.0),
    };
    for (final entry in cases.entries) {
      final r = ElectricalCalculations.solve(
        entry.key,
        entry.value.$1,
        entry.value.$2,
      );
      expect(r.voltage, closeTo(24, 1e-9));
      expect(r.current, closeTo(2, 1e-9));
      expect(r.resistance, closeTo(12, 1e-9));
      expect(r.power, closeTo(48, 1e-9));
    }
    expect(
      () => ElectricalCalculations.solve('U + R', 24, 0),
      throwsArgumentError,
    );
  });
  test(
    'Tank geometries cover empty, full, half and nonlinear horizontal fill',
    () {
      ({double filled, double total}) tank(String shape, double fill) =>
          ProcessCalculations.tank(
            shape,
            fill,
            height: 2,
            length: 3,
            width: 2,
            diameter: 2,
          );
      expect(tank('Quader', 1), (filled: 6.0, total: 12.0));
      expect(tank('Zylinder stehend', 1).filled, closeTo(math.pi, 1e-10));
      expect(tank('Zylinder liegend', 1).filled, closeTo(1.5 * math.pi, 1e-10));
      expect(tank('Zylinder liegend', .5).filled, closeTo(1.8425545479, 1e-9));
      expect(tank('Kugel', 1).filled, closeTo(2 * math.pi / 3, 1e-10));
      for (final shape in [
        'Quader',
        'Zylinder stehend',
        'Zylinder liegend',
        'Kugel',
      ]) {
        expect(tank(shape, 0).filled, closeTo(0, 1e-10));
        expect(tank(shape, 2).filled, closeTo(tank(shape, 2).total, 1e-10));
        expect(() => tank(shape, 2.01), throwsArgumentError);
        expect(() => tank(shape, -1), throwsArgumentError);
      }
    },
  );
}
