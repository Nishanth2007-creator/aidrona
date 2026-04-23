import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _insights = {};
  List<dynamic> _crises = [];
  int _userCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getAdminInsights('India'),
        api.getActiveCrises(),
        api.getAdminUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _insights = results[0] as Map<String, dynamic>;
        _crises = results[1] as List<dynamic>;
        _userCount = (results[2] as List<dynamic>).length;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/role-select'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                              child: _StatCard(
                                  label: 'Users',
                                  value: '$_userCount',
                                  icon: Icons.people_rounded,
                                  color: AppTheme.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _StatCard(
                                  label: 'Active Crises',
                                  value: '${_crises.length}',
                                  icon: Icons.warning_rounded,
                                  color: AppTheme.danger)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // AI Insights
                      const Text('AI Insights',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      if (_insights['narrative_summary'] != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.12),
                                AppTheme.surfaceCard,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.auto_awesome,
                                        color: AppTheme.primary, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Gemini Analysis',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurface)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _insights['narrative_summary'] ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppTheme.onSurfaceMuted,
                                    fontSize: 13,
                                    height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Shortage risks
                      if ((_insights['shortage_risk_types'] as List?)
                              ?.isNotEmpty ==
                          true) ...[
                        _InsightChips(
                          title: 'Shortage Risks',
                          items: List<String>.from(
                              _insights['shortage_risk_types'] ?? []),
                          color: AppTheme.danger,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if ((_insights['predicted_peak_hours'] as List?)
                              ?.isNotEmpty ==
                          true) ...[
                        _InsightChips(
                          title: 'Peak Hours',
                          items: List<String>.from(
                              _insights['predicted_peak_hours'] ?? []),
                          color: AppTheme.amber,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if ((_insights['suggested_awareness_areas'] as List?)
                              ?.isNotEmpty ==
                          true) ...[
                        _InsightChips(
                          title: 'Awareness Areas',
                          items: List<String>.from(
                              _insights['suggested_awareness_areas'] ?? []),
                          color: AppTheme.teal,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Active crises
                      const Text('Active Crises',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      if (_crises.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: AppTheme.eligible, size: 40),
                                SizedBox(height: 8),
                                Text('No active crises',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppTheme.onSurfaceMuted)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(_crises.length, (i) {
                          final c = _crises[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.bloodtype_rounded,
                                      color: AppTheme.danger,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${c['blood_type'] ?? '?'} Blood Needed',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.onSurface,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        'Severity: ${c['severity_score'] ?? '?'}/10 · Status: ${c['status'] ?? 'open'}',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color:
                                                AppTheme.onSurfaceMuted,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  ),
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
          const Text('Failed to load admin data',
              style: TextStyle(
                  fontFamily: 'Inter', color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _InsightChips extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _InsightChips(
      {required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(s.toString(),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
