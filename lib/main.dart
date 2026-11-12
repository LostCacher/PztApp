import 'package:material_ui/material_ui.dart';

import 'core/app_theme.dart';
import 'features/home_screen.dart';

void main() => runApp(const PztApp());

class PztApp extends StatelessWidget {
  const PztApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PztApp',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    themeMode: ThemeMode.dark,
    home: const HomeScreen(),
  );
}
