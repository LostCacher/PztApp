import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/calculations.dart';

void main() {
  test('Signal endpoints, midpoint, reverse and extrapolation', () {
    expect(Calculations.scale(4, 4, 20, 0, 100), 0);
    expect(Calculations.scale(12, 4, 20, 0, 100), 50);
    expect(Calculations.scale(20, 4, 20, 0, 100), 100);
    expect(Calculations.scale(50, 0, 100, 4, 20), 12);
    expect(Calculations.scale(5, 0, 10, -50, 150), 50);
    expect(Calculations.scale(10, 0, 20, 100, 0), 50);
    expect(Calculations.scale(0, 4, 20, 0, 100), -25);
    expect(() => Calculations.scale(1, 0, 0, 0, 100), throwsArgumentError);
  });
  test('Pt100 reference points and inverse across both branches', () {
    expect(Calculations.resistance(0, 100), 100);
    expect(Calculations.resistance(100, 100), closeTo(138.5055, 0.0001));
    expect(Calculations.resistance(-200, 100), closeTo(18.52008, 0.0001));
    for (final r0 in [100.0, 1000.0]) {
      for (final t in [-200.0, -100.0, 0.0, 100.0, 850.0]) {
        expect(
          Calculations.temperature(Calculations.resistance(t, r0), r0),
          closeTo(t, 1e-8),
        );
      }
    }
    expect(() => Calculations.resistance(851, 100), throwsArgumentError);
    expect(() => Calculations.temperature(0, 100), throwsArgumentError);
  });
  test('Motor and German numeric input', () {
    expect(Calculations.synchronousRpm(50, 4), 1500);
    expect(Calculations.synchronousRpm(50, 2), 3000);
    expect(parseNumber(' 12,5 '), 12.5);
    expect(parseNumber('NaN'), isNull);
    expect(parseNumber('Infinity'), isNull);
    expect(formatNumber(100), '100');
    expect(formatNumber(0), '0');
    expect(formatNumber(12.50), '12,5');
    expect(formatNumber(1e30), '1,000e+30');
  });
  test(
    'Slip changes both conversion directions and validates motor operation',
    () {
      expect(Calculations.motorRpm(50, 4), 1500);
      expect(Calculations.motorRpm(50, 4, slipPercent: 3), 1455);
      expect(
        Calculations.motorFrequency(1455, 4, slipPercent: 3),
        closeTo(50, 1e-10),
      );
      expect(Calculations.motorRpm(0, 4, slipPercent: 3), 0);
      for (final slip in [-1.0, 100.0, double.nan]) {
        expect(
          () => Calculations.motorRpm(50, 4, slipPercent: slip),
          throwsArgumentError,
        );
        expect(
          () => Calculations.motorFrequency(1500, 4, slipPercent: slip),
          throwsArgumentError,
        );
      }
      expect(() => Calculations.motorRpm(-1, 4), throwsArgumentError);
    },
  );
  test('Torque uses shaft power and rejects standstill', () {
    expect(Calculations.torque(7.5, 1450), closeTo(49.392914, 1e-6));
    expect(Calculations.torque(0, 1450), 0);
    expect(() => Calculations.torque(7.5, 0), throwsArgumentError);
    expect(() => Calculations.torque(-1, 1450), throwsArgumentError);
  });
  test('Electrical power distinguishes DC, single phase and three phase', () {
    expect(
      Calculations.electricalPowerKw(
        400,
        15,
        MotorSupply.threePhase,
        powerFactor: .85,
      ),
      closeTo(8.8334591186, 1e-9),
    );
    expect(
      Calculations.electricalPowerKw(
        230,
        10,
        MotorSupply.singlePhase,
        powerFactor: .8,
      ),
      closeTo(1.84, 1e-10),
    );
    expect(Calculations.electricalPowerKw(24, 10, MotorSupply.dc), .24);
    expect(Calculations.shaftPowerKw(10, 90), 9);
    for (final efficiency in [0.0, -1.0, 101.0]) {
      expect(
        () => Calculations.shaftPowerKw(10, efficiency),
        throwsArgumentError,
      );
    }
    expect(
      () => Calculations.electricalPowerKw(
        400,
        15,
        MotorSupply.threePhase,
        powerFactor: 1.1,
      ),
      throwsArgumentError,
    );
    expect(
      () => Calculations.electricalPowerKw(400, -1, MotorSupply.threePhase),
      throwsArgumentError,
    );
  });
}
