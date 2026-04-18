import 'package:flutter/foundation.dart';

class CrisisProvider extends ChangeNotifier {
  String? _activeCrisisId;
  String? _crisisStatus;
  int _donorsNotified = 0;
  Map<String, dynamic>? _triage;

  String? get activeCrisisId => _activeCrisisId;
  String? get crisisStatus => _crisisStatus;
  int get donorsNotified => _donorsNotified;
  Map<String, dynamic>? get triage => _triage;

  void setCrisis({required String crisisId, required Map<String, dynamic> triage, required int donorsNotified}) {
    _activeCrisisId = crisisId;
    _triage = triage;
    _donorsNotified = donorsNotified;
    _crisisStatus = 'open';
    notifyListeners();
  }

  void updateStatus(String status) {
    _crisisStatus = status;
    notifyListeners();
  }

  void clear() {
    _activeCrisisId = null;
    _crisisStatus = null;
    _donorsNotified = 0;
    _triage = null;
    notifyListeners();
  }
}
