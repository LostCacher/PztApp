import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';
import '../core/calculations.dart';
import 'brand.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    bottomNavigationBar: const SafeArea(top: false, child: DeveloperCredit()),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WERKZEUG',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Werte eingeben. Ergebnis direkt ablesen.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

abstract class CalculatorState<T extends StatefulWidget> extends State<T> {
  final fields = <String, TextEditingController>{};
  void setup(Map<String, String> defaults) {
    for (final entry in defaults.entries) {
      fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  double number(String key) {
    final value = parseNumber(fields[key]!.text);
    if (value == null) throw ArgumentError('Bitte gültige Zahlen eingeben.');
    return value;
  }

  Widget input(String key, String label, String unit, {bool text = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextField(
          key: ValueKey('input-$key'),
          controller: fields[key],
          onChanged: (_) => setState(() {}),
          keyboardType: text
              ? TextInputType.text
              : const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
          decoration: InputDecoration(
            labelText: label,
            suffixText: unit.isEmpty ? null : unit,
          ),
        ),
      );
  Widget menu<V>(
    String label,
    V value,
    List<V> items,
    ValueChanged<V> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<V>(
      key: ValueKey('select-$label'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text('$item', overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) setState(() => change(next));
      },
    ),
  );
  Widget result(Widget Function() builder) {
    try {
      return builder();
    } on ArgumentError catch (e) {
      return ResultCard(
        title: 'EINGABE PRÜFEN',
        value: '${e.message}',
        error: true,
      );
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    this.title = 'ERGEBNIS',
    required this.value,
    this.unit = '',
    this.lines = const [],
    this.error = false,
  });
  final String title, value, unit;
  final List<String> lines;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF2E2145), Color(0xFF251B31)],
      ),
      border: Border.all(
        color: error ? AppColors.pink : const Color(0xFF60427E),
      ),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: error ? AppColors.pink : AppColors.purple,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            unit.isEmpty ? value : '$value $unit',
            style: TextStyle(
              fontSize: error ? 15 : 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectableText(
                line,
                style: const TextStyle(
                  color: Color(0xFFCEC0DE),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ToolNote extends StatelessWidget {
  const ToolNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
    ),
  );
}
