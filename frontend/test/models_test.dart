import 'package:flutter_test/flutter_test.dart';
import 'package:wiki_roulette/data/models/models.dart';

void main() {
  group('ArticleModel Tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'wiki_page_id': 51529,
        'title': 'The Great Molasses Flood',
        'slug': 'The_Great_Molasses_Flood',
        'url': 'https://en.wikipedia.org/wiki/Great_Molasses_Flood',
        'description': 'A 1919 industrial disaster in Boston',
        'extract': 'The Great Molasses Flood occurred on January 15, 1919. A large tank burst.',
        'thumbnail_url': 'https://example.com/image.jpg',
        'language': 'en',
        'word_count': 150,
        'difficulty': 'medium',
        'quiz_available': true,
        'categories': [
          {'id': 1, 'name': 'History', 'icon': '📜'}
        ],
      };

      final article = ArticleModel.fromJson(json);

      expect(article.id, 1);
      expect(article.title, 'The Great Molasses Flood');
      expect(article.difficultyLabel, 'Medium');
      expect(article.difficultyEmoji, '🟡');
      expect(article.categories.length, 1);
      expect(article.categories.first.name, 'History');
    });

    test('shortExtract returns first sentences', () {
      const longText = 'Sentence one. Sentence two. Sentence three. Sentence four. Sentence five.';
      const article = ArticleModel(
        id: 1,
        wikiPageId: 100,
        title: 'Test',
        slug: 'Test',
        url: 'https://example.com',
        extract: longText,
        difficulty: 'easy',
        quizAvailable: true,
      );

      final short = article.shortExtract;
      expect(short, contains('Sentence one.'));
      expect(short, contains('Sentence two.'));
      expect(short, contains('Sentence three.'));
      expect(short, isNot(contains('Sentence four.')));
    });
  });

  group('ScoreBreakdownModel Tests', () {
    test('isPerfect returns true when all questions correct', () {
      const breakdown = ScoreBreakdownModel(
        correctAnswers: 5,
        totalQuestions: 5,
        baseScore: 500,
        speedBonus: 100,
        perfectBonus: 200,
        dailyMultiplier: 1.0,
        finalScore: 800,
        xpEarned: 80,
        levelBefore: 1,
        levelAfter: 2,
        leveledUp: true,
        newAchievements: ['Perfect Score'],
      );

      expect(breakdown.isPerfect, true);
      expect(breakdown.accuracy, 1.0);
    });

    test('isPerfect returns false when some answers incorrect', () {
      const breakdown = ScoreBreakdownModel(
        correctAnswers: 3,
        totalQuestions: 5,
        baseScore: 300,
        speedBonus: 50,
        perfectBonus: 0,
        dailyMultiplier: 1.0,
        finalScore: 350,
        xpEarned: 35,
        levelBefore: 1,
        levelAfter: 1,
        leveledUp: false,
        newAchievements: [],
      );

      expect(breakdown.isPerfect, false);
      expect(breakdown.accuracy, 0.6);
    });
  });

  group('QuizQuestionModel Tests', () {
    test('optionsMap correctly maps keys', () {
      const q = QuizQuestionModel(
        id: 1,
        question: 'What year did Einstein die?',
        optionA: '1945',
        optionB: '1955',
        optionC: '1965',
        optionD: '1975',
        difficulty: 'easy',
      );

      expect(q.optionsMap['a'], '1945');
      expect(q.optionsMap['b'], '1955');
      expect(q.optionsMap['c'], '1965');
      expect(q.optionsMap['d'], '1975');
    });
  });
}
