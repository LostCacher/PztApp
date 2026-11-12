import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/pzt-logo.png',
    width: size,
    height: size,
    semanticLabel: 'PZT Signalimpuls Logo',
  );
}

class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Text(
      '@by LostCacher',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 1),
    ),
  );
}
