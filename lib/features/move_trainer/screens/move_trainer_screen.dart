import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MoveTrainerScreen extends StatelessWidget {
  const MoveTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moveTrainer)),
      body: Center(
        child: Text(l10n.moveComingSoon),
      ),
    );
  }
}
