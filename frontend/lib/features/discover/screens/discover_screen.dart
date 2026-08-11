import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../home/providers/home_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static const _topCategories = [
    ('📜', 'History'), ('🌌', 'Space'), ('🧪', 'Science'),
    ('🌍', 'Geography'), ('💻', 'Technology'), ('🎨', 'Art'),
    ('🐾', 'Animals'), ('🏆', 'Sports'), ('🎵', 'Music'),
    ('🍜', 'Food'), ('⚙️', 'Engineering'), ('🏛️', 'Architecture'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtmosphericBackground(
      glowAlignment: Alignment.topLeft,
      glowColor: AppColors.cyanGlow,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DISCOVER',
                                style: AppTextStyles.overline(
                                    color: AppColors.secondaryAccent)),
                            Text('Explore by Topic', style: AppTextStyles.screenTitle()),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded,
                              color: AppColors.textSecondary, size: 28),
                          onPressed: () => context.push('/search'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Random discovery CTA ──
                    GlassCard(
                      onTap: () {
                        ref.read(rouletteProvider.notifier).spin();
                        context.go('/home');
                      },
                      borderColor: AppColors.accent.withOpacity(0.4),
                      backgroundColor: AppColors.accent.withOpacity(0.05),
                      child: Row(
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SURPRISE ME',
                                    style: AppTextStyles.overline(
                                        color: AppColors.accent)),
                                Text('Get a completely random Wikipedia article',
                                    style: AppTextStyles.body()),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.accent),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text('BROWSE CATEGORIES',
                        style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 16),

                    // ── Category grid ──
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: _topCategories.map((cat) {
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () {}, // TODO category filter
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.$1, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(cat.$2,
                                  style: AppTextStyles.metadata(
                                      color: AppColors.textSecondary),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
