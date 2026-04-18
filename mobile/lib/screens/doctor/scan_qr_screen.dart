import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  Map<String, dynamic>? _patient;
  bool _loading = false;
  final _manualCtrl = TextEditingController();

  Future<void> _fetchPatient(String uid) async {
    setState(() { _loading = true; _scanned = true; });
    try {
      final data = await context.read<ApiService>().getPatientSummary(uid);
      setState(() { _patient = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Patient QR'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
      ),
      body: _scanned ? _buildPatientView() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  if (_scanned) return;
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) {
                    // Parse aidrona://user/{uid}
                    final uri = Uri.tryParse(code);
                    final uid = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : code;
                    _fetchPatient(uid);
                  }
                },
              ),
              // Scan frame overlay
              Center(
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.primary, width: 3), borderRadius: BorderRadius.circular(16)),
                ),
              ),
              Positioned(bottom: 20, left: 0, right: 0, child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.surfaceCard.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Point camera at patient QR code', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 13)),
                ),
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _manualCtrl, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface), decoration: const InputDecoration(hintText: 'Enter patient phone / UID manually'))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () => _fetchPatient(_manualCtrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal), child: const Text('Go')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientView() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    final user = _patient?['user'] as Map? ?? {};
    final donor = _patient?['donor_profile'] as Map? ?? {};
    final medical = _patient?['medical_record'] as Map? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Center(child: Text((user['name'] ?? 'U').toString()[0].toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white)))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user['name'] ?? '—', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.onSurface)),
                  Text('Blood: ${user['blood_type'] ?? '—'}  |  Score: ${donor['fitness_score'] ?? 0}', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoTile('Hemoglobin', '${medical['hemoglobin'] ?? '—'} g/dL'),
          _infoTile('Eligible', donor['is_eligible'] == true ? 'Yes ✓' : 'No ✗'),
          const SizedBox(height: 24),
          const Text('Actions', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _actionBtn('Update Record', Icons.edit_note_rounded, AppTheme.primary, () => context.push('/doctor/update/${user['id']}'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Verify Donor', Icons.verified_rounded, AppTheme.teal, () => context.push('/doctor/verify/${user['id']}?crisis_id='))),
            ],
          ),
          const SizedBox(height: 10),
          _actionBtnFull('View Full History', Icons.history_rounded, AppTheme.surfaceElevated, () {
            final uid = user['id'] as String? ?? '';
            if (uid.isNotEmpty) context.push('/medical-history?uid=$uid');
          }),
          const SizedBox(height: 16),
          TextButton(onPressed: () => setState(() { _scanned = false; _patient = null; }), child: const Text('Scan Again', style: TextStyle(fontFamily: 'Inter', color: AppTheme.primary))),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 14)),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _actionBtnFull(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}
