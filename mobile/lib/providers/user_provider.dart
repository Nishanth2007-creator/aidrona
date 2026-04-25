import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _uid;
  String? _name;
  String? _phone;
  String? _bloodType;
  String? _role;
  double _fitnessScore = 0;
  bool _isEligible = false;
  bool _expiryWarning = false;
  int _unreadNotifications = 0;

  String? get uid => _uid;
  String? get name => _name;
  String? get phone => _phone;
  String? get bloodType => _bloodType;
  String? get role => _role;
  double get fitnessScore => _fitnessScore;
  bool get isEligible => _isEligible;
  bool get expiryWarning => _expiryWarning;
  int get unreadNotifications => _unreadNotifications;

  void setUser({
    required String uid,
    required String name,
    required String phone,
    required String bloodType,
    String role = 'patient',
  }) {
    _uid = uid;
    _name = name;
    _phone = phone;
    _bloodType = bloodType;
    _role = role;
    notifyListeners();
  }

  void updateHomeSummary(Map<String, dynamic> summary) {
    if (summary['user'] != null) {
      final u = summary['user'];
      _name = u['name'];
      _phone = u['phone'];
      _bloodType = u['blood_type'];
      _role = u['role'];
    }
    final fitness = summary['fitness_status'] as Map<String, dynamic>? ?? {};
    _fitnessScore = (fitness['score'] as num?)?.toDouble() ?? 0;
    _isEligible = fitness['is_eligible'] as bool? ?? false;
    _expiryWarning = summary['expiry_warning'] as bool? ?? false;
    _unreadNotifications = summary['unread_notifications'] as int? ?? 0;
    notifyListeners();
  }

  void clear() {
    _uid = null;
    _name = null;
    _phone = null;
    _bloodType = null;
    _role = null;
    _fitnessScore = 0;
    _isEligible = false;
    notifyListeners();
  }
}
