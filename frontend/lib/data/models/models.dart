// Data models for the app
// Using plain Dart classes (no code generation required for MVP)

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
        id: json['id'] as int,
        wikiPageId: json['wiki_page_id'] as int,
        title: json['title'] as String,
        slug: json['slug'] as String,
        url: json['url'] as String,
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

  String get difficultyLabel => difficulty[0].toUpperCase() + difficulty.substring(1);

  String get difficultyEmoji {
    switch (difficulty) {
      case 'easy': return '🟢';
      case 'medium': return '🟡';
      case 'hard': return '🔴';
      default: return '🟡';
    }
  }

  String? get shortExtract {
    if (extract == null) return null;
    final sentences = extract!.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isEmpty) return extract;
    // Return first 3 sentences
    return sentences.take(3).join(' ');
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? icon;

  const CategoryModel({required this.id, required this.name, this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String?,
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
        id: json['id'] as int,
        question: json['question'] as String,
        optionA: json['option_a'] as String,
        optionB: json['option_b'] as String,
        optionC: json['option_c'] as String,
        optionD: json['option_d'] as String,
        difficulty: json['difficulty'] as String? ?? 'medium',
      );

  Map<String, String> get optionsMap => {
        'a': optionA, 'b': optionB, 'c': optionC, 'd': optionD,
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
        sessionId: json['session_id'] as int,
        articleId: json['article_id'] as int,
        gameType: json['game_type'] as String,
        questions: (json['questions'] as List<dynamic>)
            .map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
            .toList(),
        startedAt: DateTime.parse(json['started_at'] as String),
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
        correct: json['correct'] as bool,
        correctOption: json['correct_option'] as String,
        explanation: json['explanation'] as String?,
        scoreDelta: json['score_delta'] as int,
        xpDelta: json['xp_delta'] as int,
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
    required this.newAchievements,
  });

  factory ScoreBreakdownModel.fromJson(Map<String, dynamic> json) => ScoreBreakdownModel(
        correctAnswers: json['correct_answers'] as int,
        totalQuestions: json['total_questions'] as int,
        baseScore: json['base_score'] as int,
        speedBonus: json['speed_bonus'] as int,
        perfectBonus: json['perfect_bonus'] as int,
        dailyMultiplier: (json['daily_multiplier'] as num).toDouble(),
        finalScore: json['final_score'] as int,
        xpEarned: json['xp_earned'] as int,
        levelBefore: json['level_before'] as int,
        levelAfter: json['level_after'] as int,
        leveledUp: json['leveled_up'] as bool,
        newAchievements: (json['new_achievements'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  bool get isPerfect => correctAnswers == totalQuestions;
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
        sessionId: json['session_id'] as int,
        scoreBreakdown: ScoreBreakdownModel.fromJson(
            json['score_breakdown'] as Map<String, dynamic>),
        newStreak: json['new_streak'] as int,
      );
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int totalGames;
  final int totalScore;
  final int currentStreak;
  final int longestStreak;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.xp,
    required this.level,
    required this.totalGames,
    required this.totalScore,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        totalGames: json['total_games'] as int? ?? 0,
        totalScore: json['total_score'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
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
        rank: json['rank'] as int,
        userId: json['user_id'] as int,
        username: json['username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        score: json['score'] as int,
        isCurrentUser: json['is_current_user'] as bool? ?? false,
      );
}

class AchievementModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.unlocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        xpReward: json['xp_reward'] as int,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.parse(json['unlocked_at'] as String)
            : null,
      );
}
