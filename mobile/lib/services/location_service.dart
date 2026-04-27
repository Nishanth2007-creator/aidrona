import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Periodically syncs the user's GPS location to the backend.
///
/// - Polls every [_intervalMinutes] minutes while the app is in the foreground.
/// - Only sends an update if the user has moved more than [_minDistanceMeters]
///   from the last synced position (avoids unnecessary writes).
/// - Gracefully degrades: if GPS or network fails, it silently retries next cycle.
class LocationService {
  LocationService(this._api);

  final ApiService _api;
  Timer? _timer;
  String? _uid;
  Position? _lastSyncedPosition;

  static const int _intervalMinutes = 5;
  static const double _minDistanceMeters = 100; // ~100m movement threshold

  /// Start periodic location syncing for the given user.
  void start(String uid) {
    _uid = uid;
    // Do an immediate sync, then schedule periodic
    _syncLocation();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: _intervalMinutes),
      (_) => _syncLocation(),
    );
    debugPrint('[LocationService] Started (every $_intervalMinutes min) for $uid');
  }

  /// Stop periodic syncing (call on logout or dispose).
  void stop() {
    _timer?.cancel();
    _timer = null;
    _uid = null;
    _lastSyncedPosition = null;
    debugPrint('[LocationService] Stopped');
  }

  /// Whether the service is currently running.
  bool get isRunning => _timer != null && _uid != null;

  Future<void> _syncLocation() async {
    if (_uid == null) return;

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled, skipping');
        return;
      }

      // Check permission (don't request — only sync if already granted)
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] No location permission, skipping');
        return;
      }

      // Get current position (medium accuracy is fine for proximity matching)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Only send update if the user has moved significantly
      if (_lastSyncedPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastSyncedPosition!.latitude,
          _lastSyncedPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < _minDistanceMeters) {
          debugPrint(
              '[LocationService] Moved ${distance.toStringAsFixed(0)}m < ${_minDistanceMeters}m threshold, skipping');
          return;
        }
      }

      // Send to backend
      await _api.updateUserProfile(_uid!, {
        'lat': position.latitude,
        'lng': position.longitude,
      });

      _lastSyncedPosition = position;
      debugPrint(
          '[LocationService] Synced: ${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}');
    } catch (e) {
      debugPrint('[LocationService] Sync failed (will retry): $e');
    }
  }
}
