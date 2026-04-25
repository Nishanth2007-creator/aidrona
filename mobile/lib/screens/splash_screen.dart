import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (!mounted) return;

    if (user != null) {
      try {
        final api = context.read<ApiService>();
        final userProvider = context.read<UserProvider>();
        
        // Ensure token is set for API calls
        final token = await user.getIdToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token ?? '');

        final data = await api.getUserProfile(user.uid).timeout(const Duration(seconds: 10));
        if (data['name'] != null && data['error'] == null) {
          userProvider.setUser(
            uid: user.uid,
            name: data['name'] ?? '',
            phone: data['phone'] ?? data['phone_number'] ?? '',
            bloodType: data['blood_type'] ?? '',
          );
          if (mounted) context.go('/home');
          return;
        }
      } catch (e) {
        debugPrint('Splash Profile Fetch Error: $e');
        // If profile fetch fails, we might still want to go home and let HomeScreen retry,
        // or go to onboarding if it's a 404. For now, let's go home if it's just a network error.
        if (mounted) context.go('/home');
        return;
      }
      // If no profile data found, maybe onboarding wasn't finished
      if (mounted) context.go('/onboarding');
    } else {
      context.go('/role-select');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF8B7CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 4)],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                const Text('AiDrona', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 36, color: AppTheme.onSurface, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text('Emergency Health Coordination', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
