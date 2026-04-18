import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = context.read<AuthService>().uid!;
      final data = await context.read<ApiService>().getMedicalHistory(uid);
      setState(() { _history = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _history.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _HistoryCard(entry: _history[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medical_information_outlined, size: 60, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          const Text('No medical records yet', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Visit a doctor and scan your QR code to add a record', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  const _HistoryCard({required this.entry});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final eligibilityChanged = e['eligibility_changed'] == true;
    final scoreBefore = e['fitness_score_before'] ?? 0;
    final scoreAfter = e['fitness_score_after'] ?? 0;
    final delta = (scoreAfter - scoreBefore).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: eligibilityChanged ? AppTheme.primary.withOpacity(0.5) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_hospital_outlined, color: AppTheme.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['hospital'] ?? 'Hospital', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 14)),
                      Text(e['doctor_reg_id'] ?? 'Dr. —', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Score: $scoreAfter', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 13)),
                    Text('${double.tryParse(delta)! >= 0 ? '+' : ''}$delta', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: double.tryParse(delta)! >= 0 ? AppTheme.eligible : AppTheme.danger)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppTheme.onSurfaceMuted),
              ],
            ),
            if (eligibilityChanged) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('⚡ Eligibility status changed', style: TextStyle(fontFamily: 'Inter', color: AppTheme.primary, fontSize: 12)),
              ),
            ],
            if (_expanded) ...[
              const Divider(height: 20, color: Color(0xFF2A2745)),
              _detail('Diagnosis', e['diagnosis'] ?? '—'),
              _detail('Hemoglobin', '${e['hemoglobin'] ?? '—'} g/dL'),
              _detail('Blood Pressure', e['blood_pressure'] ?? '—'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
