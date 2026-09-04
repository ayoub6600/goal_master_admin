import 'dart:convert';

import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';

/// Whether a notification, by its stable id, has already been shown to the
/// user (system tray alert + sound).
///
/// Persisted rather than kept in memory: an in-memory "seen" set resets to
/// empty on every app restart, so a socket reconnect that redelivers the
/// latest notification right after launch — which is exactly what the app
/// was seen doing — passed straight through as though nothing had ever been
/// shown. This survives the restart.
///
/// Tracks a small bounded set of recent ids, not just the single latest one:
/// once the same event can arrive through either the socket or FCM (see
/// NotificationIdentity), a single-slot "last id" is no longer enough — a
/// second, unrelated event arriving between the two channels' copies of the
/// first would overwrite that one slot, and the later-arriving copy would
/// wrongly look new again. A handful of recent ids is enough to cover the
/// realistic gap between two delivery channels for the same event without
/// growing unbounded.
class NotificationDedupStore {
  static const _key = PrefKey.lastShownNotificationId;
  static const _maxTracked = 30;

  static List<String> _readRecent() {
    final raw = SharedPreferenceUtil.getString(_key);
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      // Pre-upgrade format was a single bare id string, not JSON — treat it
      // as the one already-seen id rather than losing it.
      return [raw];
    }
    return [];
  }

  static String? get lastShownId {
    final recent = _readRecent();
    return recent.isEmpty ? null : recent.last;
  }

  /// True — and records `id` — the first time this id is seen. False, and
  /// nothing recorded, if `id` is already among the recently-shown ones.
  ///
  /// An empty id never suppresses: there is nothing to compare it against,
  /// and silently dropping an unidentified notification would hide it
  /// entirely rather than risk one duplicate.
  static bool markIfNew(String id) {
    if (id.isEmpty) return true;

    final recent = _readRecent();
    if (recent.contains(id)) return false;

    recent.add(id);
    final overflow = recent.length - _maxTracked;
    if (overflow > 0) {
      recent.removeRange(0, overflow);
    }
    SharedPreferenceUtil.putString(_key, jsonEncode(recent));
    return true;
  }
}
