import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pzt_app/core/thermocouples.dart';

void main() {
  test(
    'All eight NIST curves agree with independent published table samples',
    () {
      final data = jsonDecode(
        File('test/fixtures/nist_reference_points.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final row in data['points'] as List) {
        expect(
          Thermocouples.emf(
            row['type'] as String,
            (row['temperature'] as num).toDouble(),
          ),
          closeTo((row['millivolts'] as num).toDouble(), .000501),
          reason: '${row['type']} at ${row['temperature']} °C',
        );
      }
    },
  );
  test(
    'A and C reference endpoints agree with BIPM published inverse ranges',
    () {
      expect(Thermocouples.emf('A', 100), closeTo(1.337, .001));
      expect(Thermocouples.emf('A', 2480), closeTo(33.485, .001));
      expect(Thermocouples.emf('C', 2315), closeTo(37.070, .001));
    },
  );
  test('All ten types round trip across segments with comparison junction compensation', () {
    expect(Thermocouples.types.toSet(), {
      'A',
      'B',
      'C',
      'E',
      'J',
      'K',
      'N',
      'R',
      'S',
      'T',
    });
    for (final type in Thermocouples.types) {
      final min = Thermocouples.inverseMin(type),
          max = Thermocouples.maxTemperature(type);
      for (var i = 0; i <= 100; i++) {
        final hot = min + (max - min) * i / 100;
        final mv = Thermocouples.millivolts(type, hot, reference: 25);
        expect(
          Thermocouples.temperature(type, mv, reference: 25),
          closeTo(hot, .0005),
          reason: '$type at $hot',
        );
      }
      expect(Thermocouples.millivolts(type, 25, reference: 25), 0);
      expect(() => Thermocouples.emf(type, max + 1), throwsArgumentError);
      expect(() => Thermocouples.temperature(type, 1000), throwsArgumentError);
    }
    expect(
      Thermocouples.temperature(
        'K',
        Thermocouples.millivolts('K', -100, reference: 25),
        reference: 25,
      ),
      closeTo(-100, 1e-6),
    );
    expect(() => Thermocouples.temperature('B', 0), throwsArgumentError);
    expect(
      () => Thermocouples.millivolts('B', 500, reference: -1),
      throwsArgumentError,
    );
  });
}
