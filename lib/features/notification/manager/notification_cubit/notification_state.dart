part of 'notification_cubit.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {}

class NotificationSuccess extends NotificationState {
  final PagingController<int, NotificationItem> pagingController;

  const NotificationSuccess({required this.pagingController});
}

class NotificationFailure extends NotificationState {
  final String message;

  const NotificationFailure({required this.message});
}

class NotificationLoading extends NotificationState {}

class NotificationLoadSuccess extends NotificationState {
  final PagingController<int, NotificationItem> pagingController;
  NotificationLoadSuccess({required this.pagingController});
}

class NotificationLoadFailure extends NotificationState {
  final String message;
  NotificationLoadFailure({required this.message});
}

class NotificationMarkingAsRead extends NotificationState {
  final String notificationId;
  NotificationMarkingAsRead(this.notificationId);
}

class NotificationMarkAsReadSuccess extends NotificationState {
  final String notificationId;
  final String message;
  NotificationMarkAsReadSuccess({
    required this.notificationId,
    required this.message,
  });
}

class NotificationMarkAsReadFailure extends NotificationState {
  final String notificationId;
  final String message;
  NotificationMarkAsReadFailure({
    required this.notificationId,
    required this.message,
  });
}

// حالات جديدة لـ "تعيين كل الإشعارات كمقروءة"
class NotificationMarkingAllAsRead extends NotificationState {}

class NotificationMarkAllAsReadSuccess extends NotificationState {
  final String message;
  NotificationMarkAllAsReadSuccess({required this.message});
}

class NotificationMarkAllAsReadFailure extends NotificationState {
  final String message;
  NotificationMarkAllAsReadFailure({required this.message});
}
