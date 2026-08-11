import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/widgets/main_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).profile;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(currentTabProvider.notifier).state = 0;
          context.go('/home');
        }
      },
      child: AtmosphericBackground(
        glowAlignment: Alignment.topRight,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('EXPLORER PROFILE',
                              style: AppTextStyles.overline(color: AppColors.accent)),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: AppColors.textSecondary),
                            onPressed: () => context.push('/settings'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Avatar & Identity ──
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.accent, AppColors.secondaryAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.35),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'E',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                            const SizedBox(height: 14),

                            Text(
                              user.name,
                              style: AppTextStyles.sectionTitle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Level ${user.level} Explorer',
                              style: AppTextStyles.body(color: AppColors.accent),
                            ),

                            const SizedBox(height: 16),

                            // XP Progress
                            SizedBox(
                              width: 260,
                              child: XpProgressBar(
                                progress: _xpProgress(user.xp, user.level),
                                currentXp: user.xp,
                                nextLevelXp: _xpForLevel(user.level + 1),
                                level: user.level,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 450.ms),

                      // Selected Interests Tags
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('FAVORITE TOPICS',
                            style: AppTextStyles.overline(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests.map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.glass,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Text(
                                topic,
                                style: AppTextStyles.metadata(color: AppColors.secondaryAccent),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Stats Grid ──
                      Text('STATISTICS', style: AppTextStyles.overline(color: AppColors.accent)),
                      const SizedBox(height: 10),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard('Articles Read', '${user.articlesRead}',
                              Icons.auto_stories_rounded),
                          _StatCard('Quizzes Done', '${user.totalGames}', Icons.quiz_rounded),
                          _StatCard('Perfect Games', '${user.perfectQuizzes}',
                              Icons.workspace_premium_rounded),
                          _StatCard(
                            'Total Points',
                            _fmtScore(user.totalScore),
                            Icons.insights_rounded,
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 18),

                      // ── Streak Card ──
                      GlassCard(
                        borderColor: AppColors.streak.withOpacity(0.3),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.streak.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.streak,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STREAK PROGRESS',
                                      style: AppTextStyles.overline(color: AppColors.streak)),
                                  Text(
                                    '${user.currentStreak} Days Active',
                                    style: AppTextStyles.cardTitle(),
                                  ),
                                  Text(
                                    'Personal best: ${user.longestStreak} days',
                                    style: AppTextStyles.metadata(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 300.ms).fadeIn(),

                      const SizedBox(height: 18),

                      // ── Achievements Action ──
                      GlassCard(
                        onTap: () => context.push('/achievements'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ACHIEVEMENTS', style: AppTextStyles.cardTitle()),
                                  Text(
                                    'View your unlocked milestone badges',
                                    style: AppTextStyles.metadata(),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ).animate(delay: 350.ms).fadeIn(),

                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _xpProgress(int xp, int level) {
    final currentLevelXp = _xpForLevel(level);
    final nextLevelXp = _xpForLevel(level + 1);
    if (nextLevelXp <= currentLevelXp) return 1.0;
    return ((xp - currentLevelXp) / (nextLevelXp - currentLevelXp)).clamp(0.0, 1.0);
  }

  int _xpForLevel(int level) {
    if (level <= 1) return 0;
    return (300 * (level * 1.5)).toInt();
  }

  String _fmtScore(int score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return score.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondaryAccent, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.cardTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.metadata(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
