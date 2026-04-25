import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DonorIncomingScreen extends StatefulWidget {
  final String crisisId;
  const DonorIncomingScreen({super.key, required this.crisisId});

  @override
  State<DonorIncomingScreen> createState() => _DonorIncomingScreenState();
}

class _DonorIncomingScreenState extends State<DonorIncomingScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _crisis;
  bool _loading = true;
  bool _responded = false;
  bool _filled = false;
  String? _responseType;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadCrisis();
  }

  Future<void> _loadCrisis() async {
    try {
      final data = await context.read<ApiService>().getCrisis(widget.crisisId);
      setState(() {
        _crisis = data;
        _loading = false;
        _filled = data['status'] == 'fulfilled';
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(bool accept) async {
    final uid = context.read<AuthService>().uid!;
    final api = context.read<ApiService>();
    setState(() => _loading = true);
    try {
      if (accept) {
        await api.acceptDonation(widget.crisisId, uid);
        setState(() {
          _responded = true;
          _responseType = 'accepted';
        });
      } else {
        await api.declineDonation(widget.crisisId, uid);
        setState(() {
          _responded = true;
          _responseType = 'declined';
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _crisis == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    if (_filled && !_responded) {
      return _buildFilledScreen();
    }

    if (_responded) {
      return _buildRespondedScreen();
    }

    final bloodType = _crisis?['blood_type'] ?? '?';
    final severity = _crisis?['severity_score'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF2A0A0A), Color(0xFF1A0505)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                      ),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                  color:
                                      AppTheme.danger.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.danger, width: 2)),
                              child: Center(
                                  child: Text(bloodType,
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 28,
                                          color: AppTheme.danger))),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Blood Needed!',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                  color: Colors.white)),
                          const SizedBox(height: 6),
                          Text('Severity: $severity/10',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppTheme.onSurfaceMuted,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(
                              Icons.location_on_rounded,
                              'Nearest hospital listed as donation point',
                              AppTheme.teal),
                          const SizedBox(height: 12),
                          _infoRow(
                              Icons.access_time_rounded,
                              'Please respond quickly — timer is running',
                              AppTheme.amber),
                          const SizedBox(height: 12),
                          _infoRow(
                              Icons.verified_user_rounded,
                              'You have been selected based on your fitness score',
                              AppTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _respond(false),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side:
                              const BorderSide(color: AppTheme.onSurfaceMuted),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Decline',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceMuted,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _respond(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Accept',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.teal, size: 80),
              const SizedBox(height: 20),
              const Text('Request Already Filled',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text(
                  'Another donor has already accepted this request. No action needed. Thank you!',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRespondedScreen() {
    final accepted = _responseType == 'accepted';
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  accepted
                      ? Icons.volunteer_activism_rounded
                      : Icons.cancel_outlined,
                  color: accepted ? AppTheme.teal : AppTheme.onSurfaceMuted,
                  size: 80),
              const SizedBox(height: 20),
              Text(accepted ? 'You\'re a Hero! 🫀' : 'Response Sent',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.onSurface)),
              const SizedBox(height: 10),
              Text(
                  accepted
                      ? 'Thank you for accepting. Please head to the donation location.'
                      : 'You have declined this request.',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.onSurfaceMuted,
                    fontSize: 14))),
      ],
    );
  }
}
