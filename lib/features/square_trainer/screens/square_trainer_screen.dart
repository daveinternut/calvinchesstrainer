import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SquareTrainerScreen extends StatelessWidget {
  const SquareTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.squareTrainer)),
      body: Center(
        child: Text(l10n.squareComingSoon),
      ),
    );
  }
}
