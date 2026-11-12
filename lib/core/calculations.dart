/// Pure calculations, independent of the interface.
library;

import 'dart:math' as math;

enum MotorSupply { dc, singlePhase, threePhase }

abstract final class Calculations {
  static double scale(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (inMin == inMax || outMin == outMax) {
      throw ArgumentError('Die Bereichsgrenzen müssen unterschiedlich sein.');
    }
    return outMin + (value - inMin) / (inMax - inMin) * (outMax - outMin);
  }

  // IEC 60751 platinum characteristic, alpha = 0.00385.
  // Reference: Analog Devices, RTD Measurement System Design Essentials.
  static double resistance(double temperature, double r0) {
    if (temperature < -200 || temperature > 850) {
      throw ArgumentError('Temperatur muss zwischen −200 und 850 °C liegen.');
    }
    return r0 *
        (1 +
            3.9083e-3 * temperature -
            5.775e-7 * temperature * temperature +
            (temperature < 0
                ? -4.183e-12 *
                      (temperature - 100) *
                      temperature *
                      temperature *
                      temperature
                : 0));
  }

  static double temperature(double ohms, double r0) {
    if (ohms < resistance(-200, r0) || ohms > resistance(850, r0)) {
      throw ArgumentError(
        'Widerstand liegt außerhalb der Kennlinie (−200 … 850 °C).',
      );
    }
    var low = -200.0;
    var high = 850.0;
    for (var i = 0; i < 60; i++) {
      final mid = (low + high) / 2;
      if (resistance(mid, r0) < ohms) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  static double synchronousRpm(double hz, int poles) => 120 * hz / poles;

  static void _validateMotor(double value, int poles, double slipPercent) {
    if (!value.isFinite || value < 0 || poles < 2 || poles.isOdd) {
      throw ArgumentError(
        'Drehzahl/Frequenz muss ≥ 0 und die Polzahl gerade sein.',
      );
    }
    if (!slipPercent.isFinite || slipPercent < 0 || slipPercent >= 100) {
      throw ArgumentError(
        'Schlupf muss zwischen 0 und kleiner als 100 % liegen.',
      );
    }
  }

  static double motorRpm(double hz, int poles, {double slipPercent = 0}) {
    _validateMotor(hz, poles, slipPercent);
    return synchronousRpm(hz, poles) * (1 - slipPercent / 100);
  }

  static double motorFrequency(
    double rpm,
    int poles, {
    double slipPercent = 0,
  }) {
    _validateMotor(rpm, poles, slipPercent);
    return rpm * poles / (120 * (1 - slipPercent / 100));
  }

  /// Shaft torque from mechanical output power, never apparent/input power.
  static double torque(double shaftPowerKw, double rpm) {
    if (!shaftPowerKw.isFinite || shaftPowerKw < 0) {
      throw ArgumentError('Die Wellenleistung muss größer oder gleich 0 sein.');
    }
    if (!rpm.isFinite || rpm <= 0) {
      throw ArgumentError('Die Drehzahl muss größer als 0 U/min sein.');
    }
    return shaftPowerKw * 60000 / (2 * math.pi * rpm);
  }

  /// AC: RMS voltage/current; 3-phase: line-to-line voltage and line current.
  static double electricalPowerKw(
    double voltage,
    double current,
    MotorSupply supply, {
    double powerFactor = 1,
  }) {
    if (!voltage.isFinite || voltage <= 0 || !current.isFinite || current < 0) {
      throw ArgumentError('Spannung muss > 0 und Strom muss ≥ 0 sein.');
    }
    if (supply != MotorSupply.dc &&
        (!powerFactor.isFinite || powerFactor <= 0 || powerFactor > 1)) {
      throw ArgumentError('cos φ muss größer als 0 und höchstens 1 sein.');
    }
    return voltage *
        current /
        1000 *
        (supply == MotorSupply.threePhase ? math.sqrt(3) : 1) *
        (supply == MotorSupply.dc ? 1 : powerFactor);
  }

  static double shaftPowerKw(double inputPowerKw, double efficiencyPercent) {
    if (!efficiencyPercent.isFinite ||
        efficiencyPercent <= 0 ||
        efficiencyPercent > 100) {
      throw ArgumentError(
        'Wirkungsgrad muss größer als 0 und höchstens 100 % sein.',
      );
    }
    if (!inputPowerKw.isFinite || inputPowerKw < 0) {
      throw ArgumentError(
        'Die Aufnahmeleistung muss größer oder gleich 0 sein.',
      );
    }
    return inputPowerKw * efficiencyPercent / 100;
  }
}

double? parseNumber(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

String formatNumber(double value) {
  if (!value.isFinite) return '—';
  if (value.abs() >= 1e12) {
    return value.toStringAsExponential(3).replaceAll('.', ',');
  }
  return (value.abs() < 0.0000005 ? 0.0 : value)
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
}
