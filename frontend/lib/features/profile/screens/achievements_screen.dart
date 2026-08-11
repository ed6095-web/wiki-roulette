import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';
import '../../auth/providers/auth_provider.dart';

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  try {
    final data = await ApiClient.instance.getAchievements();
    return data.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    // Fallback static achievements if offline
    return const [
      AchievementModel(
        id: 1,
        name: 'First Discovery',
        description: 'Completed your first Wikipedia quiz',
        iconCode: 'explore',
        xpReward: 100,
        unlocked: true,
      ),
      AchievementModel(
        id: 2,
        name: 'Perfect Mind',
        description: 'Scored 100% accuracy on any challenge',
        iconCode: 'star',
        xpReward: 250,
        unlocked: false,
      ),
      AchievementModel(
        id: 3,
        name: '3-Day Streak',
        description: 'Explored Wikipedia articles 3 days in a row',
        iconCode: 'fire',
        xpReward: 200,
        unlocked: false,
      ),
      AchievementModel(
        id: 4,
        name: 'Knowledge Collector',
        description: 'Discovered and read 10 unique articles',
        iconCode: 'book',
        xpReward: 300,
        unlocked: false,
      ),
      AchievementModel(
        id: 5,
        name: 'Speed Demon',
        description: 'Answered a question correctly in under 3 seconds',
        iconCode: 'speed',
        xpReward: 150,
        unlocked: false,
      ),
    ];
  }
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(achievementsProvider);
    final user = ref.watch(profileProvider).profile;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Achievements'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: data.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 6,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonLoader(height: 72),
            ),
          ),
          error: (_, __) => const SizedBox(),
          data: (achievements) {
            // Check unlocks dynamically against user profile
            final processed = achievements.map((a) {
              bool isUnlocked = a.unlocked;
              if (a.name == 'First Discovery' && user.totalGames >= 1) isUnlocked = true;
              if (a.name == 'Perfect Mind' && user.perfectQuizzes >= 1) isUnlocked = true;
              if (a.name == '3-Day Streak' && user.currentStreak >= 3) isUnlocked = true;
              if (a.name == 'Knowledge Collector' && user.articlesRead >= 10) isUnlocked = true;
              return AchievementModel(
                id: a.id,
                name: a.name,
                description: a.description,
                iconCode: a.iconCode,
                xpReward: a.xpReward,
                unlocked: isUnlocked,
                unlockedAt: a.unlockedAt,
              );
            }).toList();

            final unlockedCount = processed.where((a) => a.unlocked).length;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Progress Bar Card
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount of ${processed.length} Unlocked',
                              style: AppTextStyles.cardTitle(),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: processed.isEmpty
                                    ? 0
                                    : (unlockedCount / processed.length).clamp(0.0, 1.0),
                                backgroundColor: AppColors.glassBorder,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(AppColors.warning),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                ...processed.asMap().entries.map((e) {
                  return _AchievementRow(achievement: e.value, index: e.key);
                }),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final AchievementModel achievement;
  final int index;
  const _AchievementRow({required this.achievement, required this.index});

  IconData _iconForCode(String code) {
    switch (code) {
      case 'star':
        return Icons.star_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'book':
        return Icons.auto_stories_rounded;
      case 'speed':
        return Icons.speed_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        backgroundColor:
            achievement.unlocked ? AppColors.success.withOpacity(0.06) : AppColors.glass,
        borderColor: achievement.unlocked
            ? AppColors.success.withOpacity(0.35)
            : AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.unlocked
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.glassBorder,
              ),
              child: Icon(
                achievement.unlocked
                    ? _iconForCode(achievement.iconCode)
                    : Icons.lock_outline_rounded,
                color: achievement.unlocked ? AppColors.success : AppColors.textDisabled,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: AppTextStyles.bodyMedium(
                      color: achievement.unlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: AppTextStyles.metadata(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: achievement.unlocked
                    ? AppColors.accent.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: achievement.unlocked
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: AppTextStyles.metadata(
                  color: achievement.unlocked ? AppColors.accent : AppColors.textDisabled,
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 25))
          .fadeIn(duration: 250.ms)
          .slideX(begin: 0.04),
    );
  }
}
