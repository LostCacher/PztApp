import 'package:material_ui/material_ui.dart';

import '../core/tool_kind.dart';
import 'basic_tool_screen.dart';
import 'electrical/electrical_screen.dart';
import 'process/calibration_screen.dart';
import 'process/flow_screen.dart';
import 'process/level_screen.dart';
import 'process/plc_screen.dart';
import 'process/pressure_screen.dart';
import 'process/tank_screen.dart';
import 'temperature/thermocouple_screen.dart';
export '../core/tool_kind.dart';

class ToolScreen extends StatelessWidget {
  const ToolScreen({super.key, required this.kind, required this.title});
  final ToolKind kind;
  final String title;
  @override
  Widget build(BuildContext context) => switch (kind) {
    ToolKind.signal ||
    ToolKind.percent ||
    ToolKind.temperature ||
    ToolKind.motor ||
    ToolKind.torque => BasicToolScreen(
      kind: BasicToolKind.values.byName(kind.name),
      title: title,
    ),
    ToolKind.pressure => const PressureScreen(),
    ToolKind.calibration => const CalibrationScreen(),
    ToolKind.plc => const PlcScreen(),
    ToolKind.electrical => const ElectricalScreen(),
    ToolKind.level => const LevelScreen(),
    ToolKind.tank => const TankScreen(),
    ToolKind.flow => const FlowScreen(),
    ToolKind.thermocouple => const ThermocoupleScreen(),
  };
}
