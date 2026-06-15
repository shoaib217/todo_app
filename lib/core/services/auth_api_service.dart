import 'package:dio/dio.dart';
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
      final response = await _dio.post(
        '/auth/login',
        data: {
          'login_id': loginId,
          'password': password,
        },
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiUtils.handleDioError(e);
    } catch (e) {
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
