import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = context.read<AuthService>().uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await context.read<ApiService>().getUserNotifications(uid);
      if (mounted) {
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    try {
      await context.read<ApiService>().markNotificationsRead(uid);
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'read': true})
            .toList();
      });
    } catch (_) {}
  }

  String _relativeTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return ts.toString();
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'donor_popup':
        return Icons.bloodtype_rounded;
      case 'request_update':
        return Icons.check_circle_rounded;
      case 'escalation':
        return Icons.local_hospital_rounded;
      case 'medical_reminder':
      case 'request_filled':
        return Icons.medical_information_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'donor_popup':
        return AppTheme.danger;
      case 'request_update':
        return AppTheme.teal;
      case 'escalation':
        return AppTheme.amber;
      case 'request_filled':
        return AppTheme.onSurfaceMuted;
      case 'medical_reminder':
        return AppTheme.primary;
      default:
        return AppTheme.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.primary,
                    fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _buildItem(i),
                      ),
                    ),
    );
  }

  Widget _buildItem(int i) {
    final n = _notifications[i];
    final unread = !(n['read'] as bool? ?? false);
    final type = n['type'] as String? ?? '';
    return GestureDetector(
      onTap: () {
        setState(() => _notifications[i] = {...n, 'read': true});
        // Mark individual read silently
        final uid = context.read<AuthService>().uid;
        if (uid != null) {
          context.read<ApiService>().markNotificationsRead(uid);
        }
        final link = n['deep_link'] as String? ?? '/home';
        if (link == '/donor/incoming') {
          final crisisId = n['crisis_id'] as String? ?? '';
          if (crisisId.isNotEmpty) {
            context.push('/donor/incoming?crisis_id=$crisisId');
          }
        } else {
          context.push(link);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? AppTheme.surfaceElevated : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: unread
                  ? _colorFor(type).withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _colorFor(type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_iconFor(type), color: _colorFor(type), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title'] as String? ?? '',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppTheme.onSurface,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(n['body'] as String? ?? '',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_relativeTime(n['created_at']),
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 11)),
                ],
              ),
            ),
            if (unread)
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: _colorFor(type), shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_none_rounded,
              size: 60, color: AppTheme.onSurfaceMuted),
          SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load notifications',
              style: TextStyle(color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _load();
              },
              child: const Text('Retry')),
        ],
      ),
    );
  }
}
