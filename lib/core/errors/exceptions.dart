import 'package:dio/dio.dart';
import 'failure.dart';

class ServerFailure extends Failure {
  ServerFailure({required super.errMessage});

  factory ServerFailure.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure(errMessage: 'انتهت مهلة الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.');
      case DioExceptionType.sendTimeout:
        return ServerFailure(errMessage: 'انتهت مهلة إرسال الطلب. حاول مرة أخرى.');
      case DioExceptionType.receiveTimeout:
        return ServerFailure(errMessage: 'تأخر رد الخادم. حاول مرة أخرى.');
      case DioExceptionType.badCertificate:
        return ServerFailure(errMessage: 'تعذر التحقق من أمان الاتصال بالخادم.');
      case DioExceptionType.badResponse:
        return ServerFailure.fromBadResponse(
            dioException.response!.statusCode!, dioException.response!.data);
      case DioExceptionType.cancel:
        return ServerFailure(errMessage: 'تم إلغاء الطلب.');
      case DioExceptionType.connectionError:
        return ServerFailure(errMessage: 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.');
      case DioExceptionType.unknown:
        return ServerFailure(errMessage: 'حدث خطأ غير متوقع. حاول مرة أخرى.');
      default:
        return ServerFailure(
            errMessage: dioException.response?.data ??
                'Unexpected error, Please try again!');
    }
  }

  factory ServerFailure.fromBadResponse(int statusCode, dynamic response) {
    // Debug logging

    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 405 ||
        statusCode == 422) {
      if (response is Map<String, dynamic>) {
        // Handle validation errors (422 case)
        if (response.containsKey('errors') && response['errors'] is Map) {
          final errors = response['errors'] as Map<String, dynamic>;

          // Special handling for password error in Arabic
          if (errors.containsKey('password') &&
              errors['password'] is List &&
              errors['password'].isNotEmpty) {
            final passwordError = errors['password'][0];
            return ServerFailure(errMessage: passwordError);
          }

          // General case for multiple errors. The server's sentences only —
          // a raw field key like `phone_number:` in front means nothing to a
          // manager.
          final errorMessages = errors.values
              .map((value) => value is List ? value.join('، ') : '$value')
              .join('\n');
          return ServerFailure(errMessage: errorMessages);
        }

        // Fallback to message if exists
        if (response.containsKey('message')) {
          return ServerFailure(errMessage: response['message']);
        }

        if (response.containsKey('data') &&
            response['data'] is String &&
            (response['data'] as String).trim().isNotEmpty) {
          return ServerFailure(errMessage: response['data']);
        }
      }

      return ServerFailure(
          errMessage: 'تحقق من البيانات المدخلة ثم حاول مرة أخرى.');
    } else if (statusCode == 404) {
      if (response is Map<String, dynamic> &&
          response['message'] is String &&
          (response['message'] as String).trim().isNotEmpty) {
        return ServerFailure(errMessage: response['message'] as String);
      }
      return ServerFailure(
          errMessage: 'لم يتم العثور على الحملة. حدّث القائمة وحاول مجددًا.');
    } else if (statusCode >= 500) {
      // The server's own sentence when it wrote one (e.g. «لم يتم خصم أي
      // مبلغ»), never an exception dump.
      if (response is Map &&
          response['data'] is String &&
          (response['data'] as String).trim().isNotEmpty &&
          !(response['data'] as String).contains('Exception')) {
        return ServerFailure(errMessage: response['data'] as String);
      }
      if (response is Map &&
          response['message'] is String &&
          (response['message'] as String).trim().isNotEmpty &&
          !(response['message'] as String).contains('Exception') &&
          response['message'] != 'Server Error') {
        return ServerFailure(errMessage: response['message'] as String);
      }
      return ServerFailure(
          errMessage: 'حدث خطأ في الخادم. حاول مرة أخرى بعد قليل.');
    } else if (statusCode == 429) {
      return ServerFailure(
          errMessage: 'محاولات كثيرة خلال وقت قصير. انتظر قليلًا ثم حاول مرة أخرى.');
    } else {
      return ServerFailure(
          errMessage: 'حدث خطأ غير متوقع ($statusCode). حاول مرة أخرى.');
    }
  }
}
