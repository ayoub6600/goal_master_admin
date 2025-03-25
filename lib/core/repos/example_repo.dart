import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart' show Failure;

abstract class ExampleRepo {
  Future<Either<Failure, String>> fetchID();
  Future<Either<Failure, List<String>>> fetchIDs();
  Future<Either<Failure, String>> putID(String id);
  Future<Either<Failure, String>> deleteID(String id);
  Future<Either<Failure, void>> postID(String id);
  Future<Either<Failure, String>> uploadSingleFile(File file);
  Future<Either<Failure, void>> uploadMultipleFiles(List<File> files);
}
