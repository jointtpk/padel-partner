import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

/// Persists the signed-in user's profile to SharedPreferences as JSON,
/// plus an email-keyed registry of all profiles known on this device.
///
/// The registry lets a returning user (same email) sign in and recover
/// their original profile instead of being treated as a brand-new
/// account every time. Seed entries for the two demo users are inserted
/// at startup via [ensureSeedUsers].
class UserStorage {
  UserStorage._();

  static const _kUserKey     = 'current_user_v1';
  static const _kRegistryKey = 'user_registry_v1';

  // ── Current user ──────────────────────────────────────────────────────────

  static Future<void> save(Player p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserKey, jsonEncode(p.toMap()));
    // Mirror into the registry so subsequent sign-ins can restore this
    // profile by email even after a sign-out wipes the active session.
    final email = p.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final reg = await _loadRegistry();
      reg[email] = p;
      await _saveRegistry(reg);
    }
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

  /// Clears the *active* session only — the registry of known emails is
  /// preserved so the user can sign back in with the same email and
  /// recover the same identity.
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserKey);
  }

  // ── Email registry ────────────────────────────────────────────────────────

  static Future<Player?> findByEmail(String email) async {
    final reg = await _loadRegistry();
    return reg[email.trim().toLowerCase()];
  }

  static Future<Map<String, Player>> _loadRegistry() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kRegistryKey);
    if (raw == null || raw.isEmpty) return <String, Player>{};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, Player>{};
      m.forEach((k, v) {
        if (v is Map) {
          try {
            out[k] = Player.fromMap(Map<String, dynamic>.from(v));
          } catch (_) {/* skip malformed entries */}
        }
      });
      return out;
    } catch (_) {
      return <String, Player>{};
    }
  }

  static Future<void> _saveRegistry(Map<String, Player> reg) async {
    final sp = await SharedPreferences.getInstance();
    final m = <String, dynamic>{};
    reg.forEach((k, v) => m[k] = v.toMap());
    await sp.setString(_kRegistryKey, jsonEncode(m));
  }

  /// Seeds the two demo accounts the team uses for testing the host /
  /// player split. Idempotent — only inserts entries that don't already
  /// exist, so real edits to those profiles won't be clobbered on every
  /// app launch.
  static Future<void> ensureSeedUsers() async {
    final reg = await _loadRegistry();
    var changed = false;

    if (!reg.containsKey('manooazad@gmail.com')) {
      reg['manooazad@gmail.com'] = const Player(
        id: 'me',
        name: 'Manoo Azad',
        handle: '@manoo',
        level: 3.4,
        tier: 'pro',
        badge: 'Pro',
        avatarColor: Color(0xFFFFD27A),
        initials: 'MA',
        city: 'Karachi',
        wins: 28,
        games: 42,
        age: 28,
        gender: 'M',
        email: 'manooazad@gmail.com',
        bio: 'Hosting weekend matches · always down for a rally.',
      );
      changed = true;
    }

    if (!reg.containsKey('taqiratnani@hotmail.com')) {
      reg['taqiratnani@hotmail.com'] = const Player(
        id: 'me',
        name: 'Taqi Ratnani',
        handle: '@taqi',
        level: 2.4,
        tier: 'regular',
        badge: 'Regular',
        avatarColor: Color(0xFFB7F4A1),
        initials: 'TR',
        city: 'Karachi',
        wins: 14,
        games: 26,
        age: 26,
        gender: 'M',
        email: 'taqiratnani@hotmail.com',
        bio: 'Looking for matches · improving game weekly.',
      );
      changed = true;
    }

    if (changed) await _saveRegistry(reg);
  }
}
