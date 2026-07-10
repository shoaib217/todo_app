import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/exceptions/api_exception.dart';
import 'package:todo_app/core/models/user.dart';
import 'package:todo_app/core/services/todo_api_service.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.read(dioProvider));
});

class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  Future<User> login(String loginId, String password) async {
    try {
      debugPrint('--- Login API Call ---');
      debugPrint('URL: ${_dio.options.baseUrl}/auth/login');
      debugPrint('Payload: {login_id: $loginId}');
      
      final response = await _dio.post(
        '/auth/login',
        data: {
          'login_id': loginId,
          'password': password,
        },
      );
      
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('----------------------');
      
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('--- Login API Error (Dio) ---');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Error Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      debugPrint('----------------------------');
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      debugPrint('--- Login API Error (Unexpected) ---');
      debugPrint('Error: $e');
      debugPrint('-----------------------------------');
      throw ApiException('An unexpected error occurred during login');
    }
  }

  Future<User> signup(User user) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: user.toJson(),
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
      throw ApiException('An unexpected error occurred during signup');
    }
  }
}
