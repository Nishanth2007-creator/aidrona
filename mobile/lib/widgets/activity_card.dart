import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityCard extends StatelessWidget {
  final String type, status, time;
  const ActivityCard({super.key, required this.type, required this.status, required this.time});

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'fulfilled': return AppTheme.eligible;
      case 'escalated_to_bank': return AppTheme.amber;
      case 'open': return AppTheme.primary;
      default: return AppTheme.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bloodtype_outlined, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppTheme.onSurface, fontSize: 13)),
            Text(time, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _statusColor, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
