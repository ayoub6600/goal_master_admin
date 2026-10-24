import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';

class ManagerMarketingCampaignRepo {
  ManagerMarketingCampaignRepo(this.consumer);

  final ApiConsumer consumer;

  Future<Either<Failure, Map<String, dynamic>>> index() =>
      consumer.handleRequest(
        () => consumer.get(EndPoints.managerMarketingCampaigns),
        (response) => Map<String, dynamic>.from(response['data'] as Map),
      );

  Future<Either<Failure, String>> create(Map<String, dynamic> data) =>
      consumer.handleRequest(
        () => consumer.post(EndPoints.managerMarketingCampaigns, data: data),
        (response) => response['message']?.toString() ?? 'تم حفظ العرض.',
      );

  Future<Either<Failure, String>> toggle(int id) => consumer.handleRequest(
        () => consumer.post(EndPoints.managerMarketingCampaignToggle(id)),
        (response) => response['message']?.toString() ?? 'تم تحديث حالة العرض.',
      );
}
