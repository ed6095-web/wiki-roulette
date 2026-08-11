import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../core/network/api_client.dart';

// ── Random Article State ──
enum RouletteStatus { idle, spinning, loaded, error }

class RouletteState {
  final RouletteStatus status;
  final ArticleModel? article;
  final String? error;

  const RouletteState({
    this.status = RouletteStatus.idle,
    this.article,
    this.error,
  });

  RouletteState copyWith({
    RouletteStatus? status,
    ArticleModel? article,
    String? error,
  }) => RouletteState(
        status: status ?? this.status,
        article: article ?? this.article,
        error: error,
      );
}

class RouletteNotifier extends StateNotifier<RouletteState> {
  RouletteNotifier() : super(const RouletteState());

  Future<void> spin() async {
    state = state.copyWith(status: RouletteStatus.spinning, error: null);
    try {
      final data = await ApiClient.instance.getRandomArticle();
      state = RouletteState(
        status: RouletteStatus.loaded,
        article: ArticleModel.fromJson(data),
      );
    } catch (e) {
      state = RouletteState(
        status: RouletteStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const RouletteState();
  }
}

final rouletteProvider = StateNotifierProvider<RouletteNotifier, RouletteState>(
  (_) => RouletteNotifier(),
);

// ── Daily Challenge ──
final dailyChallengeProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    return await ApiClient.instance.getDailyChallenge();
  } catch (_) {
    return null;
  }
});
