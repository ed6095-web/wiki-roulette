import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_text_styles.dart';

// ──────────────────────────────────────────────────────
// AUTH STATE
// ──────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) => AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    if (token != null) {
      try {
        final data = await ApiClient.instance.getMe();
        state = AuthState(
          isAuthenticated: true,
          user: UserModel.fromJson(data),
        );
      } catch (_) {
        await _clearCache();
      }
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiClient.instance.register(username, email, password);
      await _saveToken(data['access_token'] as String, data['user_id'] as int, data['username'] as String);
      final userData = await ApiClient.instance.getMe();
      state = AuthState(isAuthenticated: true, user: UserModel.fromJson(userData));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiClient.instance.login(email, password);
      await _saveToken(data['access_token'] as String, data['user_id'] as int, data['username'] as String);
      final userData = await ApiClient.instance.getMe();
      state = AuthState(isAuthenticated: true, user: UserModel.fromJson(userData));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _clearCache();
    state = const AuthState();
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    try {
      final data = await ApiClient.instance.getMe();
      state = state.copyWith(user: UserModel.fromJson(data));
    } catch (_) {}
  }

  Future<void> _saveToken(String token, int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.authTokenKey, token);
    await prefs.setInt(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.usernameKey, username);
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
