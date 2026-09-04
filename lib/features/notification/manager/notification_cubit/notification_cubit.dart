import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/utils/notification_dedup_store.dart';
import 'package:goal_master_admin/utils/notification_identity.dart';
import 'package:goal_master_admin/utils/notification_socket_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:equatable/equatable.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo notificationRepo;
  final void Function(NotificationItem)? onVisualNotification;
  final int userId;

  late final PagingController<int, NotificationItem> _pagingController;
  late final NotificationSocketService _socketService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<RemoteMessage>? _fcmForegroundSubscription;

  bool _isDisposed = false;

  PagingController<int, NotificationItem> get pagingController =>
      _pagingController;

  NotificationCubit({
    required this.notificationRepo,
    required this.userId,
    this.onVisualNotification,
  }) : super(NotificationInitial()) {
    _pagingController =
        PagingController<int, NotificationItem>(firstPageKey: 1);
    _pagingController.addPageRequestListener(_fetchPage);

    _socketService = NotificationSocketService(
      userId: userId,
      onNotificationReceived: handleNotificationReceived,
    );

    _fetchPage(1);
    emit(NotificationLoadSuccess(
        pagingController: _pagingController, unreadCount: unreadCount));
    emit(NotificationUnreadUpdated(unreadCount));
  }

  /// A foreground FCM message never auto-displays on Android/iOS the way a
  /// background/terminated one does — the OS hands it to app code instead,
  /// which is exactly why nothing was visibly happening for it before this.
  /// Routed through the same [handleNotificationReceived] gate as the socket
  /// and polling paths, using the same [NotificationIdentity] id derivation,
  /// so a socket delivery and an FCM delivery of the same backend event
  /// collapse into a single alert instead of two. Background/terminated
  /// delivery is untouched — that path never reaches this listener at all.
  void listenForForegroundFcm() {
    if (_isDisposed) return;
    _fcmForegroundSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (_isDisposed) return;
      final data = message.data;
      final body = message.notification?.body ??
          data['message']?.toString() ??
          data['msg']?.toString() ??
          '';
      if (body.isEmpty) return;

      handleNotificationReceived(NotificationItem(
        id: NotificationIdentity.resolve(data),
        type: data['type']?.toString() ?? 'fcm_notification',
        notifiableType: 'fcm',
        notifiableId: userId,
        data: NotificationInnerData(message: body),
        readAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });
  }

  // Nullable rather than `late`: only ever assigned once `startSocket()`
  // runs, and `close()` must be safe to call whether or not it did.
  Timer? _pollingTimer;

  void startSocket() {
    if (_isDisposed) return;
    _socketService.initialize();

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      print('[\u23F1\uFE0F Polling] التحقق من وجود إشعارات جديدة...');
      _checkForNewNotification();
    });
  }

  Future<void> _checkForNewNotification() async {
    if (_isDisposed) return;

    final result = await notificationRepo.getNotifications(1);
    result.fold(
      (failure) => {},
      (response) {
        // No pre-filter here on purpose: `handleNotificationReceived` is the
        // one place — shared with the socket path — that decides both
        // whether the in-app list needs this item and whether it has
        // already been alerted on. Filtering here too was the second of
        // the two places a single event could independently decide to
        // alert, which is how it ended up alerting twice.
        final latest = response.data.data.firstOrNull;
        if (latest != null) {
          handleNotificationReceived(latest);
        }
      },
    );
  }

  /// Called for every notification the socket forwards or a poll turns up
  /// — including a re-delivery of one already seen. Two separate concerns,
  /// deliberately not gated by the same check:
  ///
  ///  - the in-app list/unread count always reflects reality, whether or
  ///    not this particular call is a re-delivery (its own guard below is
  ///    about not duplicating a LIST ENTRY, not about alerting);
  ///  - the actual alert (sound + system notification) is shown at most
  ///    once per backend id, via the one persisted, restart-safe gate.
  ///
  /// Public (not the usual leading underscore) only so a test can exercise
  /// it directly without a live socket connection — not meant to be called
  /// from outside this cubit's own wiring otherwise.
  @visibleForTesting
  Future<void> handleNotificationReceived(NotificationItem notification) async {
    if (_isDisposed) return;

    final current = _pagingController.itemList ?? [];

    if (!current.any((item) => item.id == notification.id)) {
      final updatedList = [notification, ...current];
      _pagingController.itemList = updatedList;

      final newUnreadCount = updatedList
          .where((item) => item.readAt == null || item.readAt!.isEmpty)
          .length;

      emit(NotificationLoadSuccess(
        pagingController: _pagingController,
        unreadCount: newUnreadCount,
      ));

      print('[✅] Updated unreadCount: $newUnreadCount');
    }

    // The one authoritative alert gate. Both the socket path and the
    // polling fallback above funnel through this same method, so there is
    // exactly one place left that can decide to alert.
    if (!NotificationDedupStore.markIfNew(notification.id)) return;

    print('[🔔 إشعار جديد]: ${notification.data.message}');

    try {
      await _audioPlayer.play(
        AssetSource('sound/new-notification-09-352705.mp3'),
      );
    } catch (e) {
      print('[NotificationCubit] فشل تشغيل صوت الإشعار: $e');
    }

    onVisualNotification?.call(notification);
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isDisposed) return;

    try {
      final result = await notificationRepo.getNotifications(pageKey);
      if (_isDisposed) return;

      result.fold(
        (failure) {
          _pagingController.error = failure.errMessage;
          emit(NotificationLoadFailure(message: failure.errMessage));
        },
        (response) {
          final notifications = response.data.data;

          final isLastPage = pageKey >= response.data.lastPage;
          if (isLastPage) {
            _pagingController.appendLastPage(notifications);
          } else {
            _pagingController.appendPage(notifications, pageKey + 1);
          }

          emit(NotificationLoadSuccess(
              pagingController: _pagingController, unreadCount: unreadCount));
          emit(NotificationUnreadUpdated(unreadCount));
        },
      );
    } catch (error) {
      _pagingController.error = error.toString();
      emit(NotificationLoadFailure(message: error.toString()));
    }
  }

  void refresh() {
    if (_isDisposed) return;
    _pagingController.refresh();
    emit(NotificationLoading());
  }

  Future<void> markAllAsRead() async {
    if (_isDisposed) return;

    final currentItems = _pagingController.itemList;
    if (!hasUnreadNotifications()) return;

    emit(NotificationMarkingAllAsRead());

    if (currentItems != null) {
      final updated = currentItems
          .map(
              (item) => item.copyWith(readAt: DateTime.now().toIso8601String()))
          .toList();
      _pagingController.itemList = updated;
    }

    final result = await notificationRepo.markAllNotificationsAsRead();

    if (_isDisposed) return;

    result.fold(
      (failure) =>
          emit(NotificationMarkAllAsReadFailure(message: failure.errMessage)),
      (message) => emit(NotificationMarkAllAsReadSuccess(message: message)),
    );
  }

  int get unreadCount {
    return _pagingController.itemList
            ?.where((item) => item.readAt == null || item.readAt!.isEmpty)
            .length ??
        0;
  }

  bool hasUnreadNotifications() => unreadCount > 0;
  Future<void> markAsRead(String notificationId) async {
    if (_isDisposed) return;

    final currentItems = _pagingController.itemList;
    if (currentItems == null) return;

    final index = currentItems.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;

    final updatedItem =
        currentItems[index].copyWith(readAt: DateTime.now().toIso8601String());
    currentItems[index] = updatedItem;
    _pagingController.itemList = List.from(currentItems);

    final result =
        await notificationRepo.markNotificationAsRead(notificationId);

    result.fold(
      (failure) => print('[❌] فشل تعيين الإشعار كمقروء: ${failure.errMessage}'),
      (message) => print('[✅] الإشعار $notificationId تم تحديثه بنجاح'),
    );

    emit(NotificationUnreadUpdated(unreadCount));
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _socketService.dispose();
    _fcmForegroundSubscription?.cancel();
    _pagingController.dispose();
    _pollingTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
