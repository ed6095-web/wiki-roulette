import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/datasets/curated_articles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final ArticleModel article;
  const QuizScreen({super.key, required this.article});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _elapsed = 0;
  int _questionStartTime = 0;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _showingFeedback = false;
  late List<QuizQuestionModel> _questions;
  final Map<int, bool> _results = {};
  final List<int> _responseTimes = [];
  late AnimationController _feedbackCtrl;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(vsync: this, duration: 400.ms);
    _questions = CuratedArticleDataset.getQuestionsForArticle(
      widget.article.id,
      widget.article.title,
      widget.article.extract ?? '',
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _timer?.cancel();
    _timer = Timer.periodic(1.seconds, (t) {
      if (!mounted) return;
      setState(() => _elapsed = t.tick);
    });
  }

  void _resetQuestionTimer() {
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    setState(() => _elapsed = 0);
    _startTimer();
  }

  void _onOptionSelected(String option) async {
    if (_showingFeedback) return;
    final responseTime = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
    _responseTimes.add(responseTime);

    final currentQ = _questions[_currentIndex];
    final isCorrect = option.toLowerCase() == currentQ.correctOption.toLowerCase();
    _results[_currentIndex] = isCorrect;

    setState(() {
      _selectedOption = option;
      _showingFeedback = true;
    });

    if (isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    _feedbackCtrl.forward(from: 0);

    await Future.delayed(900.ms);
    if (!mounted) return;

    if (_currentIndex >= _questions.length - 1) {
      // Quiz Complete - Calculate score immediately
      final correctCount = _results.values.where((c) => c).length;
      final total = _questions.length;
      final baseScore = correctCount * 100;
      final isPerfect = correctCount == total;
      final speedBonus = correctCount * 30;
      final perfectBonus = isPerfect ? 200 : 0;
      final finalScore = baseScore + speedBonus + perfectBonus;
      final xpEarned = finalScore ~/ 10;

      final gameComplete = GameCompleteModel(
        sessionId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        scoreBreakdown: ScoreBreakdownModel(
          correctAnswers: correctCount,
          totalQuestions: total,
          baseScore: baseScore,
          speedBonus: speedBonus,
          perfectBonus: perfectBonus,
          dailyMultiplier: 1.0,
          finalScore: finalScore,
          xpEarned: xpEarned,
          levelBefore: 1,
          levelAfter: 1,
          leveledUp: false,
          newAchievements: isPerfect ? ['Perfect Score'] : [],
        ),
        newStreak: 1,
      );

      // Update local profile stats immediately
      ref.read(profileProvider.notifier).updateStats(
            xpEarned: xpEarned,
            scoreEarned: finalScore,
            isPerfect: isPerfect,
            newStreak: 1,
          );

      context.pushReplacement('/score', extra: {
        'article': widget.article,
        'result': gameComplete,
      });
    } else {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _showingFeedback = false;
      });
      _feedbackCtrl.reset();
      _resetQuestionTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final question = _questions[_currentIndex];
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;
    final secondsLeft =
        AppConstants.quizTimerSeconds - _elapsed > 0 ? AppConstants.quizTimerSeconds - _elapsed : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.surfaceElevated,
                          title: const Text(
                            'Quit quiz?',
                            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary),
                          ),
                          content: const Text(
                            'Your current progress will be lost.',
                            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('STAY'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.pop();
                              },
                              child: const Text('QUIT', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'QUESTION ${_currentIndex + 1} OF $total',
                          style: AppTextStyles.label(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.glassBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Countdown Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: secondsLeft <= 3
                          ? AppColors.error.withOpacity(0.2)
                          : AppColors.glass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: secondsLeft <= 3 ? AppColors.error : AppColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: secondsLeft <= 3 ? AppColors.error : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${secondsLeft}s',
                          style: AppTextStyles.label(
                            color: secondsLeft <= 3 ? AppColors.error : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Question and Options Scrollable ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPIC: ${widget.article.title.toUpperCase()}',
                      style: AppTextStyles.overline(color: AppColors.accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Question Box
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question.question,
                        style: AppTextStyles.cardTitle().copyWith(height: 1.4),
                      ),
                    ).animate().fadeIn(duration: 250.ms),

                    const SizedBox(height: 20),

                    // Options Map
                    ...question.optionsMap.entries.map((entry) {
                      final opt = entry.key;
                      final text = entry.value;
                      final isSelected = _selectedOption == opt;
                      final isCorrect = opt.toLowerCase() == question.correctOption.toLowerCase();

                      Color bgColor = AppColors.glass;
                      Color borderColor = isSelected ? AppColors.accent : AppColors.glassBorder;

                      if (_showingFeedback) {
                        if (isCorrect) {
                          bgColor = AppColors.success.withOpacity(0.2);
                          borderColor = AppColors.success;
                        } else if (isSelected) {
                          bgColor = AppColors.error.withOpacity(0.2);
                          borderColor = AppColors.error;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: _showingFeedback ? null : () => _onOptionSelected(opt),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: borderColor.withOpacity(0.15),
                                    border: Border.all(color: borderColor, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      opt.toUpperCase(),
                                      style: AppTextStyles.label(
                                        color: isSelected || (_showingFeedback && isCorrect)
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(text, style: AppTextStyles.bodyMedium()),
                                ),
                                if (_showingFeedback && isCorrect)
                                  const Icon(Icons.check_rounded,
                                      color: AppColors.success, size: 20),
                                if (_showingFeedback && isSelected && !isCorrect)
                                  const Icon(Icons.close_rounded,
                                      color: AppColors.error, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
