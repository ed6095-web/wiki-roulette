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
}

class QuizQuestionModel {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String difficulty;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.difficulty,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) => QuizQuestionModel(
        id: json['id'] as int? ?? 0,
        question: json['question'] as String? ?? '',
        optionA: json['option_a'] as String? ?? '',
        optionB: json['option_b'] as String? ?? '',
        optionC: json['option_c'] as String? ?? '',
        optionD: json['option_d'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? 'medium',
      );

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
        newAchievements: (json['new_achievements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  bool get isPerfect => totalQuestions > 0 && correctAnswers == totalQuestions;
  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
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
        scoreBreakdown: json['score_breakdown'] != null
            ? ScoreBreakdownModel.fromJson(json['score_breakdown'] as Map<String, dynamic>)
            : const ScoreBreakdownModel(
                correctAnswers: 0,
                totalQuestions: 0,
                baseScore: 0,
                speedBonus: 0,
                perfectBonus: 0,
                dailyMultiplier: 1.0,
                finalScore: 0,
                xpEarned: 0,
                levelBefore: 1,
                levelAfter: 1,
                leveledUp: false,
              ),
        newStreak: json['new_streak'] as int? ?? 0,
      );
}

class UserProfileModel {
  final String name;
  final List<String> interests;
  final int xp;
  final int level;
  final int totalGames;
  final int totalScore;
  final int currentStreak;
  final int longestStreak;
  final int perfectQuizzes;
  final int articlesRead;

  const UserProfileModel({
    required this.name,
    this.interests = const [],
    this.xp = 0,
    this.level = 1,
    this.totalGames = 0,
    this.totalScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.perfectQuizzes = 0,
    this.articlesRead = 0,
  });

  UserProfileModel copyWith({
    String? name,
    List<String>? interests,
    int? xp,
    int? level,
    int? totalGames,
    int? totalScore,
    int? currentStreak,
    int? longestStreak,
    int? perfectQuizzes,
    int? articlesRead,
  }) =>
      UserProfileModel(
        name: name ?? this.name,
        interests: interests ?? this.interests,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        totalGames: totalGames ?? this.totalGames,
        totalScore: totalScore ?? this.totalScore,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        perfectQuizzes: perfectQuizzes ?? this.perfectQuizzes,
        articlesRead: articlesRead ?? this.articlesRead,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'interests': interests,
        'xp': xp,
        'level': level,
        'totalGames': totalGames,
        'totalScore': totalScore,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'perfectQuizzes': perfectQuizzes,
        'articlesRead': articlesRead,
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
        name: json['name'] as String? ?? 'Explorer',
        interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const [],
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        totalGames: json['totalGames'] as int? ?? 0,
        totalScore: json['totalScore'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        perfectQuizzes: json['perfectQuizzes'] as int? ?? 0,
        articlesRead: json['articlesRead'] as int? ?? 0,
      );
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
    required this.isCurrentUser,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => LeaderboardEntryModel(
        rank: json['rank'] as int? ?? 1,
        userId: json['user_id'] as int? ?? 0,
        username: json['username'] as String? ?? 'Explorer',
        avatarUrl: json['avatar_url'] as String?,
        score: json['score'] as int? ?? 0,
        isCurrentUser: json['is_current_user'] as bool? ?? false,
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
        iconCode: json['icon'] as String? ?? 'trophy',
        xpReward: json['xp_reward'] as int? ?? 50,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.tryParse(json['unlocked_at'] as String)
            : null,
      );
}
