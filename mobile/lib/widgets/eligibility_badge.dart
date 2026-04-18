import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EligibilityBadge extends StatelessWidget {
  final bool isEligible;
  final bool large;
  const EligibilityBadge({super.key, required this.isEligible, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = isEligible ? AppTheme.eligible : AppTheme.suspended;
    final label = isEligible ? 'Eligible' : 'Suspended';
    final icon = isEligible ? Icons.check_circle_rounded : Icons.pause_circle_rounded;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 16 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 18 : 14),
          SizedBox(width: large ? 6 : 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: color, fontSize: large ? 14 : 12)),
        ],
      ),
    );
  }
}
