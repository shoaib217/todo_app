import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiUtils {
  static ApiException handleDioError(DioException e) {
    String message = "An unexpected error occurred";
    
    if (e.response != null && e.response?.data is Map) {
      final data = e.response?.data as Map<String, dynamic>;
      // This picks up the {"error": "..."} format from your backend
      message = data['error']?.toString() ?? message;
    } else {
      // Handles network issues (timeout, no internet)
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = "Connection timed out. Please check your internet.";
          break;
        case DioExceptionType.connectionError:
          message = "Cannot reach the server. Make sure it's running.";
          break;
        case DioExceptionType.badResponse:
          message = "Server returned an invalid response.";
          break;
        case DioExceptionType.cancel:
          message = "Request was cancelled.";
          break;
        default:
          message = "Network error occurred (${e.type})";
      }
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
