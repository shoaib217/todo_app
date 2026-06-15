import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/models/user.dart';
import 'package:todo_app/core/services/auth_api_service.dart';

final authProvider = StateNotifierProvider<AuthService, User?>((ref) {
  return AuthService(ref.read(authApiServiceProvider));
});

class AuthService extends StateNotifier<User?> {
  AuthService(this._apiService) : super(null) {
    _loadUser();
  }

  final AuthApiService _apiService;
  static const _userKey = 'logged_in_user';

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        state = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_userKey);
      }
    }
  }

  Future<void> login(String loginId, String password) async {
    try {
      final user = await _apiService.login(loginId, password);
      state = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup(User user) async {
    try {
      await _apiService.signup(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
