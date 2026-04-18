import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _bloodType = 'O+';
  String? _verificationId;
  bool _loading = false;
  String? _error;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _loading = true; _error = null; });

    final auth = context.read<AuthService>();
    await auth.sendOtp(
      phoneNumber: '+91$phone',
      onAutoVerify: (cred) async {
        await _signIn(cred);
      },
      onCodeSent: (vid, _) {
        setState(() { _verificationId = vid; _loading = false; });
        _nextPage();
      },
      onError: (e) => setState(() { _error = e.message; _loading = false; }),
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    setState(() { _loading = true; });
    final auth = context.read<AuthService>();
    final cred = await auth.verifyOtp(_verificationId!, _otpCtrl.text.trim());
    if (cred != null) {
      setState(() { _loading = false; });
      _nextPage();
    } else {
      setState(() { _error = 'Invalid OTP'; _loading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; });
    try {
      final auth = context.read<AuthService>();
      final api = context.read<ApiService>();
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}

      final result = await api.register({
        'uid': auth.uid,
        'name': _nameCtrl.text.trim(),
        'phone': auth.phone,
        'blood_type': _bloodType,
        'lat': pos?.latitude ?? 0,
        'lng': pos?.longitude ?? 0,
        'role': 'patient',
      });

      if (!mounted) return;
      context.read<UserProvider>().setUser(
        uid: auth.uid!,
        name: _nameCtrl.text.trim(),
        phone: auth.phone ?? '',
        bloodType: _bloodType,
      );
      context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signIn(PhoneAuthCredential credential) async {
    await FirebaseAuth.instance.signInWithCredential(credential);
    if (!mounted) return;
    setState(() { _loading = false; });
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _PhonePage(ctrl: _phoneCtrl, loading: _loading, error: _error, onSend: _sendOtp),
            _OtpPage(ctrl: _otpCtrl, loading: _loading, error: _error, onVerify: _verifyOtp),
            _ProfilePage(nameCtrl: _nameCtrl, bloodType: _bloodType, bloodTypes: _bloodTypes, loading: _loading, error: _error,
              onBloodTypeSelect: (bt) => setState(() => _bloodType = bt),
              onRegister: _register,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhonePage extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onSend;
  const _PhonePage({required this.ctrl, required this.loading, this.error, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text('Welcome to\nAiDrona', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 36, color: AppTheme.onSurface, height: 1.2)),
          const SizedBox(height: 12),
          const Text('Enter your phone number to get started', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 15, fontFamily: 'Inter')),
          const SizedBox(height: 40),
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18), decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(12)), child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppTheme.onSurface))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.phone, maxLength: 10, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface), decoration: const InputDecoration(hintText: 'Phone number', counterText: ''))),
            ],
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
          const SizedBox(height: 24),
          GradientButton(onPressed: loading ? null : onSend, loading: loading, label: 'Send OTP'),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OtpPage extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onVerify;
  const _OtpPage({required this.ctrl, required this.loading, this.error, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text('Verify OTP', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 32, color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          const Text('Enter the 6-digit code sent to your number', style: TextStyle(color: AppTheme.onSurfaceMuted, fontFamily: 'Inter')),
          const SizedBox(height: 36),
          TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, letterSpacing: 12, color: AppTheme.onSurface), decoration: const InputDecoration(counterText: '')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
          const SizedBox(height: 28),
          GradientButton(onPressed: loading ? null : onVerify, loading: loading, label: 'Verify'),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final String bloodType;
  final List<String> bloodTypes;
  final bool loading;
  final String? error;
  final Function(String) onBloodTypeSelect;
  final VoidCallback onRegister;
  const _ProfilePage({required this.nameCtrl, required this.bloodType, required this.bloodTypes, required this.loading, this.error, required this.onBloodTypeSelect, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text('Your Profile', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 32, color: AppTheme.onSurface)),
          const SizedBox(height: 32),
          TextField(controller: nameCtrl, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface), decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.onSurfaceMuted))),
          const SizedBox(height: 24),
          const Text('Blood Type', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: bloodTypes.map((bt) {
              final selected = bt == bloodType;
              return GestureDetector(
                onTap: () => onBloodTypeSelect(bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 2),
                    boxShadow: selected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 12)] : [],
                  ),
                  child: Text(bt, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.onSurfaceMuted, fontSize: 15)),
                ),
              );
            }).toList(),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppTheme.danger))),
          const SizedBox(height: 32),
          GradientButton(onPressed: loading ? null : onRegister, loading: loading, label: 'Get Started'),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
