import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/constants/app_text_styles.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final ArticleModel article;
  const QuizScreen({super.key, required this.article});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _elapsed = 0;
  int _questionStartTime = 0;
  String? _selectedOption;
  AnswerResultModel? _lastResult;
  bool _showingFeedback = false;
  late AnimationController _feedbackCtrl;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(vsync: this, duration: 600.ms);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuiz(widget.article.id);
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackCtrl.dispose();
    ref.read(quizProvider.notifier).reset();
    super.dispose();
  }

  void _startTimer() {
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(1.seconds, (t) {
      if (!mounted) return;
      setState(() => _elapsed = t.tick);
    });
  }

  void _resetQuestionTimer() {
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    setState(() => _elapsed = 0);
  }

  Future<void> _onOptionSelected(String option) async {
    if (_showingFeedback) return;
    final responseTime = DateTime.now().millisecondsSinceEpoch - _questionStartTime;

    setState(() {
      _selectedOption = option;
      _showingFeedback = true;
    });

    HapticFeedback.selectionClick();
    _timer?.cancel();

    final result = await ref.read(quizProvider.notifier).submitAnswer(option, responseTime);
    if (!mounted) return;

    setState(() => _lastResult = result);
    _feedbackCtrl.forward(from: 0);

    if (result?.correct == true) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    // Show feedback for 1.5s, then advance or complete
    await Future.delayed(1800.ms);
    if (!mounted) return;

    final state = ref.read(quizProvider);
    if (state.isLastQuestion) {
      // Complete the quiz
      final result = await ref.read(quizProvider.notifier).completeQuiz();
      if (!mounted) return;
      if (result != null) {
        context.pushReplacement('/score', extra: {
          'article': widget.article,
          'result': result,
        });
      }
    } else {
      ref.read(quizProvider.notifier).advanceQuestion();
      setState(() {
        _selectedOption = null;
        _showingFeedback = false;
        _lastResult = null;
      });
      _feedbackCtrl.reset();
      _startTimer();
      _resetQuestionTimer();
    }
  }

  Color _optionColor(String option) {
    if (!_showingFeedback) return AppColors.glass;
    final result = _lastResult;
    if (result == null) return AppColors.glass;
    if (option == result.correctOption) return AppColors.success.withOpacity(0.2);
    if (option == _selectedOption && !result.correct) return AppColors.error.withOpacity(0.2);
    return AppColors.glass;
  }

  Color _optionBorderColor(String option) {
    if (!_showingFeedback) {
      return option == _selectedOption ? AppColors.accent : AppColors.glassBorder;
    }
    final result = _lastResult;
    if (result == null) return AppColors.glassBorder;
    if (option == result.correctOption) return AppColors.success;
    if (option == _selectedOption && !result.correct) return AppColors.error;
    return AppColors.glassBorder;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(QuizState state) {
    if (state.status == QuizStatus.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Preparing questions...',
                style: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.status == QuizStatus.error) {
      return AppErrorState(
        message: state.error ?? 'Quiz failed to load',
        onRetry: () => ref.read(quizProvider.notifier).startQuiz(widget.article.id),
        emoji: '🧠',
      );
    }

    final question = state.currentQuestion;
    if (question == null) return const SizedBox();

    final total = state.totalQuestions;
    final current = state.currentQuestionIndex;
    final progress = (current + 1) / total;

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surfaceElevated,
                      title: const Text('Quit quiz?',
                          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary)),
                      content: const Text(
                        'Your progress will be lost.',
                        style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.pop();
                          },
                          child: const Text('Quit', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('${current + 1} / $total',
                        style: AppTextStyles.label(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.glassBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _elapsed >= AppConstants.quizTimerSeconds
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.glass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _elapsed >= AppConstants.quizTimerSeconds
                        ? AppColors.error
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  '${AppConstants.quizTimerSeconds - _elapsed > 0 ? AppConstants.quizTimerSeconds - _elapsed : 0}s',
                  style: AppTextStyles.label(
                    color: _elapsed >= AppConstants.quizTimerSeconds
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Question card ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article context
                Text('From: ${widget.article.title}',
                    style: AppTextStyles.overline(color: AppColors.accent)),
                const SizedBox(height: 16),

                // Question text
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Text(question.question,
                      style: AppTextStyles.cardTitle().copyWith(height: 1.5)),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // ── Answer options ──
                ...question.optionsMap.entries.map((entry) {
                  final opt = entry.key;
                  final text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionButton(
                      option: opt,
                      text: text,
                      bgColor: _optionColor(opt),
                      borderColor: _optionBorderColor(opt),
                      onTap: () => _onOptionSelected(opt),
                      isSelected: _selectedOption == opt,
                      showingFeedback: _showingFeedback,
                      isCorrect: _lastResult?.correctOption == opt,
                    ),
                  );
                }),

                // ── Feedback explanation ──
                if (_showingFeedback && _lastResult?.explanation != null)
                  GlassCard(
                    backgroundColor: _lastResult!.correct
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderColor: _lastResult!.correct ? AppColors.success : AppColors.error,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_lastResult!.correct ? '✅' : '❌',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_lastResult!.explanation!,
                              style: AppTextStyles.body()),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String option;
  final String text;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showingFeedback;
  final bool isCorrect;

  const _OptionButton({
    required this.option,
    required this.text,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
    required this.isSelected,
    required this.showingFeedback,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showingFeedback ? null : onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Option letter badge
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor.withOpacity(0.2),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Center(
                child: Text(option.toUpperCase(),
                    style: AppTextStyles.label(
                        color: isSelected || (showingFeedback && isCorrect)
                            ? AppColors.textPrimary
                            : AppColors.textMuted)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text, style: AppTextStyles.bodyMedium()),
            ),
            if (showingFeedback && isCorrect)
              const Text('✓', style: TextStyle(color: AppColors.success, fontSize: 18)),
            if (showingFeedback && isSelected && !isCorrect)
              const Text('✗', style: TextStyle(color: AppColors.error, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
