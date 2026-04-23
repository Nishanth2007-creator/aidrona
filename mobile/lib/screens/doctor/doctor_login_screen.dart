import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _regIdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _regIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final regId = _regIdCtrl.text.trim();
    if (regId.isEmpty) {
      setState(() => _error = 'Please enter your registration ID');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result =
          await context.read<ApiService>().verifyDoctor(regId);
      if (result['verified'] == true) {
        // Persist reg_id for use in medical update screen
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('doctor_reg_id', regId);
        final doctorName =
            result['doctor']?['name'] as String? ?? 'Doctor';
        await prefs.setString('doctor_name', doctorName);
        if (mounted) context.go('/doctor/scan');
      } else {
        setState(() { _error = 'Verification failed'; _loading = false; });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('not registered')
            ? 'Doctor ID not found in system. Use DR-XXXXX format for demos.'
            : 'Verification error. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/role-select'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.onSurface, size: 18),
                ),
              ),
              const Spacer(),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_hospital_rounded,
                    color: AppTheme.teal, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('Doctor Login',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: AppTheme.onSurface)),
              const SizedBox(height: 8),
              const Text('Verified medical professionals only',
                  style: TextStyle(
                      fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
              const SizedBox(height: 36),
              Row(
                children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('+91',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: AppTheme.onSurface))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontFamily: 'Inter', color: AppTheme.onSurface),
                        decoration: const InputDecoration(
                            hintText: 'Phone number (optional)')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _regIdCtrl,
                style: const TextStyle(
                    fontFamily: 'Inter', color: AppTheme.onSurface),
                decoration: const InputDecoration(
                    labelText: 'Medical Registration ID (e.g. DR-12345)',
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppTheme.onSurfaceMuted)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.4))),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppTheme.danger,
                                    fontSize: 13))),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              GradientButton(
                onPressed: _loading ? null : _verify,
                loading: _loading,
                label: 'Verify & Continue',
                color: AppTheme.teal,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
