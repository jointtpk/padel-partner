import 'game.dart';

/// Helpers for reasoning about a [Game]'s scheduled start time.
///
/// Games store their start as two strings: a relative day (`'Today'`,
/// `'Tomorrow'`, `'Saturday'`, …) and a 12-hour clock time (`'6:30 PM'`).
/// This file converts that pair to an absolute [DateTime] so we can answer
/// questions like "has this game already started?" — used to gate joining
/// past-time games.
class GameTime {
  GameTime._();

  static final RegExp _timeRe =
      RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*$');

  static const _weekdayIndex = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };

  /// Parses [game.when] + [game.time] into the next occurring [DateTime].
  /// Returns null if either field can't be understood.
  ///
  /// Day resolution rules:
  ///   - 'Today'  → today's date
  ///   - 'Tomorrow' / 'Tmrw' → today + 1
  ///   - Day name (e.g. 'Saturday') → the *next* future occurrence. If today
  ///     is Saturday and the time is still in the future, today is used;
  ///     otherwise the following Saturday.
  static DateTime? resolve(Game game) {
    final m = _timeRe.firstMatch(game.time);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final period = m.group(3)!.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final whenLower = game.when.trim().toLowerCase();
    DateTime? day;
    if (whenLower == 'today') {
      day = today;
    } else if (whenLower == 'tomorrow' || whenLower == 'tmrw') {
      day = today.add(const Duration(days: 1));
    } else if (_weekdayIndex.containsKey(whenLower)) {
      final target = _weekdayIndex[whenLower]!;
      var diff = (target - now.weekday) % 7;
      if (diff < 0) diff += 7;
      // If today matches the target weekday, keep today only if the start
      // time is still ahead of now; otherwise jump a week forward.
      if (diff == 0) {
        final candidate = today.add(Duration(hours: hour, minutes: minute));
        if (!candidate.isAfter(now)) diff = 7;
      }
      day = today.add(Duration(days: diff));
    }
    if (day == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// True if the game's start time has already passed.
  static bool hasStarted(Game game) {
    final start = resolve(game);
    if (start == null) return false;
    return !start.isAfter(DateTime.now());
  }
}
