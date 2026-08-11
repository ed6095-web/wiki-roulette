import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../home/providers/home_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static const List<(IconData, String)> _categories = [
    (Icons.history_edu_rounded, 'History'),
    (Icons.rocket_launch_rounded, 'Space'),
    (Icons.biotech_rounded, 'Science'),
    (Icons.public_rounded, 'Geography'),
    (Icons.memory_rounded, 'Technology'),
    (Icons.palette_rounded, 'Arts'),
    (Icons.pets_rounded, 'Animals'),
    (Icons.sports_volleyball_rounded, 'Sports'),
    (Icons.music_note_rounded, 'Music'),
    (Icons.restaurant_rounded, 'Cuisine'),
    (Icons.apartment_rounded, 'Architecture'),
    (Icons.movie_rounded, 'Cinema'),
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISCOVER',
                              style: AppTextStyles.overline(color: AppColors.secondaryAccent),
                            ),
                            const SizedBox(height: 2),
                            Text('Explore Topics', style: AppTextStyles.screenTitle()),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => context.push('/search'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Random Surprise Card ──
                    GlassCard(
                      onTap: () {
                        ref.read(rouletteProvider.notifier).spin();
                        context.go('/home');
                      },
                      borderColor: AppColors.accent.withOpacity(0.4),
                      backgroundColor: AppColors.accent.withOpacity(0.06),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.casino_rounded,
                              color: AppColors.accent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SURPRISE ME',
                                    style: AppTextStyles.overline(color: AppColors.accent)),
                                const SizedBox(height: 2),
                                Text(
                                  'Explore a completely random article',
                                  style: AppTextStyles.body(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.accent),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text('BROWSE BY CATEGORY',
                        style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 14),

                    // ── Category Grid ──
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(10),
                          onTap: () => context.push('/search'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.$1, size: 28, color: AppColors.secondaryAccent),
                              const SizedBox(height: 6),
                              Text(
                                cat.$2,
                                style: AppTextStyles.metadata(color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
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
