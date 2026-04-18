import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FitnessRing extends StatelessWidget {
  final double score;
  const FitnessRing({super.key, required this.score});

  Color get _ringColor {
    if (score >= 70) return AppTheme.eligible;
    if (score >= 40) return AppTheme.suspended;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 7,
            backgroundColor: AppTheme.surfaceElevated,
            color: _ringColor,
            strokeCap: StrokeCap.round,
          ),
          Text(score.toStringAsFixed(0), style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20, color: _ringColor)),
        ],
      ),
    );
  }
}
