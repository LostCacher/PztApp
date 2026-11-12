import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';
import '../core/tool_kind.dart';

class ToolDefinition {
  const ToolDefinition(
    this.title,
    this.subtitle,
    this.category,
    this.icon,
    this.color,
    this.kind,
    this.tags,
  );
  final String title, subtitle, category, tags;
  final IconData icon;
  final Color color;
  final ToolKind kind;
}

const tools = [
  ToolDefinition(
    'Signal-Converter',
    'Messsignale in Prozesswerte umrechnen. Und zurück.',
    'Prozesssignale',
    Icons.insights_rounded,
    AppColors.purple,
    ToolKind.signal,
    '0–20 mA   /   4–20 mA   /   0–10 V',
  ),
  ToolDefinition(
    'Prozentrechner',
    'Grundwert, Prozentwert und Prozentsatz berechnen.',
    'Grundlagen',
    Icons.percent_rounded,
    AppColors.pink,
    ToolKind.percent,
    'GRUNDWERT   /   ANTEIL   /   PROZENT',
  ),
  ToolDefinition(
    'Pt100 / Pt1000',
    'Temperatur und Widerstand präzise umrechnen.',
    'Temperatur',
    Icons.thermostat_rounded,
    Color(0xFFFFB86C),
    ToolKind.temperature,
    'PT100   /   PT1000',
  ),
  ToolDefinition(
    'Drehzahl & Frequenz',
    'Drehzahl aus Frequenz, Polzahl und optionalem Schlupf.',
    'Antriebstechnik',
    Icons.settings_input_component_rounded,
    Color(0xFF65D9CC),
    ToolKind.motor,
    'HZ   /   U/MIN   /   SCHLUPF',
  ),
  ToolDefinition(
    'Drehmoment & Leistung',
    'Motordrehmoment aus Leistung oder elektrischen Daten.',
    'Antriebstechnik',
    Icons.rotate_right_rounded,
    Color(0xFF65D9CC),
    ToolKind.torque,
    'NM   /   KW   /   MOTORDATEN',
  ),
  ToolDefinition(
    'Druckeinheiten',
    'Druckwerte in elf Einheiten umrechnen.',
    'Druck & Füllstand',
    Icons.speed_rounded,
    Color(0xFF80BBFF),
    ToolKind.pressure,
    'BAR   /   PA   /   PSI   /   MWS',
  ),
  ToolDefinition(
    '5-Punkt-Kalibrierhelfer',
    'Sollwerte, Messabweichung und Toleranz im Blick.',
    'Prozesssignale',
    Icons.fact_check_outlined,
    AppColors.purple,
    ToolKind.calibration,
    'PRÜFPUNKTE   /   SOLL–IST',
  ),
  ToolDefinition(
    'SPS-Rohwertskalierung',
    'Analog-Rohwerte in technische Einheiten übersetzen.',
    'Automatisierung',
    Icons.memory_rounded,
    Color(0xFF65D9CC),
    ToolKind.plc,
    'ROHWERT   /   SKALIERUNG',
  ),
  ToolDefinition(
    'Elektrische Grundlagen',
    'DC, Wechselstrom und Drehstrom mit Leistungsfaktor.',
    'Elektrotechnik',
    Icons.electrical_services_rounded,
    AppColors.pink,
    ToolKind.electrical,
    'DC   /   1~   /   3~   /   P–Q–S',
  ),
  ToolDefinition(
    'Hydrostatischer Füllstand',
    'Füllhöhe aus Druck und Mediendichte berechnen.',
    'Druck & Füllstand',
    Icons.water_rounded,
    Color(0xFF80BBFF),
    ToolKind.level,
    'DRUCK   /   DICHTE   /   HÖHE',
  ),
  ToolDefinition(
    'Tankvolumen',
    'Füllinhalt für Quader, Zylinder und Kugel.',
    'Druck & Füllstand',
    Icons.storage_rounded,
    Color(0xFF80BBFF),
    ToolKind.tank,
    'M³   /   LITER   /   FÜLLGRAD',
  ),
  ToolDefinition(
    'Differenzdruck & Durchfluss',
    'Wirkdruck mit Wurzelkennlinie in Durchfluss umrechnen.',
    'Prozesssignale',
    Icons.waves_rounded,
    AppColors.purple,
    ToolKind.flow,
    'ΔP   /   DURCHFLUSS   /   √',
  ),
  ToolDefinition(
    'Thermoelemente',
    'Thermospannung und Temperatur mit Vergleichsstelle.',
    'Temperatur',
    Icons.device_thermostat_rounded,
    Color(0xFFFFB86C),
    ToolKind.thermocouple,
    'A   /   B   /   C   /   E   /   J   /   K   /   N   /   R   /   S   /   T',
  ),
];
