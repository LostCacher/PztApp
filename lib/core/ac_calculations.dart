import 'dart:math' as math;

import 'process_calculations.dart' show positive, finiteResult;

enum AcSystem { singlePhase, threePhase }

enum AcConnection { star, delta }

typedef AcCircuitResult = ({
  double lineVoltage,
  double lineCurrent,
  double phaseVoltage,
  double phaseCurrent,
  double activePower,
  double apparentPower,
  double reactivePower,
  double impedance,
  double resistance,
  double reactance,
  double phaseAngle,
});

/// Sinusoidal AC, balanced loads for three-phase; powers are circuit totals.
/// Three-phase U/I are line-to-line voltage / line current; Z is per branch.
abstract final class AcCalculations {
  static AcCircuitResult solve(
    String pair,
    double a,
    double b, {
    AcSystem system = AcSystem.singlePhase,
    AcConnection connection = AcConnection.star,
    double powerFactor = 1,
    bool capacitive = false,
  }) {
    positive(a, 'Erster Eingabewert');
    positive(b, 'Zweiter Eingabewert');
    if (!powerFactor.isFinite || powerFactor < 0 || powerFactor > 1) {
      throw ArgumentError('cos φ muss zwischen 0 und 1 liegen.');
    }
    if (pair.startsWith('P +') && powerFactor == 0) {
      throw ArgumentError(
        'Bei Wirkleistung als Eingabe muss cos φ größer als 0 sein.',
      );
    }
    final threePhase = system == AcSystem.threePhase;
    final sqrt3 = math.sqrt(3);
    final powerMultiplier = threePhase ? sqrt3 : 1.0;
    final voltageMultiplier = threePhase && connection == AcConnection.star
        ? sqrt3
        : 1.0;
    final currentMultiplier = threePhase && connection == AcConnection.delta
        ? sqrt3
        : 1.0;
    double u, i;
    switch (pair) {
      case 'U + I':
        u = a;
        i = b;
      case 'U + Z':
        u = a;
        i = (a / voltageMultiplier) / b * currentMultiplier;
      case 'I + Z':
        i = a;
        u = (a / currentMultiplier) * b * voltageMultiplier;
      case 'P + U':
        u = b;
        i = a / (powerMultiplier * b * powerFactor);
      case 'P + I':
        i = b;
        u = a / (powerMultiplier * b * powerFactor);
      case 'P + Z':
        final phaseApparent = a / powerFactor / (threePhase ? 3 : 1);
        u = math.sqrt(phaseApparent * b) * voltageMultiplier;
        i = math.sqrt(phaseApparent / b) * currentMultiplier;
      case 'S + U':
        u = b;
        i = a / (powerMultiplier * b);
      case 'S + I':
        i = b;
        u = a / (powerMultiplier * b);
      default:
        throw ArgumentError('Unbekannte AC-Eingabekombination.');
    }
    final phaseU = u / voltageMultiplier, phaseI = i / currentMultiplier;
    final apparent = powerMultiplier * u * i;
    final sinPhi =
        math.sqrt(math.max(0, 1 - powerFactor * powerFactor)) *
        (capacitive ? -1 : 1);
    final impedance = phaseU / phaseI;
    return (
      lineVoltage: finiteResult(u),
      lineCurrent: finiteResult(i),
      phaseVoltage: finiteResult(phaseU),
      phaseCurrent: finiteResult(phaseI),
      activePower: finiteResult(apparent * powerFactor),
      apparentPower: finiteResult(apparent),
      reactivePower: finiteResult(apparent * sinPhi),
      impedance: finiteResult(impedance),
      resistance: finiteResult(impedance * powerFactor),
      reactance: finiteResult(impedance * sinPhi),
      phaseAngle: finiteResult(
        math.acos(powerFactor) * 180 / math.pi * (capacitive ? -1 : 1),
      ),
    );
  }
}
