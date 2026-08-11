import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';

final leaderboardPeriodProvider = StateProvider<String>((ref) => 'weekly');

final leaderboardDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  return await ApiClient.instance.getLeaderboard(period);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(leaderboardPeriodProvider);
    final data = ref.watch(leaderboardDataProvider(period));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LEADERBOARD',
                        style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Text('Top Knowledge Explorers',
                        style: AppTextStyles.screenTitle()),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 20),

              // ── Period tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: ['daily', 'weekly', 'monthly', 'alltime'].map((p) {
                    final isSelected = p == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = p,
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.glass,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.glassBorder,
                            ),
                          ),
                          child: Text(
                            p[0].toUpperCase() + p.substring(1),
                            style: AppTextStyles.label(
                              color: isSelected ? AppColors.accent : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Entries ──
              Expanded(
                child: data.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: 10,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonLoader(height: 72),
                    ),
                  ),
                  error: (e, _) => AppErrorState(
                    message: 'Failed to load leaderboard',
                    onRetry: () => ref.invalidate(leaderboardDataProvider),
                    emoji: '🏆',
                  ),
                  data: (data) {
                    final entries = (data['entries'] as List<dynamic>?)
                        ?.map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
                        .toList() ??
                        [];

                    if (entries.isEmpty) {
                      return Center(
                        child: Text('No entries yet. Play a game to appear here!',
                            style: AppTextStyles.body(color: AppColors.textMuted),
                            textAlign: TextAlign.center),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final entry = entries[i];
                        return _LeaderboardRow(entry: entry, index: i)
                            .animate(delay: Duration(milliseconds: i * 40))
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: 0.05);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final int index;
  const _LeaderboardRow({required this.entry, required this.index});

  String get _rankEmoji {
    switch (entry.rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#${entry.rank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        backgroundColor: entry.isCurrentUser
            ? AppColors.accent.withOpacity(0.06)
            : null,
        borderColor: entry.isCurrentUser
            ? AppColors.accent.withOpacity(0.4)
            : isTop3 ? AppColors.warning.withOpacity(0.3) : AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: entry.rank <= 3
                  ? Text(_rankEmoji, style: const TextStyle(fontSize: 20))
                  : Text('#${entry.rank}',
                      style: AppTextStyles.label(color: AppColors.textMuted)),
            ),

            // Avatar placeholder
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.secondaryAccent],
                ),
              ),
              child: Center(
                child: Text(
                  entry.username[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.username, style: AppTextStyles.bodyMedium()),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('YOU',
                              style: AppTextStyles.metadata(color: AppColors.accent)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Text(_fmtScore(entry.score),
                style: AppTextStyles.cardTitle(
                    color: entry.rank == 1 ? AppColors.warning : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  String _fmtScore(int score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return score.toString();
  }
}
