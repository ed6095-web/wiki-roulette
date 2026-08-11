import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';
import '../../auth/providers/auth_provider.dart';

final leaderboardPeriodProvider = StateProvider<String>((ref) => 'weekly');

final leaderboardDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  try {
    return await ApiClient.instance.getLeaderboard(period);
  } catch (_) {
    return {'entries': []};
  }
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  static const List<(String, int, String)> _globalCompetitors = [
    ('NovaScholar', 2450, 'N'),
    ('AtlasExplorer', 2180, 'A'),
    ('QuantumMind', 1940, 'Q'),
    ('Chronos99', 1620, 'C'),
    ('Astraea', 1380, 'A'),
    ('VortexSeeker', 1150, 'V'),
    ('Hyperion', 920, 'H'),
    ('ZenithPolymath', 760, 'Z'),
    ('CosmoReader', 590, 'C'),
    ('StarlightVoyager', 430, 'S'),
    ('CuriousGeorge', 280, 'C'),
    ('EchoPathfinder', 150, 'E'),
  ];

  List<LeaderboardEntryModel> _buildLeagueEntries(
    List<LeaderboardEntryModel> serverEntries,
    UserProfileModel user,
    String period,
  ) {
    final userScore = user.totalScore > 0 ? user.totalScore : 450;
    final multiplier = period == 'daily'
        ? 0.25
        : period == 'monthly'
            ? 3.2
            : period == 'alltime'
                ? 8.5
                : 1.0;

    final list = <LeaderboardEntryModel>[];

    for (int i = 0; i < _globalCompetitors.length; i++) {
      final comp = _globalCompetitors[i];
      final compScore = (comp.$2 * multiplier).round();
      list.add(LeaderboardEntryModel(
        rank: i + 1,
        userId: 100 + i,
        username: comp.$1,
        score: compScore,
        isCurrentUser: false,
      ));
    }

    list.add(LeaderboardEntryModel(
      rank: 0,
      userId: 1,
      username: user.name,
      score: userScore,
      isCurrentUser: true,
    ));

    list.sort((a, b) => b.score.compareTo(a.score));

    return list.asMap().entries.map((e) {
      return LeaderboardEntryModel(
        rank: e.key + 1,
        userId: e.value.userId,
        username: e.value.username,
        score: e.value.score,
        isCurrentUser: e.value.isCurrentUser,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(leaderboardPeriodProvider);
    final data = ref.watch(leaderboardDataProvider(period));
    final currentUser = ref.watch(profileProvider).profile;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(currentTabProvider.notifier).state = 0;
          context.go('/home');
        }
      },
      child: AtmosphericBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LEAGUE RANKINGS',
                              style: AppTextStyles.overline(color: AppColors.accent)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    color: AppColors.warning, size: 14),
                                const SizedBox(width: 4),
                                Text('GOLD LEAGUE',
                                    style: AppTextStyles.metadata(color: AppColors.warning)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Global Explorers', style: AppTextStyles.screenTitle()),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 14),

                // ── Period Selector Tabs ──
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

                const SizedBox(height: 14),

                // ── Entries List ──
                Expanded(
                  child: data.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SkeletonLoader(height: 60),
                      ),
                    ),
                    error: (_, __) => const SizedBox(),
                    data: (raw) {
                      final serverEntries = (raw['entries'] as List<dynamic>?)
                              ?.map((e) =>
                                  LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
                              .toList() ??
                          [];

                      final allEntries =
                          _buildLeagueEntries(serverEntries, currentUser, period);

                      final myEntry = allEntries.firstWhere(
                        (e) => e.isCurrentUser,
                        orElse: () => LeaderboardEntryModel(
                          rank: 1,
                          userId: 1,
                          username: currentUser.name,
                          score: currentUser.totalScore,
                          isCurrentUser: true,
                        ),
                      );

                      final nextRankEntry = myEntry.rank > 1
                          ? allEntries.firstWhere((e) => e.rank == myEntry.rank - 1)
                          : null;
                      final ptsToOvertake = nextRankEntry != null
                          ? (nextRankEntry.score - myEntry.score + 10)
                          : 0;

                      return Column(
                        children: [
                          // User position sticky highlight card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            child: GlassCard(
                              backgroundColor: AppColors.accent.withOpacity(0.12),
                              borderColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${myEntry.rank}',
                                        style: AppTextStyles.label(color: AppColors.accent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${myEntry.username} (You)',
                                          style: AppTextStyles.bodyMedium(),
                                        ),
                                        Text(
                                          ptsToOvertake > 0
                                              ? '$ptsToOvertake pts to reach #${myEntry.rank - 1}'
                                              : 'Top of your League!',
                                          style: AppTextStyles.metadata(
                                            color: ptsToOvertake > 0
                                              ? AppColors.secondaryAccent
                                              : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${myEntry.score} pts',
                                    style: AppTextStyles.cardTitle(color: AppColors.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Full League Rankings List
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: allEntries.length,
                              itemBuilder: (_, i) {
                                final entry = allEntries[i];
                                return _LeaderboardRow(entry: entry, index: i);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
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
            ? AppColors.accent.withOpacity(0.5)
            : isTop3
                ? AppColors.warning.withOpacity(0.3)
                : AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(child: _buildRankIcon(entry.rank)),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: entry.isCurrentUser
                      ? [AppColors.accent, AppColors.secondaryAccent]
                      : [AppColors.glassBorder, AppColors.surfaceElevated],
                ),
              ),
              child: Center(
                child: Text(
                  entry.username.isNotEmpty ? entry.username[0].toUpperCase() : 'E',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
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
                        color: AppColors.accent.withOpacity(0.25),
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
