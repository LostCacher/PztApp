import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../widgets/brand.dart';
import 'tool_screen.dart';
import 'tool_catalog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String category = 'Alle Tools';
  String query = '';
  ToolDefinition? lastUsed;
  late final SharedPreferencesAsync preferences;

  @override
  void initState() {
    super.initState();
    preferences = SharedPreferencesAsync();
    unawaited(restoreLastUsed());
  }

  Future<void> restoreLastUsed() async {
    try {
      final saved = await preferences.getString('last_used_tool');
      if (!mounted || lastUsed != null) return;
      for (final tool in tools) {
        if (tool.kind.name == saved) {
          setState(() => lastUsed = tool);
          return;
        }
      }
    } on Exception catch (error) {
      debugPrint('Letztes Werkzeug konnte nicht geladen werden: $error');
    }
  }

  Future<void> rememberTool(ToolDefinition tool) async {
    try {
      await preferences.setString('last_used_tool', tool.kind.name);
    } on Exception catch (error) {
      // The shortcut remains available in this session if storage is unavailable.
      debugPrint('Letztes Werkzeug konnte nicht gespeichert werden: $error');
    }
  }

  void openTool(ToolDefinition tool) {
    setState(() => lastUsed = tool);
    unawaited(rememberTool(tool));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ToolScreen(kind: tool.kind, title: tool.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = tools
        .where(
          (t) =>
              (category == 'Alle Tools' || t.category == category) &&
              '${t.title} ${t.subtitle} ${t.tags} ${t.category}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      bottomNavigationBar: const SafeArea(top: false, child: DeveloperCredit()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 600
                        ? 22
                        : 44,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const BrandMark(),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PztApp',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'DEIN TECHNIK-WERKZEUGKASTEN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1.6,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 46),
                      const Text(
                        'WENIGER RECHNEN. MEHR TECHNIK.',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dein nächster Wert.\nNur einen Tap entfernt.',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Praktische Rechner für Prozess- und Elektrotechnik.\nSchnell zur Hand, direkt zum Ergebnis.',
                        style: TextStyle(color: AppColors.muted, height: 1.6),
                      ),
                      const SizedBox(height: 28),
                      _RecentToolCard(
                        tool: lastUsed,
                        onTap: lastUsed == null
                            ? null
                            : () => openTool(lastUsed!),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Deine Werkzeuge',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${tools.length} TOOLS',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Werkzeug suchen …',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              [
                                    'Alle Tools',
                                    ...{
                                      for (final tool in tools) tool.category,
                                    },
                                  ]
                                  .map(
                                    (label) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(label),
                                        selected: category == label,
                                        onSelected: (_) =>
                                            setState(() => category = label),
                                        showCheckmark: false,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'Kein Werkzeug gefunden. Versuche einen anderen Suchbegriff.',
                          ),
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: visible
                              .map(
                                (tool) => SizedBox(
                                  width: constraints.maxWidth >= 650
                                      ? (constraints.maxWidth - 16) / 2
                                      : constraints.maxWidth,
                                  child: _ToolCard(
                                    tool: tool,
                                    onTap: () => openTool(tool),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.offline_bolt_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Alle Berechnungen direkt auf deinem Gerät',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentToolCard extends StatelessWidget {
  const _RecentToolCard({required this.tool, required this.onTap});
  final ToolDefinition? tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('recent-tool'),
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF28203F), Color(0xFF211A2B)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF463257)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                tool?.icon ?? Icons.history_rounded,
                color: AppColors.purple,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zuletzt verwendet',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tool?.title ?? 'Noch kein Werkzeug geöffnet',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool?.category ?? 'Wähle unten dein erstes Werkzeug.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (tool != null) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.purple,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onTap});
  final ToolDefinition tool;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 26),
                ),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              tool.category.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: tool.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              tool.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              tool.subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 15),
            Text(
              tool.tags,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
