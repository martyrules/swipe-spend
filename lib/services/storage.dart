import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lokale opslag (localStorage op web). Niks gaat naar een server.
class LocalStore {
  static const _kOnboarding = 'onboarding_done_v1';
  static const _kSession = 'session_v2';

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null; // bv. private mode zonder storage: gewoon in-memory
    }
  }

  bool get onboardingDone => _prefs?.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingDone(bool v) async =>
      _prefs?.setBool(_kOnboarding, v);

  Map<String, Object?>? loadSession() {
    final raw = _prefs?.getString(_kSession);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(Map<String, Object?> session) async =>
      _prefs?.setString(_kSession, jsonEncode(session));

  Future<void> clearSession() async => _prefs?.remove(_kSession);
}
