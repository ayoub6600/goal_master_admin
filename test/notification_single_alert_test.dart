import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [NotificationSocketService] and the 15s polling fallback both now funnel
/// into `NotificationCubit.handleNotificationReceived` — the one place left
/// that can show an alert. Exercising that method directly is exercising
/// exactly what either path does; the socket used to also decide on its own
/// whether to show something, which is the two-places-decide bug this
/// covers.
class _FakeNotificationRepo implements NotificationRepo {
  @override
  Future<Either<Failure, NotificationResponse>> getNotifications(int page) async {
    return right(NotificationResponse(
      status: true,
      data: NotificationData(
        currentPage: 1,
        data: const [],
        firstPageUrl: null,
        from: 0,
        lastPage: 1,
        lastPageUrl: null,
        links: const [],
        nextPageUrl: null,
        path: '',
        perPage: 10,
        prevPageUrl: null,
        to: 0,
        total: 0,
      ),
    ));
  }

  @override
  Future<Either<Failure, String>> markNotificationAsRead(String id) async =>
      right('ok');

  @override
  Future<Either<Failure, String>> markAllNotificationsAsRead() async =>
      right('ok');
}

NotificationItem _item(String id, {String message = 'حجز جديد'}) =>
    NotificationItem(
      id: id,
      type: 'App\\Notifications\\UserNotification',
      notifiableType: 'user',
      notifiableId: 1,
      data: NotificationInnerData(message: message),
      readAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  // `handleNotificationReceived` plays a sound via `audioplayers`, whose
  // global singleton lazily opens platform channels on its very first use
  // in the whole test run. No platform implementation is registered in a
  // plain unit-test environment, so those channel calls fail — already
  // caught where it's awaited (`try { await _audioPlayer.play(...) } catch`
  // in `handleNotificationReceived`), which is exactly the pre-existing,
  // accepted behavior. Give the plugin a real test binding + mocked
  // channels so that failure happens in a place the cubit's own try/catch
  // can actually see, instead of as an uncaught error from a stream
  // listener that outruns it.
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioChannels = [
    MethodChannel('xyz.luan/audioplayers'),
    MethodChannel('xyz.luan/audioplayers.global'),
  ];
  for (final channel in audioChannels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferenceUtil.getInstance();
  });

  late List<NotificationItem> alerted;
  late NotificationCubit cubit;

  setUp(() {
    alerted = [];
    cubit = NotificationCubit(
      notificationRepo: _FakeNotificationRepo(),
      userId: 1,
      onVisualNotification: alerted.add,
    );
  });

  tearDown(() => cubit.close());

  // `NotificationDedupStore` is backed by the real (mocked-in-memory)
  // `shared_preferences` singleton — persisted on purpose, restart-safe by
  // design — so it carries state between `test()` blocks in this file just
  // like `notification_dedup_store_test.dart` already documents. Every test
  // below therefore uses ids unique to itself, never reusing 'single-X'
  // etc. across two different tests.

  test('1&2. notification X → one alert; processed again → no second alert',
      () async {
    final x = _item('t12-X');

    await cubit.handleNotificationReceived(x); // e.g. via the socket
    await cubit.handleNotificationReceived(x); // e.g. the cubit sees it once more

    expect(alerted.length, 1);
    expect(alerted.single.id, 't12-X');
  });

  test('3. a genuinely new Y after X → one more alert', () async {
    await cubit.handleNotificationReceived(_item('t3-X'));
    await cubit.handleNotificationReceived(_item('t3-Y'));

    expect(alerted.map((n) => n.id), ['t3-X', 't3-Y']);
  });

  test('4. a reconnect replay of X produces zero new alerts', () async {
    final x = _item('t4-X');

    await cubit.handleNotificationReceived(x);
    // Three more "deliveries" of the same id, as a flaky reconnect loop
    // might produce.
    await cubit.handleNotificationReceived(x);
    await cubit.handleNotificationReceived(x);
    await cubit.handleNotificationReceived(x);

    expect(alerted.length, 1);
  });

  test('5. polling turning up an already-shown X does not duplicate it',
      () async {
    final x = _item('t5-X');
    await cubit.handleNotificationReceived(x); // shown once already

    // The polling fallback calls the exact same method with whatever it
    // fetched as "latest" — including, most of the time, the same one.
    await cubit.handleNotificationReceived(x);

    expect(alerted.length, 1);
  });

  test('6. polling turning up a genuinely new Y alerts once', () async {
    await cubit.handleNotificationReceived(_item('t6-X'));
    await cubit.handleNotificationReceived(_item('t6-Y'));

    expect(alerted.length, 2);
  });

  test('identical text, different ids — both still alert', () async {
    await cubit.handleNotificationReceived(
        _item('text-A', message: 'حجز جديد'));
    await cubit.handleNotificationReceived(
        _item('text-B', message: 'حجز جديد'));

    expect(alerted.length, 2);
  });

  test('7. in-app history/unread state updates even for a re-delivery',
      () async {
    final x = _item('t7-X');

    await cubit.handleNotificationReceived(x);
    expect(cubit.pagingController.itemList?.map((n) => n.id), ['t7-X']);
    expect(cubit.unreadCount, 1);

    // Re-delivered — no second alert (case 4/5 above), but the item must
    // still be exactly, correctly present in history, not duplicated and
    // not dropped.
    await cubit.handleNotificationReceived(x);
    expect(cubit.pagingController.itemList?.length, 1);
    expect(cubit.unreadCount, 1);

    await cubit.markAsRead('t7-X');
    expect(cubit.unreadCount, 0);
  });
}
