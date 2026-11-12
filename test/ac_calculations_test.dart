import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/ac_calculations.dart';

void main() {
  test('Single-phase circuit resolves P/Q/S and complex impedance', () {
    final r = AcCalculations.solve('U + I', 230, 5, powerFactor: .8);
    expect(r.activePower, closeTo(920, 1e-10));
    expect(r.apparentPower, closeTo(1150, 1e-10));
    expect(r.reactivePower, closeTo(690, 1e-10));
    expect(r.impedance, closeTo(46, 1e-10));
    expect(r.resistance, closeTo(36.8, 1e-10));
    expect(r.reactance, closeTo(27.6, 1e-10));
    expect(r.phaseAngle, closeTo(36.869897646, 1e-8));
  });
  test(
    'Star/delta share line power while branch voltage/current and Z differ',
    () {
      final star = AcCalculations.solve(
        'U + I',
        400,
        10,
        system: AcSystem.threePhase,
        powerFactor: .8,
      );
      final delta = AcCalculations.solve(
        'U + I',
        400,
        10,
        system: AcSystem.threePhase,
        connection: AcConnection.delta,
        powerFactor: .8,
      );
      expect(star.activePower, closeTo(5542.5625842204, 1e-8));
      expect(star.apparentPower, closeTo(6928.2032302755, 1e-8));
      expect(star.reactivePower, closeTo(4156.9219381653, 1e-8));
      expect(star.phaseVoltage, closeTo(230.9401076759, 1e-8));
      expect(star.phaseCurrent, 10);
      expect(delta.activePower, closeTo(star.activePower, 1e-8));
      expect(delta.phaseVoltage, 400);
      expect(delta.phaseCurrent, closeTo(5.7735026919, 1e-8));
      expect(delta.impedance, closeTo(star.impedance * 3, 1e-8));
    },
  );
  test('Every AC input pair reconstructs the line circuit for 1-phase, star and delta', () {
    for (final config in [
      (AcSystem.singlePhase, AcConnection.star),
      (AcSystem.threePhase, AcConnection.star),
      (AcSystem.threePhase, AcConnection.delta),
    ]) {
      final three = config.$1 == AcSystem.threePhase;
      final impedance = !three
          ? 40.0
          : config.$2 == AcConnection.star
          ? 40 / math.sqrt(3)
          : 40 * math.sqrt(3);
      final apparent = (three ? math.sqrt(3) : 1.0) * 4000;
      final active = apparent * .8;
      final pairs = {
        'U + I': (400.0, 10.0),
        'U + Z': (400.0, impedance),
        'I + Z': (10.0, impedance),
        'P + U': (active, 400.0),
        'P + I': (active, 10.0),
        'P + Z': (active, impedance),
        'S + U': (apparent, 400.0),
        'S + I': (apparent, 10.0),
      };
      for (final p in pairs.entries) {
        final r = AcCalculations.solve(
          p.key,
          p.value.$1,
          p.value.$2,
          system: config.$1,
          connection: config.$2,
          powerFactor: .8,
        );
        expect(
          r.lineVoltage,
          closeTo(400, 1e-9),
          reason: '${config.$1} ${config.$2} ${p.key}',
        );
        expect(r.lineCurrent, closeTo(10, 1e-9));
        expect(r.activePower, closeTo(active, 1e-8));
        expect(r.impedance, closeTo(impedance, 1e-9));
      }
    }
  });
  test('Reactive sign follows load character; unity and zero power factor are defined', () {
    final r = AcCalculations.solve(
      'U + I',
      230,
      5,
      powerFactor: .8,
      capacitive: true,
    );
    expect(r.reactivePower, closeTo(-690, 1e-10));
    expect(r.reactance, closeTo(-27.6, 1e-10));
    expect(r.phaseAngle, closeTo(-36.869897646, 1e-8));
    final ohmic = AcCalculations.solve('U + I', 230, 5);
    expect(ohmic.reactivePower, 0);
    expect(ohmic.reactance, 0);
    expect(ohmic.phaseAngle, 0);
    final reactive = AcCalculations.solve('S + U', 1150, 230, powerFactor: 0);
    expect(reactive.activePower, 0);
    expect(reactive.reactivePower, 1150);
    expect(reactive.resistance, 0);
    expect(
      () => AcCalculations.solve('P + U', 920, 230, powerFactor: 0),
      throwsArgumentError,
    );
  });
  test(
    'Invalid factors, zero denominators and nonfinite results are rejected',
    () {
      for (final pf in [-.1, 1.1, double.nan, double.infinity]) {
        expect(
          () => AcCalculations.solve('U + I', 230, 5, powerFactor: pf),
          throwsArgumentError,
        );
      }
      expect(() => AcCalculations.solve('U + Z', 230, 0), throwsArgumentError);
      expect(() => AcCalculations.solve('U + I', -230, 5), throwsArgumentError);
      expect(
        () => AcCalculations.solve('U + I', 1e300, 1e300),
        throwsArgumentError,
      );
    },
  );
}
