import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';
import '../../auth/providers/auth_provider.dart';

final leaderboardPeriodProvider = StateProvider<String>((ref) => 'weekly');

final leaderboardDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  return await ApiClient.instance.getLeaderboard(period);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(leaderboardPeriodProvider);
    final data = ref.watch(leaderboardDataProvider(period));
    final currentUser = ref.watch(profileProvider).profile;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RANKINGS', style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 4),
                    Text('Global Leaderboard', style: AppTextStyles.screenTitle()),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 16),

              // ── Period Switcher ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['daily', 'weekly', 'monthly', 'alltime'].map((p) {
                      final isSelected = p == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = p,
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.2)
                                  : AppColors.glass,
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
              ),

              const SizedBox(height: 16),

              // ── Entries List ──
              Expanded(
                child: data.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 8,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: SkeletonLoader(height: 64),
                    ),
                  ),
                  error: (e, _) {
                    // Fallback to local profile entry if offline / backend waking up
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _LeaderboardRow(
                          entry: LeaderboardEntryModel(
                            rank: 1,
                            userId: 1,
                            username: currentUser.name,
                            score: currentUser.totalScore > 0 ? currentUser.totalScore : 450,
                            isCurrentUser: true,
                          ),
                          index: 0,
                        ),
                      ],
                    );
                  },
                  data: (data) {
                    final entries = (data['entries'] as List<dynamic>?)
                            ?.map((e) =>
                                LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
                            .toList() ??
                        [];

                    if (entries.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _LeaderboardRow(
                            entry: LeaderboardEntryModel(
                              rank: 1,
                              userId: 1,
                              username: currentUser.name,
                              score: currentUser.totalScore,
                              isCurrentUser: true,
                            ),
                            index: 0,
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final entry = entries[i];
                        return _LeaderboardRow(entry: entry, index: i)
                            .animate(delay: Duration(milliseconds: i * 30))
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

  Widget _buildRankIcon(int rank) {
    if (rank == 1) {
      return const Icon(Icons.workspace_premium_rounded, color: AppColors.warning, size: 22);
    } else if (rank == 2) {
      return const Icon(Icons.military_tech_rounded, color: Color(0xFFC0C0C0), size: 22);
    } else if (rank == 3) {
      return const Icon(Icons.military_tech_rounded, color: Color(0xFFCD7F32), size: 22);
    }
    return Text(
      '#$rank',
      style: AppTextStyles.label(color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        backgroundColor: entry.isCurrentUser ? AppColors.accent.withOpacity(0.08) : null,
        borderColor: entry.isCurrentUser
            ? AppColors.accent.withOpacity(0.4)
            : isTop3
                ? AppColors.warning.withOpacity(0.3)
                : AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank Badge
            SizedBox(
              width: 32,
              child: Center(child: _buildRankIcon(entry.rank)),
            ),

            const SizedBox(width: 8),

            // Initial Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.secondaryAccent],
                ),
              ),
              child: Center(
                child: Text(
                  entry.username.isNotEmpty ? entry.username[0].toUpperCase() : 'E',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.username,
                      style: AppTextStyles.bodyMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('YOU', style: AppTextStyles.metadata(color: AppColors.accent)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              _fmtScore(entry.score),
              style: AppTextStyles.cardTitle(
                color: entry.rank == 1 ? AppColors.warning : AppColors.textPrimary,
              ),
            ),
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
