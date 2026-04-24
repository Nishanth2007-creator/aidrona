import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/crisis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  String _bloodType = 'O+';
  String _urgency = 'critical';
  double _radius = 5;
  Position? _position;
  bool _listening = false;
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  Map<String, dynamic>? _result;

  final SpeechToText _speech = SpeechToText();
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<_UrgencyOption> _urgencies = [
    const _UrgencyOption('critical', 'Critical', AppTheme.danger),
    const _UrgencyOption('urgent', 'Urgent', AppTheme.amber),
    const _UrgencyOption('moderate', 'Moderate', AppTheme.teal),
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
    final userBT = context.read<UserProvider>().bloodType;
    if (userBT != null) _bloodType = userBT;
  }

  Future<void> _getLocation() async {
    setState(() {
      _position = null;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() =>
            _error = 'Location services are disabled. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _error = 'Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _error =
            'Location permissions are permanently denied. Tap to open settings.');
        return;
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }
  }

  Future<void> _startListening() async {
    final ok = await _speech.initialize();
    if (!ok) return;
    setState(() => _listening = true);
    _speech.listen(
        onResult: (r) {
          // Basic blood type extraction from voice
          final text = r.recognizedWords.toUpperCase();
          for (final bt in _bloodTypes) {
            if (text.contains(
                bt.replaceAll('+', ' POSITIVE').replaceAll('-', ' NEGATIVE'))) {
              setState(() => _bloodType = bt);
              break;
            }
          }
        },
        listenFor: const Duration(seconds: 10));
    await Future.delayed(const Duration(seconds: 10));
    _speech.stop();
    setState(() => _listening = false);
  }

  Future<void> _submit() async {
    if (_position == null) {
      setState(
          () => _error = 'Could not get your location. Please enable GPS.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = context.read<AuthService>().uid!;
      final apiService = context.read<ApiService>();
      final crisisProvider = context.read<CrisisProvider>();
      final result = await apiService.submitBloodRequest({
        'requester_id': uid,
        'blood_type': _bloodType,
        'urgency': _urgency,
        'lat': _position!.latitude,
        'lng': _position!.longitude,
        'radius_km': _radius,
      });

      if (!mounted) return;
      crisisProvider.setCrisis(
        crisisId: result['crisis_id'] ?? '',
        triage: result['triage'] ?? {},
        donorsNotified: result['donors_notified'] ?? 0,
      );
      setState(() {
        _result = result;
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Request Blood'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop())),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Blood Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _bloodTypes.map((bt) {
              final sel = bt == _bloodType;
              return GestureDetector(
                onTap: () => setState(() => _bloodType = bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.danger : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: AppTheme.danger.withValues(alpha: 0.4),
                                blurRadius: 12)
                          ]
                        : [],
                  ),
                  child: Text(bt,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.onSurfaceMuted)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Urgency Level'),
          const SizedBox(height: 12),
          Row(
            children: _urgencies.map((u) {
              final sel = u.value == _urgency;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _urgency = u.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel
                          ? u.color.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? u.color : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.circle, color: u.color, size: 10),
                        const SizedBox(height: 6),
                        Text(u.label,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color:
                                    sel ? u.color : AppTheme.onSurfaceMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _sectionLabel('Search Radius'),
              const Spacer(),
              Text('${_radius.toStringAsFixed(0)} km',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontSize: 15)),
            ],
          ),
          Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.surfaceElevated,
              onChanged: (v) => setState(() => _radius = v)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_error != null && _error!.contains('settings')) {
                Geolocator.openAppSettings();
              } else {
                _getLocation();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _error != null
                          ? AppTheme.danger.withValues(alpha: 0.3)
                          : Colors.transparent)),
              child: Row(
                children: [
                  Icon(
                      _position != null
                          ? Icons.location_on_rounded
                          : Icons.location_off_outlined,
                      color: _position != null
                          ? AppTheme.teal
                          : (_error != null ? AppTheme.danger : AppTheme.onSurfaceMuted),
                      size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _position != null
                                ? 'Location: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                : (_error ?? 'Fetching location...'),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: _error != null
                                    ? AppTheme.danger
                                    : AppTheme.onSurfaceMuted)),
                        if (_position == null && _error == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              color: AppTheme.teal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.refresh_rounded,
                      size: 18, color: AppTheme.onSurfaceMuted.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _listening
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.mic_rounded,
                          color: _listening
                              ? AppTheme.primary
                              : AppTheme.onSurfaceMuted,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_listening)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('🎙 Listening... say your blood type',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppTheme.primary,
                        fontSize: 13))),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.danger,
                        fontFamily: 'Inter',
                        fontSize: 13))),
          const SizedBox(height: 32),
          GradientButton(
              onPressed: _loading ? null : _submit,
              loading: _loading,
              label: 'Submit Request',
              color: AppTheme.danger),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final triage = _result?['triage'] as Map? ?? {};
    final donorsNotified = _result?['donors_notified'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.teal, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Request Submitted!',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          Text('$donorsNotified donors have been notified',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 15)),
          const SizedBox(height: 32),
          _statCard('Severity Score', '${(triage['severity_score'] ?? 0)}/10',
              AppTheme.primary),
          const SizedBox(height: 12),
          _statCard(
              'Est. Response',
              '${triage['estimated_response_minutes'] ?? '?'} min',
              AppTheme.teal),
          const Spacer(),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () {
                  final crisis = context.read<CrisisProvider>();
                  if (crisis.activeCrisisId != null) {
                    context
                        .read<ApiService>()
                        .extendRadius(crisis.activeCrisisId!, 10);
                  }
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Extend Range',
                    style: TextStyle(
                        fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: GradientButton(
                onPressed: () {
                  final crisis = context.read<CrisisProvider>();
                  final pos = _position;
                  if (crisis.activeCrisisId != null && pos != null) {
                    context.read<ApiService>().openToStrangers(
                        crisis.activeCrisisId!, pos.latitude, pos.longitude);
                  }
                },
                label: 'Open to All',
                color: AppTheme.primary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home',
                  style: TextStyle(
                      fontFamily: 'Inter', color: AppTheme.onSurfaceMuted))),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: color)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppTheme.onSurface));
}

class _UrgencyOption {
  final String value, label;
  final Color color;
  const _UrgencyOption(this.value, this.label, this.color);
}
