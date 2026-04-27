import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/fitness_ring.dart';
import '../widgets/eligibility_badge.dart';
import '../widgets/activity_card.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentActivity = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
      // Start periodic GPS location syncing
      final uid = context.read<AuthService>().uid;
      if (uid != null) {
        final locationService = context.read<LocationService>();
        if (!locationService.isRunning) {
          locationService.start(uid);
        }
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadSummary());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    try {
      final summary = await context.read<ApiService>().getHomeSummary(uid);
      if (mounted) {
        context.read<UserProvider>().updateHomeSummary(summary);
        final activity = summary['recent_activity'];
        if (activity is List) {
          _recentActivity = activity.cast<Map<String, dynamic>>();
        }
      }
      
      // Sync FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && mounted) {
        await context.read<ApiService>().updateUserProfile(uid, {'fcm_token': fcmToken});
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(user)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (user.expiryWarning) _buildExpiryBanner(),
                    const SizedBox(height: 8),
                    _buildFitnessCard(user),
                    const SizedBox(height: 20),
                    _buildRequestBloodButton(context),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    const Text('Recent Activity',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: AppTheme.onSurface)),
                    const SizedBox(height: 12),
                    if (_recentActivity.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('No recent activity',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppTheme.onSurfaceMuted,
                                  fontSize: 14)),
                        ),
                      )
                    else
                      ..._recentActivity.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ActivityCard(
                              type: a['type'] ?? 'Request',
                              status: _statusLabel(a['status']),
                              time: _relativeTime(a['created_at']),
                            ),
                          )),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'fulfilled': return 'Fulfilled';
      case 'escalated_to_bank': return 'Escalated';
      case 'open': return 'Active';
      case 'closed': return 'Closed';
      default: return status ?? 'Unknown';
    }
  }

  String _relativeTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} wk ago';
    } catch (_) { return ''; }
  }

  Widget _buildHeader(UserProvider user) {
    final hour = DateTime.now().hour;
    final String greeting;
    final String icon;
    if (hour < 12) { greeting = 'Good morning'; icon = '🌅'; }
    else if (hour < 17) { greeting = 'Good afternoon'; icon = '☀️'; }
    else { greeting = 'Good evening'; icon = '🌙'; }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${user.name?.split(' ').first ?? 'User'} $icon', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: AppTheme.onSurface)),
              ],
            ),
          ),
          Stack(
            children: [
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: AppTheme.onSurface, size: 22),
                ),
              ),
              if (user.unreadNotifications > 0)
                Positioned(right: 6, top: 6, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4))),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('Your medical record expires soon. Visit a doctor to update.', style: TextStyle(fontFamily: 'Inter', color: AppTheme.amber, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildFitnessCard(UserProvider user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E1B30), Color(0xFF272340)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          FitnessRing(score: user.fitnessScore),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Donor Fitness', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${user.fitnessScore.toStringAsFixed(0)}/100', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 28, color: AppTheme.onSurface)),
                const SizedBox(height: 8),
                EligibilityBadge(isEligible: user.isEligible),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/qr'),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primary, size: 26)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestBloodButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/request/blood'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.danger, Color(0xFFE05252)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype_rounded, color: Colors.white, size: 26),
            SizedBox(width: 12),
            Text('Request Blood', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      const _QuickAction('My Requests', Icons.history_rounded, '/requests'),
      const _QuickAction('Medical', Icons.medical_information_outlined, '/medical-history'),
      const _QuickAction('QR Code', Icons.qr_code_rounded, '/qr'),
      const _QuickAction('Profile', Icons.person_outline_rounded, '/profile'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) => _buildActionTile(context, a)).toList(),
    );
  }

  Widget _buildActionTile(BuildContext context, _QuickAction a) {
    return GestureDetector(
      onTap: () => context.push(a.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)), child: Icon(a.icon, color: AppTheme.primary, size: 24)),
          const SizedBox(height: 6),
          Text(a.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  const _QuickAction(this.label, this.icon, this.route);
}
