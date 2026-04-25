import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ScanQrScreen extends StatefulWidget {
  final String? crisisId;
  const ScanQrScreen({super.key, this.crisisId});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  Map<String, dynamic>? _patient;
  bool _loading = false;
  bool _cameraPermissionDenied = false;
  bool _checkingPermission = true;
  final _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionDenied = status.isDenied || status.isPermanentlyDenied;
        _checkingPermission = false;
      });
    }
  }

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
      await prefs.clear(); // Clear all doctor session data
      if (mounted) context.go('/role-select');
    }
  }

  Future<void> _fetchPatient(String input) async {
    if (input.isEmpty) return;
    setState(() {
      _loading = true;
      _scanned = true;
      _patient = null;
    });

    final api = context.read<ApiService>();
    String targetUid = input;

    try {
      // 1. If it looks like a phone number, try to resolve UID first
      final isPhone = RegExp(r'^(\+?\d{7,15})$').hasMatch(input.replaceAll(' ', ''));
      if (isPhone) {
        final userByPhone = await api.getUserByPhone(input.replaceAll(' ', '')).timeout(const Duration(seconds: 10));
        if (userByPhone['id'] != null) {
          targetUid = userByPhone['id'];
        }
      }

      // 2. Fetch full patient summary using UID
      final data = await api.getPatientSummary(targetUid).timeout(const Duration(seconds: 15));
      
      if (data['user'] == null) {
        throw 'Patient not found';
      }

      setState(() {
        _patient = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.danger,
        ));
      }
      setState(() {
        _loading = false;
        _scanned = false; // Go back to scanner if failed
      });
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
        title: const Text('Doctor Portal'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : _cameraPermissionDenied
              ? _buildPermissionError()
              : (_scanned ? _buildPatientView() : _buildScanner()),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.danger),
            const SizedBox(height: 16),
            const Text('Camera Permission Required',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Please enable camera access in settings to scan QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
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
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                        const SizedBox(height: 10),
                        Text('Camera Error: ${error.errorCode}', 
                          style: const TextStyle(color: AppTheme.onSurface, fontSize: 12)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _scanner.start(),
                          child: const Text('Retry Camera'),
                        ),
                      ],
                    ),
                  );
                },
                onDetect: (capture) {
                  if (_scanned) return;
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) {
                    _handleScannedCode(code);
                  }
                },
              ),
              // Scan frame overlay
              Center(
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.teal, width: 3), 
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: const Stack(
                    children: [
                      // Scanner animation line could be added here
                    ],
                  ),
                ),
              ),
              Positioned(bottom: 20, left: 0, right: 0, child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.surfaceCard.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Point camera at patient QR code', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 13)),
                ),
              )),
              
              // Debug button for emulator users
              if (kDebugMode)
                Positioned(
                  top: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleScannedCode('aidrona://user/WXAZuDEevDbGBcipKRIEkeATSXu2'),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Simulate Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Manual Entry', 
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCtrl, 
                      style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface), 
                      decoration: const InputDecoration(
                        hintText: 'Enter Phone or UID',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      )
                    )
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _fetchPatient(_manualCtrl.text.trim()), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ), 
                      child: const Icon(Icons.arrow_forward_rounded)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleScannedCode(String code) {
    // Parse aidrona://user/{uid}
    final uri = Uri.tryParse(code);
    final uid = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : code;
    _fetchPatient(uid);
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
          _infoTile('Blood Pressure', medical['blood_pressure'] ?? '—'),
          _infoTile('Last Visit', medical['last_visit_date'] ?? '—'),
          _infoTile('Medications', (medical['medications'] as List?)?.join(', ') ?? 'None'),
          _infoTile('Conditions', (medical['conditions'] as List?)?.join(', ') ?? 'None'),
          _infoTile('Donation Count', '${donor['donation_count'] ?? 0}'),
          _infoTile('Eligible', donor['is_eligible'] == true ? 'Yes ✓' : 'No ✗'),
          const SizedBox(height: 24),
          const Text('Actions', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _actionBtn('Update Record', Icons.edit_note_rounded, AppTheme.primary, () => context.push('/doctor/update/${user['id']}'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Verify Donor', Icons.verified_rounded, AppTheme.teal, () => context.push('/doctor/verify/${user['id']}?crisis_id=${widget.crisisId ?? ''}'))),
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
