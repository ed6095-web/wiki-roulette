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

    return AtmosphericBackground(
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
                const SizedBox(height: 20),

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
                        accuracy >= 1.0 ? Icons.workspace_premium_rounded : Icons.insights_rounded,
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

                const SizedBox(height: 32),

                // ── Big Score Display ──
                Text(
                  breakdown.finalScore.toString(),
                  style: AppTextStyles.score(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(duration: 600.ms, curve: Curves.easeOutBack),

                Text(
                  'TOTAL POINTS',
                  style: AppTextStyles.overline(color: AppColors.textMuted),
                ),

                const SizedBox(height: 28),

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
                      if (breakdown.dailyMultiplier > 1.0)
                        _BreakdownRow(
                          'Daily Multiplier (1.5x)',
                          (breakdown.finalScore -
                              breakdown.finalScore ~/ breakdown.dailyMultiplier),
                          color: AppColors.streak,
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
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // ── Level Up Banner ──
                if (breakdown.leveledUp)
                  GlassCard(
                    borderColor: AppColors.warning.withOpacity(0.6),
                    backgroundColor: AppColors.warning.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_circle_up_rounded,
                          color: AppColors.warning,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LEVEL UP',
                                  style: AppTextStyles.overline(color: AppColors.warning)),
                              Text(
                                'Level ${breakdown.levelBefore} → Level ${breakdown.levelAfter}',
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .shake(delay: 600.ms, hz: 4, offset: const Offset(4, 0)),

                // ── Streak Status ──
                if (result.newStreak > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.streak, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${result.newStreak} Day Streak Active',
                        style: AppTextStyles.bodyMedium(color: AppColors.streak),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],

                const SizedBox(height: 32),

                // ── Action Buttons ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('SPIN AGAIN'),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.15),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: () => context.go('/leaderboard'),
                    child: const Text('VIEW RANKINGS →'),
                  ),
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 20),
              ],
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
