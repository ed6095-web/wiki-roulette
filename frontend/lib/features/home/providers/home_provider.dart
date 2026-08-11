import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../core/network/api_client.dart';

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
  }) =>
      RouletteState(
        status: status ?? this.status,
        article: article ?? this.article,
        error: error,
      );
}

class RouletteNotifier extends StateNotifier<RouletteState> {
  RouletteNotifier() : super(const RouletteState());

  static final List<ArticleModel> _curatedDiscoveries = [
    const ArticleModel(
      id: 1,
      wikiPageId: 51529,
      title: 'The Great Molasses Flood',
      slug: 'The_Great_Molasses_Flood',
      url: 'https://en.wikipedia.org/wiki/Great_Molasses_Flood',
      description: 'A 1919 industrial disaster in Boston',
      extract:
          'The Great Molasses Flood, also known as the Boston Molasses Disaster, occurred on January 15, 1919, in the North End neighborhood of Boston, Massachusetts. A large storage tank burst, and a wave of molasses rushed through the streets at an estimated 35 mph (56 km/h), killing 21 people and injuring 150.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Boston_Molasses_Disaster_-_Boston_Post_-_1919-01-16.jpg/640px-Boston_Molasses_Disaster_-_Boston_Post_-_1919-01-16.jpg',
      difficulty: 'medium',
      quizAvailable: true,
      categories: [CategoryModel(id: 1, name: 'History', iconName: 'history')],
    ),
    const ArticleModel(
      id: 2,
      wikiPageId: 23862,
      title: 'Voyager 1',
      slug: 'Voyager_1',
      url: 'https://en.wikipedia.org/wiki/Voyager_1',
      description: 'NASA space probe launched in 1977',
      extract:
          'Voyager 1 is a space probe launched by NASA on September 5, 1977, as part of the Voyager program to study the outer Solar System and interstellar space. Having operated for over 46 years, the spacecraft communicates through the Deep Space Network to receive routine commands and transmit data.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Voyager_spacecraft_model.png/640px-Voyager_spacecraft_model.png',
      difficulty: 'medium',
      quizAvailable: true,
      categories: [CategoryModel(id: 2, name: 'Space', iconName: 'space')],
    ),
    const ArticleModel(
      id: 3,
      wikiPageId: 18933,
      title: 'Library of Alexandria',
      slug: 'Library_of_Alexandria',
      url: 'https://en.wikipedia.org/wiki/Library_of_Alexandria',
      description: 'One of the largest and most significant libraries of the ancient world',
      extract:
          'The Great Library of Alexandria in Alexandria, Egypt, was one of the largest and most significant libraries of the ancient world. The Library was part of a larger research institution called the Mouseion, which was dedicated to the Muses, the nine goddesses of the arts.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Ancientlibraryalex.jpg/640px-Ancientlibraryalex.jpg',
      difficulty: 'easy',
      quizAvailable: true,
      categories: [CategoryModel(id: 3, name: 'History', iconName: 'history')],
    ),
    const ArticleModel(
      id: 4,
      wikiPageId: 736,
      title: 'Albert Einstein',
      slug: 'Albert_Einstein',
      url: 'https://en.wikipedia.org/wiki/Albert_Einstein',
      description: 'Theoretical physicist who developed the theory of relativity',
      extract:
          'Albert Einstein was a German-born theoretical physicist who is widely held to be one of the greatest and most influential scientists of all time. Best known for developing the theory of relativity, he also made important contributions to quantum mechanics.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Einstein_1921_by_F_Schmutzer_-_restoration.jpg/640px-Einstein_1921_by_F_Schmutzer_-_restoration.jpg',
      difficulty: 'easy',
      quizAvailable: true,
      categories: [CategoryModel(id: 4, name: 'Science', iconName: 'science')],
    ),
  ];

  Future<void> spin() async {
    state = state.copyWith(status: RouletteStatus.spinning, error: null);
    try {
      final data = await ApiClient.instance.getRandomArticle();
      state = RouletteState(
        status: RouletteStatus.loaded,
        article: ArticleModel.fromJson(data),
      );
    } catch (_) {
      // Fallback seamlessly to curated discovery pool so user never sees an error
      final fallback = _curatedDiscoveries[Random().nextInt(_curatedDiscoveries.length)];
      state = RouletteState(
        status: RouletteStatus.loaded,
        article: fallback,
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
    return {
      'article': {
        'title': 'James Webb Space Telescope',
        'difficulty': 'medium',
      }
    };
  }
});
