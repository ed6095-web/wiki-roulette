import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  final data = await ApiClient.instance.getAchievements();
  return data.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>)).toList();
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(achievementsProvider);

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
            padding: const EdgeInsets.all(24),
            itemCount: 10,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 80),
            ),
          ),
          error: (e, _) => AppErrorState(
            message: 'Failed to load achievements',
            onRetry: () => ref.invalidate(achievementsProvider),
            emoji: '🏆',
          ),
          data: (achievements) {
            final unlocked = achievements.where((a) => a.unlocked).toList();
            final locked = achievements.where((a) => !a.unlocked).toList();

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Progress header
                GlassCard(
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${unlocked.length} / ${achievements.length} unlocked',
                                style: AppTextStyles.cardTitle()),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: achievements.isEmpty ? 0 : unlocked.length / achievements.length,
                                backgroundColor: AppColors.glassBorder,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                if (unlocked.isNotEmpty) ...[
                  Text('UNLOCKED', style: AppTextStyles.overline(color: AppColors.success)),
                  const SizedBox(height: 12),
                  ...unlocked.asMap().entries.map((e) =>
                      _AchievementRow(achievement: e.value, index: e.key)),
                  const SizedBox(height: 24),
                ],

                if (locked.isNotEmpty) ...[
                  Text('LOCKED', style: AppTextStyles.overline(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  ...locked.asMap().entries.map((e) =>
                      _AchievementRow(achievement: e.value, index: e.key + unlocked.length)),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        backgroundColor: achievement.unlocked
            ? AppColors.success.withOpacity(0.05)
            : null,
        borderColor: achievement.unlocked
            ? AppColors.success.withOpacity(0.3)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              achievement.unlocked ? achievement.icon : '🔒',
              style: TextStyle(
                fontSize: 28,
                color: achievement.unlocked ? null : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.name,
                      style: AppTextStyles.bodyMedium(
                        color: achievement.unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      )),
                  Text(achievement.description,
                      style: AppTextStyles.metadata()),
                  if (achievement.unlocked && achievement.unlockedAt != null)
                    Text('Unlocked ${_formatDate(achievement.unlockedAt!)}',
                        style: AppTextStyles.metadata(color: AppColors.success)),
                ],
              ),
            ),
            Column(
              children: [
                Text('+${achievement.xpReward} XP',
                    style: AppTextStyles.label(
                      color: achievement.unlocked ? AppColors.accent : AppColors.textDisabled,
                    )),
              ],
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 30))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.05),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
