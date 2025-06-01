import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo notificationRepo;
  late final PagingController<int, NotificationItem> _pagingController;
  bool _isDisposed = false;

  PagingController<int, NotificationItem> get pagingController =>
      _pagingController;

  NotificationCubit({required this.notificationRepo})
      : super(NotificationInitial()) {
    _pagingController =
        PagingController<int, NotificationItem>(firstPageKey: 1);
    _pagingController.addPageRequestListener(_fetchPage);
    emit(NotificationLoadSuccess(pagingController: _pagingController));
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isDisposed) return;

    try {
      final result = await notificationRepo.getNotifications(pageKey);
      if (_isDisposed) return;

      result.fold(
        (failure) {
          if (_isDisposed) return;
          _pagingController.error = failure.errMessage;
          emit(NotificationLoadFailure(message: failure.errMessage));
        },
        (response) {
          if (_isDisposed) return;
          final notifications = response.data.data;
          final isLastPage = pageKey >= response.data.lastPage;

          if (isLastPage) {
            _pagingController.appendLastPage(notifications);
          } else {
            _pagingController.appendPage(notifications, pageKey + 1);
          }
          emit(NotificationLoadSuccess(pagingController: _pagingController));
        },
      );
    } catch (error) {
      if (_isDisposed) return;
      _pagingController.error = error.toString();
      emit(NotificationLoadFailure(message: error.toString()));
    }
  }

  void refresh() {
    if (_isDisposed) return;
    _pagingController.refresh();
    emit(NotificationLoading());
  }

  Future<void> markAsRead(String notificationId) async {
    if (_isDisposed) return;

    // تحديث محلي فوري لتجربة مستخدم أفضل
    _updateNotificationLocally(notificationId, isRead: true);
    emit(NotificationMarkingAsRead(notificationId));

    final result =
        await notificationRepo.markNotificationAsRead(notificationId);

    if (_isDisposed) return;

    result.fold(
      (failure) {
        // التراجع عن التغيير إذا فشل الطلب
        _updateNotificationLocally(notificationId, isRead: false);
        emit(NotificationMarkAsReadFailure(
          notificationId: notificationId,
          message: failure.errMessage,
        ));
      },
      (message) {
        emit(NotificationMarkAsReadSuccess(
          notificationId: notificationId,
          message: message,
        ));
      },
    );
  }

  void _updateNotificationLocally(String notificationId,
      {required bool isRead}) {
    final currentItems = _pagingController.itemList;
    if (currentItems == null) return;

    final index = currentItems.indexWhere((item) => item.id == notificationId);
    if (index != -1) {
      final updatedItem = currentItems[index]
          .copyWith(readAt: isRead ? DateTime.now().toIso8601String() : null);
      final newItems = List<NotificationItem>.from(currentItems)
        ..[index] = updatedItem;
      _pagingController.itemList = newItems;
    }
  }

  Future<void> markAllAsRead() async {
    if (_isDisposed) return;

    emit(NotificationMarkingAllAsRead());

    // تحديث محلي فوري لكل الإشعارات في القائمة كـ "مقروءة"
    final currentItems = _pagingController.itemList;
    if (currentItems != null) {
      final updatedItems = currentItems
          .map(
              (item) => item.copyWith(readAt: DateTime.now().toIso8601String()))
          .toList();
      _pagingController.itemList = updatedItems;
    }

    final result = await notificationRepo.markAllNotificationsAsRead();

    if (_isDisposed) return;

    result.fold(
      (failure) {
        emit(NotificationMarkAllAsReadFailure(message: failure.errMessage));
      },
      (message) {
        emit(NotificationMarkAllAsReadSuccess(message: message));
      },
    );
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _pagingController.dispose();
    return super.close();
  }
}
