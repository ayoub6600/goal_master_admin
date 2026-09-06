import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/notification/data/model/notification_response.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';

class NotificationRepoImp extends NotificationRepo {
  final ApiConsumer consumer;

  NotificationRepoImp(this.consumer);

  @override
  Future<Either<Failure, NotificationResponse>> getNotifications(int page) {
    return consumer.handleRequest(
      () => consumer.get(
        EndPoints.notification,
        // Excludes this person's Customer-side notifications (e.g. their
        // own booking updates) from the Manager App's list — the backend
        // otherwise returns every notification ever sent to this users.id,
        // Customer and Manager alike, since both apps share one identity.
        queryParameters: {'page': page, 'app_domain': 'manager'},
      ),
      (data) => NotificationResponse.fromJson(data),
    );
  }

  @override
  Future<Either<Failure, String>> markAllNotificationsAsRead() {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.markAllNotificationsAsRead, // تأكد إن ده موجود في end_points
      ),
      (data) => data['message'],
    );
  }

  @override
  Future<Either<Failure, String>> markNotificationAsRead(
      String notificationId) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.markNotificationAsRead(notificationId),
        queryParameters: {'notification_id': notificationId},
      ),
      (data) => data['message'],
    );
  }
}
