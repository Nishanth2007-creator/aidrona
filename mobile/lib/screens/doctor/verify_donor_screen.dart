import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class VerifyDonorScreen extends StatefulWidget {
  final String donorId;
  final String crisisId;
  const VerifyDonorScreen({super.key, required this.donorId, required this.crisisId});

  @override
  State<VerifyDonorScreen> createState() => _VerifyDonorScreenState();
}

class _VerifyDonorScreenState extends State<VerifyDonorScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _submitting = false;
  String? _reason;

  final List<String> _unfitReasons = ['Low hemoglobin', 'High blood pressure', 'Recent illness', 'Disqualifying medication', 'Other'];
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) context.go('/role-select');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<ApiService>().getDonorProfile(widget.donorId);
      setState(() { _profile = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _verdict(String verdict) async {
    if (verdict == 'unfit' && _reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason before marking unfit')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(verdict == 'fit' ? 'Confirm Donor Fit' : 'Confirm Donor Unfit'),
        content: Text(verdict == 'unfit'
          ? 'This will re-trigger donor search and penalise this donor\'s fitness score.'
          : 'This will confirm the donation and notify the requester.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: verdict == 'fit' ? AppTheme.teal : AppTheme.danger),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final apiService = context.read<ApiService>();
    setState(() => _submitting = true);
    try {
      await apiService.verifyDonor({
        'donor_id': widget.donorId,
        'crisis_id': widget.crisisId,
        'doctor_verdict': verdict,
        'reason': _reason ?? '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(verdict == 'fit' ? '✓ Donor verified as fit' : '✗ Donor marked unfit — search re-triggered'),
        backgroundColor: verdict == 'fit' ? AppTheme.teal : AppTheme.danger,
      ));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));

    final score = _profile?['fitness_score'] ?? 0;
    final isEligible = _profile?['is_eligible'] == true;
    final donationCount = _profile?['donation_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Donor'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard, 
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Donor Profile', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurfaceMuted, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Fitness Score', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
                    const Spacer(),
                    Text('$score / 100', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 22, color: (double.tryParse(score.toString()) ?? 0) >= 60 ? AppTheme.teal : AppTheme.amber)),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (double.tryParse(score.toString()) ?? 0) / 100, 
                    backgroundColor: AppTheme.surfaceElevated, 
                    color: (double.tryParse(score.toString()) ?? 0) >= 60 ? AppTheme.teal : AppTheme.amber, 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Eligible', isEligible ? 'Yes ✓' : 'No ✗'),
                  _infoRow('Donations', '$donationCount'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select reason if marking unfit:', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _unfitReasons.map((r) {
                final sel = r == _reason;
                return GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.danger.withValues(alpha: 0.15) : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.danger : Colors.transparent),
                    ),
                    child: Text(r, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: sel ? AppTheme.danger : AppTheme.onSurfaceMuted)),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _verdict('unfit'),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Mark Unfit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
                const SizedBox(width: 14),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _verdict('fit'),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark Fit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 13)),
      ]),
    );
  }
}
