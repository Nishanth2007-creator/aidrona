import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RequestCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const RequestCard({super.key, required this.data});

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.data['status']) {
      case 'fulfilled':
        return AppTheme.eligible;
      case 'escalated_to_bank':
        return AppTheme.amber;
      case 'open':
        return AppTheme.primary;
      case 'closed_no_donor':
        return AppTheme.danger;
      default:
        return AppTheme.onSurfaceMuted;
    }
  }

  String get _statusLabel {
    switch (widget.data['status']) {
      case 'fulfilled':
        return 'Fulfilled';
      case 'escalated_to_bank':
        return 'Escalated';
      case 'open':
        return 'Open';
      case 'closed_no_donor':
        return 'No Donor Found';
      default:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(widget.data['blood_type'] ?? '?', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppTheme.danger, fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.data['blood_type']} Request', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 14)),
                    Text(widget.data['created_at'] ?? '', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 12)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _statusColor, fontSize: 12)),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 20, color: Color(0xFF2A2745)),
              _timelineStep('Request created', true),
              _timelineStep('Donors notified', true),
              _timelineStep('Donor confirmed', widget.data['status'] == 'fulfilled'),
              _timelineStep('Doctor verified', false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? AppTheme.teal : AppTheme.onSurfaceMuted, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: done ? AppTheme.onSurface : AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}
