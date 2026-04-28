import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import '../models/game.dart';

/// Persists *gameplay* state (hosted games, bookings) to SharedPreferences
/// so it survives app restarts. Keeps the existing `UserStorage` unchanged.
///
/// **Why not Firestore?** Firestore is the source of truth for cross-device
/// sync, but it's slow at cold start (network round-trip) and requires
/// connectivity. Local persistence gives instant boot. The two are
/// reconciled at runtime via the existing listeners.
///
/// All methods catch and log internally; failures return silently. State
/// loading must never break startup.
class StateStorage {
  StateStorage._();

  static const _kHostedGamesKey = 'hosted_games_v1';
  static const _kBookingsKey = 'bookings_v1';

  // ─── Hosted games ──────────────────────────────────────────────────────────

  static Future<void> saveHostedGames(List<Game> games) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final list = games.map((g) => g.toMap()).toList();
      await sp.setString(_kHostedGamesKey, jsonEncode(list));
    } catch (e) {
      debugPrint('StateStorage.saveHostedGames error: $e');
    }
  }

  static Future<List<Game>> loadHostedGames() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kHostedGamesKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => Game.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('StateStorage.loadHostedGames error: $e');
      return const [];
    }
  }

  // ─── Bookings ──────────────────────────────────────────────────────────────

  static Future<void> saveBookings(List<Booking> bookings) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final list = bookings.map((b) => b.toMap()).toList();
      await sp.setString(_kBookingsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('StateStorage.saveBookings error: $e');
    }
  }

  static Future<List<Booking>> loadBookings() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kBookingsKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => Booking.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('StateStorage.loadBookings error: $e');
      return const [];
    }
  }

  static Future<void> clearAll() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kHostedGamesKey);
      await sp.remove(_kBookingsKey);
    } catch (e) {
      debugPrint('StateStorage.clearAll error: $e');
    }
  }
}
