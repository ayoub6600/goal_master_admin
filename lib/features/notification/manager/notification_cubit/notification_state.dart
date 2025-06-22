part of 'notification_cubit.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoadSuccess extends NotificationState {
  final PagingController<int, NotificationItem> pagingController;
  const NotificationLoadSuccess({required this.pagingController});
}

class NotificationLoadFailure extends NotificationState {
  final String message;
  const NotificationLoadFailure({required this.message});
}

class NotificationMarkingAllAsRead extends NotificationState {}

class NotificationMarkAllAsReadSuccess extends NotificationState {
  final String message;
  const NotificationMarkAllAsReadSuccess({required this.message});
}

class NotificationMarkAllAsReadFailure extends NotificationState {
  final String message;
  const NotificationMarkAllAsReadFailure({required this.message});
}

class NotificationRealtimeReceived extends NotificationState {
  final NotificationItem notification;
  const NotificationRealtimeReceived(this.notification);
}
