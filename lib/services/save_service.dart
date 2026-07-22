import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences that stores the whole game state as a
/// single JSON blob. Fully offline; all writes are wrapped so a storage error
/// can never crash the game.
class SaveService {
  static const _key = 'wingwhirl_save_v1';
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  Map<String, dynamic> load() {
    try {
      final raw = _prefs?.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      await _prefs?.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _prefs?.remove(_key);
    } catch (_) {}
  }
}
