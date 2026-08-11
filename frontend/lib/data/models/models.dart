// Data models for Wiki Roulette
// Plain Dart classes with clean serialization

class ArticleModel {
  final int id;
  final int wikiPageId;
  final String title;
  final String slug;
  final String url;
  final String? description;
  final String? extract;
  final String? thumbnailUrl;
  final String language;
  final int? wordCount;
  final String difficulty;
  final bool quizAvailable;
  final List<CategoryModel> categories;

  const ArticleModel({
    required this.id,
    required this.wikiPageId,
    required this.title,
    required this.slug,
    required this.url,
    this.description,
    this.extract,
    this.thumbnailUrl,
    this.language = 'en',
    this.wordCount,
    required this.difficulty,
    required this.quizAvailable,
    this.categories = const [],
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as int? ?? 0,
        wikiPageId: json['wiki_page_id'] as int? ?? 0,
        title: json['title'] as String? ?? 'Untitled Article',
        slug: json['slug'] as String? ?? '',
        url: json['url'] as String? ?? '',
        description: json['description'] as String?,
        extract: json['extract'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        language: json['language'] as String? ?? 'en',
        wordCount: json['word_count'] as int?,
        difficulty: json['difficulty'] as String? ?? 'medium',
        quizAvailable: json['quiz_available'] as bool? ?? true,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'wiki_page_id': wikiPageId,
        'title': title,
        'slug': slug,
        'url': url,
        'description': description,
        'extract': extract,
        'thumbnail_url': thumbnailUrl,
        'language': language,
        'word_count': wordCount,
        'difficulty': difficulty,
        'quiz_available': quizAvailable,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  String get difficultyLabel =>
      difficulty.isNotEmpty ? difficulty[0].toUpperCase() + difficulty.substring(1) : 'Medium';

  String? get shortExtract {
    if (extract == null) return null;
    final sentences = extract!.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isEmpty) return extract;
    return sentences.take(3).join(' ');
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? iconName;

  const CategoryModel({required this.id, required this.name, this.iconName});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        iconName: json['icon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconName,
      };
}

class QuizQuestionModel {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String difficulty;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correctOption = 'a',
    required this.difficulty,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) => QuizQuestionModel(
        id: json['id'] as int? ?? 0,
        question: json['question'] as String? ?? '',
        optionA: json['option_a'] as String? ?? '',
        optionB: json['option_b'] as String? ?? '',
        optionC: json['option_c'] as String? ?? '',
        optionD: json['option_d'] as String? ?? '',
        correctOption: json['correct_option'] as String? ?? 'a',
        difficulty: json['difficulty'] as String? ?? 'medium',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': correctOption,
        'difficulty': difficulty,
      };

  Map<String, String> get optionsMap => {
        'a': optionA,
        'b': optionB,
        'c': optionC,
        'd': optionD,
      };
}

class GameSessionModel {
  final int sessionId;
  final int articleId;
  final String gameType;
  final List<QuizQuestionModel> questions;
  final DateTime startedAt;

  const GameSessionModel({
    required this.sessionId,
    required this.articleId,
    required this.gameType,
    required this.questions,
    required this.startedAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) => GameSessionModel(
        sessionId: json['session_id'] as int? ?? 0,
        articleId: json['article_id'] as int? ?? 0,
        gameType: json['game_type'] as String? ?? 'roulette',
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
            .toList(),
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AnswerResultModel {
  final bool correct;
  final String correctOption;
  final String? explanation;
  final int scoreDelta;
  final int xpDelta;

  const AnswerResultModel({
    required this.correct,
    required this.correctOption,
    this.explanation,
    required this.scoreDelta,
    required this.xpDelta,
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) => AnswerResultModel(
        correct: json['correct'] as bool? ?? false,
        correctOption: json['correct_option'] as String? ?? 'a',
        explanation: json['explanation'] as String?,
        scoreDelta: json['score_delta'] as int? ?? 0,
        xpDelta: json['xp_delta'] as int? ?? 0,
      );
}

class GameCompleteModel {
  final int sessionId;
  final ScoreBreakdownModel scoreBreakdown;
  final int newStreak;

  const GameCompleteModel({
    required this.sessionId,
    required this.scoreBreakdown,
    required this.newStreak,
  });

  factory GameCompleteModel.fromJson(Map<String, dynamic> json) => GameCompleteModel(
        sessionId: json['session_id'] as int? ?? 0,
        scoreBreakdown: ScoreBreakdownModel.fromJson(
          json['score_breakdown'] as Map<String, dynamic>? ?? {},
        ),
        newStreak: json['new_streak'] as int? ?? 1,
      );
}

class ScoreBreakdownModel {
  final int correctAnswers;
  final int totalQuestions;
  final int baseScore;
  final int speedBonus;
  final int perfectBonus;
  final double dailyMultiplier;
  final int finalScore;
  final int xpEarned;
  final int levelBefore;
  final int levelAfter;
  final bool leveledUp;
  final List<String> newAchievements;

  const ScoreBreakdownModel({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.baseScore,
    required this.speedBonus,
    required this.perfectBonus,
    required this.dailyMultiplier,
    required this.finalScore,
    required this.xpEarned,
    required this.levelBefore,
    required this.levelAfter,
    required this.leveledUp,
    this.newAchievements = const [],
  });

  factory ScoreBreakdownModel.fromJson(Map<String, dynamic> json) => ScoreBreakdownModel(
        correctAnswers: json['correct_answers'] as int? ?? 0,
        totalQuestions: json['total_questions'] as int? ?? 0,
        baseScore: json['base_score'] as int? ?? 0,
        speedBonus: json['speed_bonus'] as int? ?? 0,
        perfectBonus: json['perfect_bonus'] as int? ?? 0,
        dailyMultiplier: (json['daily_multiplier'] as num?)?.toDouble() ?? 1.0,
        finalScore: json['final_score'] as int? ?? 0,
        xpEarned: json['xp_earned'] as int? ?? 0,
        levelBefore: json['level_before'] as int? ?? 1,
        levelAfter: json['level_after'] as int? ?? 1,
        leveledUp: json['leveled_up'] as bool? ?? false,
        newAchievements: (json['new_achievements'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
  bool get isPerfect => correctAnswers == totalQuestions && totalQuestions > 0;
}

class LeaderboardEntryModel {
  final int rank;
  final int userId;
  final String username;
  final String? avatarUrl;
  final int score;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.score,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => LeaderboardEntryModel(
        rank: json['rank'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        username: json['username'] as String? ?? 'Explorer',
        avatarUrl: json['avatar_url'] as String?,
        score: json['score'] as int? ?? 0,
        isCurrentUser: json['is_current_user'] as bool? ?? false,
      );
}

class UserStatsModel {
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalGames;
  final int perfectQuizzes;
  final int articlesRead;
  final int totalScore;

  const UserStatsModel({
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalGames = 0,
    this.perfectQuizzes = 0,
    this.articlesRead = 0,
    this.totalScore = 0,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) => UserStatsModel(
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        totalGames: json['total_games'] as int? ?? 0,
        perfectQuizzes: json['perfect_quizzes'] as int? ?? 0,
        articlesRead: json['articles_read'] as int? ?? 0,
        totalScore: json['total_score'] as int? ?? 0,
      );
}

class AchievementModel {
  final int id;
  final String name;
  final String description;
  final String iconCode;
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCode,
    required this.xpReward,
    required this.unlocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        iconCode: json['icon_code'] as String? ?? 'trophy',
        xpReward: json['xp_reward'] as int? ?? 50,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.tryParse(json['unlocked_at'] as String)
            : null,
      );
}

class UserProfileModel {
  final String name;
  final List<String> interests;
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalGames;
  final int perfectQuizzes;
  final int articlesRead;
  final int totalScore;

  const UserProfileModel({
    required this.name,
    required this.interests,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalGames = 0,
    this.perfectQuizzes = 0,
    this.articlesRead = 0,
    this.totalScore = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
        name: json['name'] as String? ?? 'Explorer',
        interests: (json['interests'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        totalGames: json['total_games'] as int? ?? 0,
        perfectQuizzes: json['perfect_quizzes'] as int? ?? 0,
        articlesRead: json['articles_read'] as int? ?? 0,
        totalScore: json['total_score'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'interests': interests,
        'xp': xp,
        'level': level,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'total_games': totalGames,
        'perfect_quizzes': perfectQuizzes,
        'articles_read': articlesRead,
        'total_score': totalScore,
      };

  UserProfileModel copyWith({
    String? name,
    List<String>? interests,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? totalGames,
    int? perfectQuizzes,
    int? articlesRead,
    int? totalScore,
  }) =>
      UserProfileModel(
        name: name ?? this.name,
        interests: interests ?? this.interests,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalGames: totalGames ?? this.totalGames,
        perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
        articlesRead: articlesRead ?? this.articlesRead,
        totalScore: totalScore ?? this.totalScore,
      );
}
