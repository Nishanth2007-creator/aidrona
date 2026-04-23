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

  // Controllers
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  
  String _bloodType = 'O+';
  bool _uploadedDoc = false;
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
    _emergencyContactCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _nextPage() => _pageController.nextPage(
      duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

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

  void _goToMedical() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() => _error = null);
    _nextPage();
  }

  Future<void> _simulateUpload() async {
    setState(() { _loading = true; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _uploadedDoc = true; _loading = false; });
  }

  Future<void> _register() async {
    setState(() { _loading = true; });
    try {
      final auth = context.read<AuthService>();
      final api = context.read<ApiService>();
      Position? pos;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        }
      } catch (e) {
        print('GPS Error: $e');
      }

      await api.register({
        'uid': auth.uid,
        'name': _nameCtrl.text.trim(),
        'phone': auth.phone,
        'blood_type': _bloodType,
        'emergency_contact_name': _emergencyContactCtrl.text.trim(),
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
        'lat': pos?.latitude ?? 0,
        'lng': pos?.longitude ?? 0,
        'role': 'patient',
      });
      
      // If doc uploaded, we should ideally call /medical/upload, simulating AI parsing
      if (_uploadedDoc && auth.uid != null) {
        try {
          await api.uploadMedicalRecord({
            'patient_id': auth.uid,
            'hospital': 'AIdrona Upload',
            'base64_image': 'dummy_data', // Mock upload
          });
        } catch (_) {}
      }

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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_pageController.page == 0) {
              context.go('/role-select');
            } else {
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
            }
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _PhonePage(
                ctrl: _phoneCtrl,
                loading: _loading,
                error: _error,
                onSend: _sendOtp),
            _OtpPage(
                ctrl: _otpCtrl,
                loading: _loading,
                error: _error,
                onVerify: _verifyOtp),
            _ProfilePage(
              nameCtrl: _nameCtrl,
              emergencyContactCtrl: _emergencyContactCtrl,
              emergencyPhoneCtrl: _emergencyPhoneCtrl,
              bloodType: _bloodType,
              bloodTypes: _bloodTypes,
              error: _error,
              onBloodTypeSelect: (bt) => setState(() => _bloodType = bt),
              onNext: _goToMedical,
            ),
            _MedicalUploadPage(
              loading: _loading,
              uploaded: _uploadedDoc,
              error: _error,
              onUpload: _simulateUpload,
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
  const _PhonePage(
      {required this.ctrl, required this.loading, this.error, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Donor / Patient\nRegistration',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppTheme.onSurface,
                  height: 1.2)),
          const SizedBox(height: 12),
          const Text('Enter your phone number to get started',
              style: TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 15,
                  fontFamily: 'Inter')),
          const SizedBox(height: 40),
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Text('+91',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: AppTheme.onSurface))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(
                          fontFamily: 'Inter', color: AppTheme.onSurface),
                      decoration: const InputDecoration(
                          hintText: 'Phone number', counterText: ''))),
            ],
          ),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GradientButton(
                onPressed: loading ? null : onSend,
                loading: loading,
                label: 'Send OTP'),
          ),
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
  const _OtpPage(
      {required this.ctrl, required this.loading, this.error, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Verify OTP',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          const Text('Enter the 6-digit code sent to your number',
              style: TextStyle(
                  color: AppTheme.onSurfaceMuted, fontFamily: 'Inter')),
          const SizedBox(height: 40),
          TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  letterSpacing: 12,
                  color: AppTheme.onSurface),
              decoration: const InputDecoration(counterText: '')),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GradientButton(
                onPressed: loading ? null : onVerify,
                loading: loading,
                label: 'Verify'),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emergencyContactCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final String bloodType;
  final List<String> bloodTypes;
  final String? error;
  final Function(String) onBloodTypeSelect;
  final VoidCallback onNext;
  
  const _ProfilePage(
      {required this.nameCtrl,
      required this.emergencyContactCtrl,
      required this.emergencyPhoneCtrl,
      required this.bloodType,
      required this.bloodTypes,
      this.error,
      required this.onBloodTypeSelect,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Your Profile',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 32),
          TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                  fontFamily: 'Inter', color: AppTheme.onSurface),
              decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppTheme.onSurfaceMuted))),
          const SizedBox(height: 20),
          TextField(
              controller: emergencyContactCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                  fontFamily: 'Inter', color: AppTheme.onSurface),
              decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.contact_phone_outlined,
                      color: AppTheme.amber))),
          const SizedBox(height: 20),
          TextField(
              controller: emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                  fontFamily: 'Inter', color: AppTheme.onSurface),
              decoration: const InputDecoration(
                  labelText: 'Emergency Phone Number',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_rounded,
                      color: AppTheme.amber))),
          const SizedBox(height: 28),
          const Text('Blood Type',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: bloodTypes.map((bt) {
              final selected = bt == bloodType;
              return GestureDetector(
                onTap: () => onBloodTypeSelect(bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? AppTheme.primary : Colors.transparent,
                        width: 2),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 12)
                          ]
                        : [],
                  ),
                  child: Text(bt,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.onSurfaceMuted,
                          fontSize: 15)),
                ),
              );
            }).toList(),
          ),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!,
                    style: const TextStyle(color: AppTheme.danger))),
          const SizedBox(height: 48),
          GradientButton(
              onPressed: onNext,
              loading: false,
              label: 'Continue'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MedicalUploadPage extends StatelessWidget {
  final bool loading;
  final bool uploaded;
  final String? error;
  final VoidCallback onUpload;
  final VoidCallback onRegister;
  const _MedicalUploadPage({
    required this.loading,
    required this.uploaded,
    this.error,
    required this.onUpload,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Medical History',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          const Text('Upload past medical prescriptions for AI fitness evaluation (Optional)',
              style: TextStyle(
                  color: AppTheme.onSurfaceMuted, fontFamily: 'Inter')),
          const SizedBox(height: 36),
          
          GestureDetector(
            onTap: (loading || uploaded) ? null : onUpload,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: uploaded ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: uploaded ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
                  width: uploaded ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                   Icon(
                    uploaded ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                    size: 48,
                    color: uploaded ? AppTheme.primary : AppTheme.onSurfaceMuted,
                  ),
                  const SizedBox(height: 16),
                  if (loading && !uploaded)
                    const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Text(
                      uploaded ? 'Document Uploaded & Scanned!' : 'Tap to upload Image or PDF',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: uploaded ? AppTheme.primary : AppTheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!, style: const TextStyle(color: AppTheme.danger, fontFamily: 'Inter', fontSize: 13))),
                    ],
                  ),
                )
            ),
          
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GradientButton(
                onPressed: loading ? null : onRegister,
                loading: loading,
                label: uploaded ? 'Complete Registration' : 'Skip for now'),
          ),
        ],
      ),
    );
  }
}
