import 'package:flutter/material.dart';

class PrincipleCard extends StatelessWidget {
  final String principleText;
  final VoidCallback onDismiss;

  const PrincipleCard({
    super.key,
    required this.principleText,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB300),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFFFB300),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Opening Tip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  principleText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onDismiss,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
