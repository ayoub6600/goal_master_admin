import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';

/// Whether a notification, by its stable backend id, has already been shown
/// to the user (system tray alert + sound).
///
/// Persisted rather than kept in memory: an in-memory "last id" resets to
/// null on every app restart, so a socket reconnect that redelivers the
/// latest notification right after launch — which is exactly what the app
/// was seen doing — passed straight through as though nothing had ever been
/// shown. This survives the restart.
///
/// Deliberately tracks only the single most recent id, not a growing set:
/// the bug this exists for is the latest notification being replayed on
/// reconnect/restart. An unbounded "seen" list would grow forever for a case
/// this single comparison already covers.
class NotificationDedupStore {
  static const _key = PrefKey.lastShownNotificationId;

  static String? get lastShownId {
    final value = SharedPreferenceUtil.getString(_key);
    return value.isEmpty ? null : value;
  }

  /// True — and records `id` — the first time this id is seen. False, and
  /// nothing recorded, if `id` was already the last one shown.
  ///
  /// An empty id never suppresses: there is nothing to compare it against,
  /// and silently dropping an unidentified notification would hide it
  /// entirely rather than risk one duplicate.
  static bool markIfNew(String id) {
    if (id.isEmpty) return true;
    if (id == lastShownId) return false;

    SharedPreferenceUtil.putString(_key, id);
    return true;
  }
}
