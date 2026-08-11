import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class ScoreScreen extends ConsumerWidget {
  final ArticleModel article;
  final GameCompleteModel result;
  const ScoreScreen({super.key, required this.article, required this.result});

  String _accuracyLabel(double accuracy) {
    if (accuracy >= 1.0) return 'PERFECT SCORE';
    if (accuracy >= 0.8) return 'EXCELLENT';
    if (accuracy >= 0.6) return 'GOOD JOB';
    if (accuracy >= 0.4) return 'SOLID EFFORT';
    return 'KEEP PRACTICING';
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 1.0) return AppColors.success;
    if (accuracy >= 0.8) return AppColors.secondaryAccent;
    if (accuracy >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = result.scoreBreakdown;
    final accuracy = breakdown.accuracy;
    final label = _accuracyLabel(accuracy);
    final accentColor = _accuracyColor(accuracy);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: AtmosphericBackground(
        glowColor: accentColor.withOpacity(0.2),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Accuracy Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          accuracy >= 1.0
                              ? Icons.workspace_premium_rounded
                              : Icons.insights_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: AppTextStyles.label(color: accentColor),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 8),
                  Text(
                    '${breakdown.correctAnswers} of ${breakdown.totalQuestions} questions correct',
                    style: AppTextStyles.body(),
                  ),

                  const SizedBox(height: 28),

                  // ── Big Score Display ──
                  Text(
                    breakdown.finalScore.toString(),
                    style: AppTextStyles.score(),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),

                  Text(
                    'TOTAL POINTS',
                    style: AppTextStyles.overline(color: AppColors.textMuted),
                  ),

                  const SizedBox(height: 24),

                  // ── Score Breakdown Card ──
                  GlassCard(
                    child: Column(
                      children: [
                        _BreakdownRow('Base Points', breakdown.baseScore),
                        _BreakdownRow(
                          'Speed Bonus',
                          breakdown.speedBonus,
                          color: AppColors.secondaryAccent,
                        ),
                        if (breakdown.perfectBonus > 0)
                          _BreakdownRow(
                            'Perfect Accuracy Bonus',
                            breakdown.perfectBonus,
                            color: AppColors.warning,
                          ),
                        const Divider(color: AppColors.glassBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('EXPERIENCE GAINED', style: AppTextStyles.label()),
                            Text(
                              '+${breakdown.xpEarned} XP',
                              style: AppTextStyles.cardTitle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // ── Topic Knowledge Card ──
                  GlassCard(
                    borderColor: AppColors.secondaryAccent.withOpacity(0.3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.secondaryAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHALLENGE TOPIC',
                                style: AppTextStyles.overline(color: AppColors.secondaryAccent),
                              ),
                              Text(
                                article.title,
                                style: AppTextStyles.bodyMedium(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Difficulty: ${article.difficultyLabel}',
                                style: AppTextStyles.metadata(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 28),

                  // ── Action Buttons ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('SPIN AGAIN'),
                    ),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      onPressed: () => context.go('/leaderboard'),
                      child: const Text('VIEW RANKINGS →'),
                    ),
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BreakdownRow(this.label, this.value, {this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body()),
          Text('+$value', style: AppTextStyles.bodyMedium(color: color)),
        ],
      ),
    );
  }
}
