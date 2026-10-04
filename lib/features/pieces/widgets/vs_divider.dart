import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class VsDivider extends StatelessWidget {
  const VsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
      ),
      child: const Center(
        child: Text(
          'VS',
          style: TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
