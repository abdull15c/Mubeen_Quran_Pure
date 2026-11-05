import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'khatm_models.dart';

class KhatmController extends ChangeNotifier {
  KhatmController() {
    _initFuture = _load();
  }

  static const String _khatmStorageKey = 'mubeen_khatm_plan_v1';
  late final Future<void> _initFuture;
  KhatmPlan? _plan;
  bool _initialized = false;

  KhatmPlan? get plan => _plan;
  bool get hasActivePlan => _plan != null;
  bool get initialized => _initialized;

  Future<void> ensureInitialized() => _initFuture;

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_khatmStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _plan = KhatmPlan.fromJson(jsonStr);
      }
    } catch (e) {
      debugPrint('Error loading Khatm plan: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> createPlan({
    int targetDays = 30,
    String title = 'Хатм за 30 дней',
  }) async {
    await _initFuture;
    _plan = KhatmPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetDays: targetDays,
      startDate: DateTime.now(),
      completedPages: <int>{},
    );
    notifyListeners();
    await _persist();
  }

  Future<void> recordPageRead(int page) async {
    await _initFuture;
    if (_plan == null) return;
    if (_plan!.completedPages.contains(page)) return;

    _plan = _plan!.markPage(page);
    notifyListeners();
    await _persist();
  }

  Future<void> deletePlan() async {
    await _initFuture;
    _plan = null;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_khatmStorageKey);
  }

  Future<void> _persist() async {
    if (_plan == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_khatmStorageKey, _plan!.toJson());
    } catch (_) {}
  }
}
