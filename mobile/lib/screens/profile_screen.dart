import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/eligibility_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _donorActive = true;
  String _language = 'English';
  bool _updatingDonor = false;

  Future<void> _toggleDonorActive(bool val) async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    setState(() { _donorActive = val; _updatingDonor = true; });
    try {
      await context.read<ApiService>().updateUserProfile(uid, {'donor_active': val});
    } catch (_) {
      setState(() => _donorActive = !val); // revert on failure
    } finally {
      setState(() => _updatingDonor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + name
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.1), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF8B7CF8)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16)],
                    ),
                    child: Center(child: Text(user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 32, color: Colors.white))),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name ?? '—', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20, color: AppTheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(user.phone ?? '—', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
                  const SizedBox(height: 12),
                  EligibilityBadge(isEligible: user.isEligible),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Blood type chip
          _section('Health Info', [
            _infoTile('Blood Type', user.bloodType ?? '—', Icons.bloodtype_rounded),
            _infoTile('Fitness Score', '${user.fitnessScore.toStringAsFixed(0)}/100', Icons.monitor_heart_outlined),
          ]),
          const SizedBox(height: 16),

          // Settings
          _section('Settings', [
            _switchTile('Active Donor', 'Receive donation requests', Icons.volunteer_activism_rounded, _donorActive, _toggleDonorActive),
            _dropdownTile('Language', Icons.language_rounded, _language, ['English', 'Tamil', 'Hindi'], (v) => setState(() => _language = v!)),
          ]),
          const SizedBox(height: 16),

          // Danger zone
          _section('Account', [
            _actionTile('Sign Out', Icons.logout_rounded, AppTheme.onSurfaceMuted, () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/onboarding');
            }),
            _actionTile('Delete Account', Icons.delete_outline_rounded, AppTheme.danger, () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.surfaceCard,
                  title: const Text('Delete Account?', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface)),
                  content: const Text('All your data will be permanently deleted. This cannot be undone.', style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceMuted))),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final uid = context.read<AuthService>().uid;
                        if (uid == null) return;
                        final apiService = context.read<ApiService>();
                        final authService = context.read<AuthService>();
                        try {
                          await apiService.deleteAccount(uid);
                        } catch (_) {}
                        try {
                          await authService.signOut();
                        } catch (_) {}
                        if (context.mounted) context.go('/onboarding');
                      },
                      child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                    ),
                  ],
                ),
              );
            }),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurfaceMuted, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)), child: Column(children: children)),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 13)),
      trailing: Text(value, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppTheme.onSurface, fontSize: 14)),
    );
  }

  Widget _switchTile(String label, String sub, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceMuted, fontSize: 12)),
      trailing: _updatingDonor
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          : Switch(value: value, onChanged: onChanged, activeTrackColor: AppTheme.primary.withValues(alpha: 0.5), activeThumbColor: AppTheme.primary),
    );
  }

  Widget _dropdownTile(String label, IconData icon, String value, List<String> options, Function(String?) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: AppTheme.surfaceElevated,
        style: const TextStyle(fontFamily: 'Inter', color: AppTheme.onSurface, fontSize: 13),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(fontFamily: 'Inter', color: color, fontSize: 14)),
      onTap: onTap,
    );
  }
}
