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
    if (accuracy >= 1.0) return '💯 PERFECT!';
    if (accuracy >= 0.8) return '🔥 EXCELLENT';
    if (accuracy >= 0.6) return '⭐ GOOD';
    if (accuracy >= 0.4) return '📚 DECENT';
    return '💪 KEEP TRYING';
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ── Performance label ──
                Text(label,
                    style: AppTextStyles.sectionTitle(color: accentColor))
                    .animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 8),
                Text('${breakdown.correctAnswers} / ${breakdown.totalQuestions} correct',
                    style: AppTextStyles.body()),

                const SizedBox(height: 48),

                // ── Big Score Number ──
                Text(breakdown.finalScore.toString(),
                    style: AppTextStyles.score())
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(duration: 800.ms, curve: Curves.easeOutBack),

                Text('TOTAL SCORE',
                    style: AppTextStyles.overline(color: AppColors.textMuted)),

                const SizedBox(height: 40),

                // ── Score breakdown ──
                GlassCard(
                  child: Column(
                    children: [
                      _BreakdownRow('Base score', breakdown.baseScore),
                      _BreakdownRow('Speed bonus', breakdown.speedBonus,
                          color: AppColors.secondaryAccent),
                      if (breakdown.perfectBonus > 0)
                        _BreakdownRow('🌟 Perfect bonus', breakdown.perfectBonus,
                            color: AppColors.warning),
                      if (breakdown.dailyMultiplier > 1.0)
                        _BreakdownRow(
                          '📅 Daily multiplier ×${breakdown.dailyMultiplier.toStringAsFixed(1)}',
                          (breakdown.finalScore - breakdown.finalScore ~/ breakdown.dailyMultiplier),
                          color: AppColors.streak,
                        ),
                      const Divider(color: AppColors.glassBorder, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL', style: AppTextStyles.label()),
                          Text('+${breakdown.xpEarned} XP',
                              style: AppTextStyles.cardTitle(color: AppColors.accent)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),

                // ── Level up banner ──
                if (breakdown.leveledUp)
                  GlassCard(
                    borderColor: AppColors.warning.withOpacity(0.6),
                    backgroundColor: AppColors.warning.withOpacity(0.05),
                    child: Row(
                      children: [
                        const Text('⬆️', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LEVEL UP!',
                                  style: AppTextStyles.overline(color: AppColors.warning)),
                              Text('Level ${breakdown.levelBefore} → ${breakdown.levelAfter}',
                                  style: AppTextStyles.bodyMedium()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                      .fadeIn(delay: 900.ms)
                      .shake(delay: 1000.ms, hz: 4, offset: const Offset(4, 0)),

                // ── New achievements ──
                if (breakdown.newAchievements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    borderColor: AppColors.secondaryAccent.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEW ACHIEVEMENTS', style: AppTextStyles.overline()),
                        const SizedBox(height: 12),
                        ...breakdown.newAchievements.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Text(name, style: AppTextStyles.bodyMedium()),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1100.ms),
                ],

                const SizedBox(height: 40),

                // ── Streak ──
                if (result.newStreak > 0)
                  Text('🔥 ${result.newStreak} day streak',
                      style: AppTextStyles.bodyMedium(color: AppColors.streak))
                      .animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 32),

                // ── Action buttons ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('SPIN AGAIN'),
                  ),
                ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.15, delay: 1300.ms),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => context.go('/leaderboard'),
                    child: const Text('See Leaderboard →'),
                  ),
                ).animate().fadeIn(delay: 1400.ms),

                const SizedBox(height: 40),
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

  const _BreakdownRow(this.label, this.value,
      {this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
