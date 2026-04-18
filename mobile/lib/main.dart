import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'providers/user_provider.dart';
import 'providers/crisis_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/request_blood_screen.dart';
import 'screens/donor_incoming_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/medical_history_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/doctor/doctor_login_screen.dart';
import 'screens/doctor/scan_qr_screen.dart';
import 'screens/doctor/update_medical_screen.dart';
import 'screens/doctor/verify_donor_screen.dart';
import 'theme/app_theme.dart';

// Background/terminated message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification is stored in Firestore; no extra action needed here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // FCM: request permission and register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true, badge: true, sound: true,
  );

  runApp(const AiDronaApp());
}

class AiDronaApp extends StatefulWidget {
  const AiDronaApp({super.key});

  @override
  State<AiDronaApp> createState() => _AiDronaAppState();
}

class _AiDronaAppState extends State<AiDronaApp> {
  @override
  void initState() {
    super.initState();
    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final deepLink = data['deep_link'] ?? '';
      final crisisId = data['crisis_id'] ?? '';
      if (deepLink == '/donor/incoming' && crisisId.isNotEmpty) {
        _router.push('/donor/incoming?crisis_id=$crisisId');
      }
    });
    // Handle tap on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final deepLink = data['deep_link'] ?? '';
      final crisisId = data['crisis_id'] ?? '';
      if (deepLink == '/donor/incoming' && crisisId.isNotEmpty) {
        _router.push('/donor/incoming?crisis_id=$crisisId');
      } else if (deepLink.isNotEmpty) {
        _router.push(deepLink);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CrisisProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp.router(
        title: 'AiDrona',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/request/blood', builder: (_, __) => const RequestBloodScreen()),
    GoRoute(
      path: '/donor/incoming',
      builder: (ctx, state) => DonorIncomingScreen(crisisId: state.uri.queryParameters['crisis_id'] ?? ''),
    ),
    GoRoute(path: '/requests', builder: (_, __) => const MyRequestsScreen()),
    GoRoute(path: '/medical-history', builder: (_, __) => const MedicalHistoryScreen()),
    GoRoute(path: '/qr', builder: (_, __) => const QrCodeScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    // Doctor routes
    GoRoute(path: '/doctor/login', builder: (_, __) => const DoctorLoginScreen()),
    GoRoute(path: '/doctor/scan', builder: (_, __) => const ScanQrScreen()),
    GoRoute(
      path: '/doctor/update/:patient_id',
      builder: (ctx, state) => UpdateMedicalScreen(patientId: state.pathParameters['patient_id'] ?? ''),
    ),
    GoRoute(
      path: '/doctor/verify/:donor_id',
      builder: (ctx, state) => VerifyDonorScreen(
        donorId: state.pathParameters['donor_id'] ?? '',
        crisisId: state.uri.queryParameters['crisis_id'] ?? '',
      ),
    ),
  ],
);
