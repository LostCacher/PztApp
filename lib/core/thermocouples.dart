import 'dart:math' as math;

import 'thermocouple_data.dart';

abstract final class Thermocouples {
  static const types = ['A', 'B', 'C', 'E', 'J', 'K', 'N', 'R', 'S', 'T'];
  static List<ThermocoupleSegment> _segments(String type) {
    final segments = thermocoupleCurves[type];
    if (segments == null) throw ArgumentError('Unbekannter Thermoelementtyp.');
    return segments;
  }

  static double minTemperature(String type) => _segments(type).first.min;
  static double maxTemperature(String type) => _segments(type).last.max;
  static double inverseMin(String type) =>
      type == 'B' ? 250 : minTemperature(type);

  /// Reference EMF in mV, junction at 0 °C; Horner evaluation of NIST ITS-90.
  static double emf(String type, double temperature) {
    final segments = _segments(type);
    if (!temperature.isFinite ||
        temperature < segments.first.min ||
        temperature > segments.last.max) {
      throw ArgumentError(
        'Typ $type: Temperatur muss zwischen ${segments.first.min} und ${segments.last.max} °C liegen.',
      );
    }
    if (temperature == 0) return 0;
    final s = segments.firstWhere(
      (s) => temperature >= s.min && temperature <= s.max,
    );
    var value = 0.0;
    for (final c in s.c.reversed) {
      value = value * temperature + c;
    }
    if (s.a.isNotEmpty) {
      value += s.a[0] * math.exp(s.a[1] * math.pow(temperature - s.a[2], 2));
    }
    return value;
  }

  static double millivolts(String type, double hot, {double reference = 0}) =>
      emf(type, hot) - emf(type, reference);

  /// B is intentionally restricted to the monotonic standard inverse range.
  static double temperature(
    String type,
    double measuredMv, {
    double reference = 0,
  }) {
    if (!measuredMv.isFinite) {
      throw ArgumentError('Bitte eine gültige Spannung eingeben.');
    }
    final target = measuredMv + emf(type, reference);
    var low = inverseMin(type), high = maxTemperature(type);
    final minEmf = emf(type, low), maxEmf = emf(type, high);
    if (target < minEmf - 1e-10 || target > maxEmf + 1e-10) {
      throw ArgumentError(
        'Spannung außerhalb der Rückrechnung für Typ $type (${inverseMin(type)} … ${maxTemperature(type)} °C, inklusive Vergleichsstelle).',
      );
    }
    for (var i = 0; i < 70; i++) {
      final mid = (low + high) / 2;
      if (emf(type, mid) < target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }
}
