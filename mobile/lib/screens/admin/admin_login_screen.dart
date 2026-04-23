import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the admin access code');
      return;
    }
    setState(() { _loading = true; _error = null; });

    // Demo passcode check
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (code == 'AIDRONA-ADMIN' || code == 'ADMIN') {
        context.go('/admin/dashboard');
      } else {
        setState(() {
          _error = 'Invalid access code. Contact system administrator.';
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF8B7CF8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Admin Access',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your administrator access code',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurface,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  labelText: 'Access Code',
                  hintText: 'AIDRONA-ADMIN',
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: AppTheme.onSurfaceMuted),
                ),
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
                          color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
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
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              GradientButton(
                onPressed: _loading ? null : _verify,
                loading: _loading,
                label: 'Access Dashboard',
                color: AppTheme.primary,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
