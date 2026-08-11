import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';

final profileStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.instance.getStats();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(profileStatsProvider);

    if (user == null) return const SizedBox();

    return AtmosphericBackground(
      glowAlignment: Alignment.topRight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PROFILE',
                          style: AppTextStyles.overline(color: AppColors.accent)),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar & Identity ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.secondaryAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 16),

                        Text(user.username, style: AppTextStyles.sectionTitle()),
                        Text('Level ${user.level} Explorer',
                            style: AppTextStyles.body(color: AppColors.accent)),

                        const SizedBox(height: 20),

                        // XP progress bar
                        Container(
                          width: 280,
                          child: XpProgressBar(
                            progress: _xpProgress(user.xp, user.level),
                            currentXp: user.xp,
                            nextLevelXp: _xpForLevel(user.level + 1),
                            level: user.level,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 36),

                  // ── Stats Grid ──
                  Text('STATS',
                      style: AppTextStyles.overline(color: AppColors.accent)),
                  const SizedBox(height: 12),

                  stats.when(
                    loading: () => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: List.generate(4, (_) => SkeletonLoader(height: 80)),
                    ),
                    error: (_, __) => const SizedBox(),
                    data: (data) => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard('Articles Read', '${data['articles_discovered']}', '📖'),
                        _StatCard('Quizzes Done', '${data['quizzes_completed']}', '✍️'),
                        _StatCard('Perfect Quizzes', '${data['perfect_quizzes']}', '⭐'),
                        _StatCard('Accuracy', '${(data['average_accuracy'] as num).toStringAsFixed(0)}%', '🎯'),
                      ],
                    ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                  ),

                  const SizedBox(height: 24),

                  // ── Streak ──
                  GlassCard(
                    borderColor: AppColors.streak.withOpacity(0.3),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STREAK',
                                style: AppTextStyles.overline(color: AppColors.streak)),
                            Text('${user.currentStreak} days current',
                                style: AppTextStyles.cardTitle()),
                            Text('Best: ${user.longestStreak} days',
                                style: AppTextStyles.body()),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // ── Quick Actions ──
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          onTap: () => context.push('/achievements'),
                          child: Column(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 8),
                              Text('Achievements', style: AppTextStyles.label()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          onTap: () {}, // History
                          child: Column(
                            children: [
                              const Text('📚', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 8),
                              Text('History', style: AppTextStyles.label()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCard(this.label, this.value, this.emoji);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.sectionTitle()),
          Text(label, style: AppTextStyles.metadata()),
        ],
      ),
    );
  }
}
