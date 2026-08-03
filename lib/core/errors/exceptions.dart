import 'package:dio/dio.dart';
import 'failure.dart';

class ServerFailure extends Failure {
  ServerFailure({required super.errMessage});

  factory ServerFailure.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure(errMessage: 'Connection timeout with ApiServer');
      case DioExceptionType.sendTimeout:
        return ServerFailure(errMessage: 'Send timeout with ApiServer');
      case DioExceptionType.receiveTimeout:
        return ServerFailure(errMessage: 'Receive timeout with ApiServer');
      case DioExceptionType.badCertificate:
        return ServerFailure(errMessage: 'Bad Certificate with ApiServer');
      case DioExceptionType.badResponse:
        return ServerFailure.fromBadResponse(
            dioException.response!.statusCode!, dioException.response!.data);
      case DioExceptionType.cancel:
        return ServerFailure(errMessage: 'Request to ApiServer was canceled');
      case DioExceptionType.connectionError:
        return ServerFailure(errMessage: 'Connection error, Please try again!');
      case DioExceptionType.unknown:
        return ServerFailure(errMessage: 'Unexpected error, Please try again!');
      default:
        return ServerFailure(
            errMessage: dioException.response?.data ??
                'Unexpected error, Please try again!');
    }
  }

  factory ServerFailure.fromBadResponse(int statusCode, dynamic response) {
    // Debug logging
    print('╔══════════════════════════════════════════════════════════════');
    print('║ 🚨 SERVER ERROR - STATUS CODE: $statusCode');
    print('╠══════════════════════════════════════════════════════════════');
    print('║ 📦 RAW RESPONSE:');
    print('║ ${response.toString()}');
    print('╠══════════════════════════════════════════════════════════════');

    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 405 ||
        statusCode == 422) {
      if (response is Map<String, dynamic>) {
        // Handle validation errors (422 case)
        if (response.containsKey('errors') && response['errors'] is Map) {
          final errors = response['errors'] as Map<String, dynamic>;
          print('║ 🔍 VALIDATION ERRORS DETECTED:');
          errors.forEach((key, value) {
            print('║    $key: ${value.join(', ')}');
          });

          // Special handling for password error in Arabic
          if (errors.containsKey('password') &&
              errors['password'] is List &&
              errors['password'].isNotEmpty) {
            final passwordError = errors['password'][0];
            print('╠══════════════════════════════════════════════════════');
            print('║ 🔑 RETURNING PASSWORD ERROR: $passwordError');
            print('╚══════════════════════════════════════════════════════');
            return ServerFailure(errMessage: passwordError);
          }

          // General case for multiple errors
          final errorMessages = errors.entries
              .map((entry) =>
                  '${entry.key}: ${(entry.value as List).join(', ')}')
              .join('\n');
          print('╠══════════════════════════════════════════════════════');
          print('║ 📝 RETURNING ALL VALIDATION ERRORS');
          print('╚══════════════════════════════════════════════════════');
          return ServerFailure(errMessage: errorMessages);
        }

        // Fallback to message if exists
        if (response.containsKey('message')) {
          print('║ 📢 SERVER MESSAGE: ${response['message']}');
          print('╠══════════════════════════════════════════════════════');
          print('║ 📝 RETURNING SERVER MESSAGE');
          print('╚══════════════════════════════════════════════════════');
          return ServerFailure(errMessage: response['message']);
        }

        if (response.containsKey('data') &&
            response['data'] is String &&
            (response['data'] as String).trim().isNotEmpty) {
          print('║ 📢 SERVER DATA MESSAGE: ${response['data']}');
          print('╠══════════════════════════════════════════════════════');
          print('║ 📝 RETURNING SERVER DATA MESSAGE');
          print('╚══════════════════════════════════════════════════════');
          return ServerFailure(errMessage: response['data']);
        }
      }

      print('║ ⚠️ DEFAULT VALIDATION ERROR MESSAGE');
      print('╚══════════════════════════════════════════════════════');
      return ServerFailure(
          errMessage: 'Validation failed. Please check your input.');
    } else if (statusCode == 404) {
      print('║ ❌ 404 NOT FOUND ERROR');
      print('╚══════════════════════════════════════════════════════');
      return ServerFailure(
          errMessage: 'Request not found. Please try again later.');
    } else if (statusCode == 500) {
      print('║ 🚫 500 SERVER ERROR');
      print('╚══════════════════════════════════════════════════════');
      return ServerFailure(
          errMessage: 'Internal server error. Please try again later.');
    } else {
      print('║ ❓ UNKNOWN STATUS CODE: $statusCode');
      print('╚══════════════════════════════════════════════════════');
      return ServerFailure(
          errMessage: 'An unexpected error occurred. Status: $statusCode');
    }
  }
}
