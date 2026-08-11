import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_text_styles.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  late final Dio _wikiDirectDio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _wikiDirectDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'WikiRouletteApp/1.2.0 (contact@wikiroulette.app) MobileApp',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor());
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;

  // ── Auth ──
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final resp = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
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
    try {
      final resp = await _dio.get('/articles/random');
      return resp.data as Map<String, dynamic>;
    } catch (_) {
      // Direct Wikimedia REST random fallback
      final wikiResp = await _wikiDirectDio.get(
        'https://en.wikipedia.org/api/rest_v1/page/random/summary',
      );
      final data = wikiResp.data as Map<String, dynamic>;
      return {
        'id': data['pageid'] ?? 1001,
        'wiki_page_id': data['pageid'] ?? 1001,
        'title': data['title'] ?? 'Wikipedia Article',
        'slug': data['title']?.toString().replaceAll(' ', '_') ?? '',
        'url': data['content_urls']?['desktop']?['page'] ?? 'https://en.wikipedia.org',
        'description': data['description'],
        'extract': data['extract'],
        'thumbnail_url': null,
        'difficulty': 'medium',
        'quiz_available': true,
        'categories': [
          {'id': 1, 'name': 'Knowledge', 'icon': 'explore'}
        ],
      };
    }
  }

  Future<Map<String, dynamic>> getArticle(int id) async {
    final resp = await _dio.get('/articles/$id');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getArticleByTitle(String title) async {
    try {
      final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final wikiResp = await _wikiDirectDio.get(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );
      final data = wikiResp.data as Map<String, dynamic>;
      return {
        'id': data['pageid'] ?? 1002,
        'wiki_page_id': data['pageid'] ?? 1002,
        'title': data['title'] ?? title,
        'slug': encoded,
        'url': data['content_urls']?['desktop']?['page'] ?? 'https://en.wikipedia.org',
        'description': data['description'],
        'extract': data['extract'],
        'thumbnail_url': null,
        'difficulty': 'medium',
        'quiz_available': true,
        'categories': [
          {'id': 1, 'name': 'Knowledge', 'icon': 'explore'}
        ],
      };
    } catch (_) {
      return {
        'id': 1002,
        'wiki_page_id': 1002,
        'title': title,
        'slug': title.replaceAll(' ', '_'),
        'url': 'https://en.wikipedia.org/wiki/${title.replaceAll(' ', '_')}',
        'description': 'Wikipedia article exploring $title',
        'extract':
            '$title is a notable subject documented in global encyclopedias, containing key historical and scientific insights.',
        'thumbnail_url': null,
        'difficulty': 'medium',
        'quiz_available': true,
        'categories': [
          {'id': 1, 'name': 'Knowledge', 'icon': 'explore'}
        ],
      };
    }
  }

  Future<List<dynamic>> searchArticles(String query) async {
    try {
      final resp = await _dio.get('/articles/search', queryParameters: {'q': query});
      if (resp.data is List && (resp.data as List).isNotEmpty) {
        return resp.data as List<dynamic>;
      }
    } catch (_) {}

    // Direct Wikipedia OpenSearch fallback
    try {
      final wikiResp = await _wikiDirectDio.get(
        'https://en.wikipedia.org/w/api.php',
        queryParameters: {
          'action': 'opensearch',
          'search': query,
          'limit': '15',
          'namespace': '0',
          'format': 'json',
        },
      );
      final data = wikiResp.data;
      if (data is List && data.length >= 4) {
        final titles = data[1] as List<dynamic>? ?? [];
        final descriptions = data[2] as List<dynamic>? ?? [];
        final urls = data[3] as List<dynamic>? ?? [];

        final results = <Map<String, dynamic>>[];
        for (int i = 0; i < titles.length; i++) {
          results.add({
            'wiki_page_id': 0,
            'title': titles[i].toString(),
            'description': i < descriptions.length ? descriptions[i].toString() : null,
            'thumbnail_url': null,
            'url': i < urls.length ? urls[i].toString() : '',
          });
        }
        return results;
      }
    } catch (_) {}

    return [];
  }

  // ── Games ──
  Future<Map<String, dynamic>> startGame(int articleId,
      {String gameType = 'roulette', bool isDaily = false}) async {
    final resp = await _dio.post('/games/start', data: {
      'article_id': articleId,
      'game_type': gameType,
      'is_daily': isDaily,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAnswer(
      int sessionId, int questionId, String selectedOption, int responseTimeMs) async {
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
