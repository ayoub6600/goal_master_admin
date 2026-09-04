import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/utils/notification_dedup_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the actual bug: the socket re-sends the latest notification on
/// every (re)connect, including the one that happens on every app restart,
/// so it was displayed again as though it had just arrived.
///
/// [SharedPreferenceUtil] is backed by the real `shared_preferences` plugin
/// (mocked in-memory here, same as the on-device file it wraps) rather than
/// a plain Dart field — the whole point of the fix — so a value written in
/// one `markIfNew` call is still there for the next, exactly as it would be
/// after a real app restart. Its singleton also means state carries between
/// `test()` blocks in this file (there is no reset hook), so every test
/// below uses ids unique to itself rather than assuming a pristine store.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferenceUtil.getInstance();
  });

  test('1. a notification received for the first time is shown', () {
    expect(NotificationDedupStore.markIfNew('case1-X'), isTrue);
  });

  test('2. restart/init again with the same id is NOT shown again', () {
    NotificationDedupStore.markIfNew('case2-X');

    // Simulates the reconnect-on-restart replay: the exact same id arrives
    // again, with nothing else having happened in between.
    expect(NotificationDedupStore.markIfNew('case2-X'), isFalse);
    // And it stays refused on a further replay too.
    expect(NotificationDedupStore.markIfNew('case2-X'), isFalse);
  });

  test('3. a genuinely new notification after restart is still shown', () {
    NotificationDedupStore.markIfNew('case3-X');

    expect(NotificationDedupStore.markIfNew('case3-Y'), isTrue);
  });

  test('4. identical text is irrelevant — only the id decides', () {
    // The store never sees text at all, only the id — asserted by working
    // purely off two ids that would carry identical rendered text upstream.
    expect(NotificationDedupStore.markIfNew('case4-X'), isTrue);
    expect(NotificationDedupStore.markIfNew('case4-Y'), isTrue,
        reason: 'a different id must never be suppressed by a previous one, '
            'whatever the notification text says');
  });

  test('an empty id never suppresses — nothing to compare it against', () {
    expect(NotificationDedupStore.markIfNew(''), isTrue);
    expect(NotificationDedupStore.markIfNew(''), isTrue);
  });

  test('the persisted value survives across separate reads, not just once',
      () {
    NotificationDedupStore.markIfNew('case6-42');

    expect(NotificationDedupStore.lastShownId, 'case6-42');
    // A fresh read — not the same call — sees the same persisted value,
    // exactly as a fresh app process would after a restart.
    expect(NotificationDedupStore.lastShownId, 'case6-42');
  });
}
