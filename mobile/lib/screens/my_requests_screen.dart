import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/request_card.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter'),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          tabs: const [Tab(text: 'Sent'), Tab(text: 'Received')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RequestsList(type: 'sent'),
          _RequestsList(type: 'received'),
        ],
      ),
    );
  }
}

class _RequestsList extends StatefulWidget {
  final String type;
  const _RequestsList({required this.type});

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      final data = await context
          .read<ApiService>()
          .getMyRequests(uid, type: widget.type);
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return iso;
    }
  }

  Map<String, dynamic> _toCardData(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    if (widget.type == 'sent') {
      return {
        'blood_type': map['blood_type'] ?? '—',
        'status': map['status'] ?? 'closed',
        'created_at': _relativeTime(map['created_at']),
        'severity': map['severity_score'] ?? 0,
      };
    } else {
      // Received (donor_response): show status of the response
      return {
        'blood_type': map['blood_type'] ?? '—',
        'status': map['status'] ?? 'pending',
        'created_at': _relativeTime(map['created_at']),
        'severity': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load', style: const TextStyle(color: AppTheme.onSurfaceMuted)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.type == 'sent'
                  ? Icons.send_outlined
                  : Icons.volunteer_activism_outlined,
              size: 56,
              color: AppTheme.onSurfaceMuted,
            ),
            const SizedBox(height: 14),
            Text(
              widget.type == 'sent'
                  ? 'No blood requests sent yet'
                  : 'No donation requests received',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() { _loading = true; _error = null; });
        await _load();
      },
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => RequestCard(data: _toCardData(_items[i])),
      ),
    );
  }
}
