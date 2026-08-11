import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_text_styles.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;

  // ── Auth ──
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final resp = await _dio.post('/auth/register', data: {
      'username': username, 'email': email, 'password': password,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('/auth/me');
    return resp.data as Map<String, dynamic>;
  }

  // ── Articles ──
  Future<Map<String, dynamic>> getRandomArticle() async {
    final resp = await _dio.get('/articles/random');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getArticle(int id) async {
    final resp = await _dio.get('/articles/$id');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> searchArticles(String query) async {
    final resp = await _dio.get('/articles/search', queryParameters: {'q': query});
    return resp.data as List<dynamic>;
  }

  // ── Games ──
  Future<Map<String, dynamic>> startGame(int articleId, {String gameType = 'roulette', bool isDaily = false}) async {
    final resp = await _dio.post('/games/start', data: {
      'article_id': articleId, 'game_type': gameType, 'is_daily': isDaily,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAnswer(int sessionId, int questionId, String selectedOption, int responseTimeMs) async {
    final resp = await _dio.post('/games/$sessionId/answer', data: {
      'question_id': questionId,
      'selected_option': selectedOption,
      'response_time_ms': responseTimeMs,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeGame(int sessionId) async {
    final resp = await _dio.post('/games/$sessionId/complete');
    return resp.data as Map<String, dynamic>;
  }

  // ── Profile ──
  Future<Map<String, dynamic>> getStats() async {
    final resp = await _dio.get('/profile/stats');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final resp = await _dio.get('/profile/history', queryParameters: {'page': page});
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAchievements() async {
    final resp = await _dio.get('/profile/achievements');
    return resp.data as List<dynamic>;
  }

  // ── Leaderboard ──
  Future<Map<String, dynamic>> getLeaderboard(String period) async {
    final resp = await _dio.get('/leaderboard', queryParameters: {'period': period});
    return resp.data as Map<String, dynamic>;
  }

  // ── Daily ──
  Future<Map<String, dynamic>> getDailyChallenge() async {
    final resp = await _dio.get('/daily');
    return resp.data as Map<String, dynamic>;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Transform all errors into friendly messages
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    String message;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please try again.';
    } else if (statusCode == 401) {
      message = 'Session expired. Please log in again.';
    } else if (statusCode == 422) {
      message = data?['detail'] ?? 'Invalid request.';
    } else if (statusCode == 503) {
      message = 'Wikipedia is being Wikipedia 😅 — try again in a moment.';
    } else {
      message = data?['detail'] ?? 'Something went wrong. Please try again.';
    }

    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
    ));
  }
}
