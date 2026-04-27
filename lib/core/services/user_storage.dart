import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

/// Persists the signed-in user's profile to SharedPreferences as JSON.
class UserStorage {
  UserStorage._();

  static const _kUserKey = 'current_user_v1';

  static Future<void> save(Player p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserKey, jsonEncode(p.toMap()));
  }

  static Future<Player?> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Player.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasUser() async => (await load()) != null;

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserKey);
  }
}
