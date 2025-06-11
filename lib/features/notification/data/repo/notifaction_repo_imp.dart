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
        queryParameters: {'page': page},
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
}
