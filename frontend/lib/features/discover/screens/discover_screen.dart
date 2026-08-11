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

final discoverCategoryProvider = StateProvider<String?>((ref) => null);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static const List<(String, String, IconData, Color)> _categories = [
    ('History', 'Ancient civilizations & revolutions', Icons.history_edu_rounded, Color(0xFF6366F1)),
    ('Science', 'Physics, chemistry & universe', Icons.biotech_rounded, Color(0xFF06B6D4)),
    ('Space', 'Galaxies, planets & cosmos', Icons.rocket_launch_rounded, Color(0xFF8B5CF6)),
    ('Technology', 'AI, computing & invention', Icons.memory_rounded, Color(0xFF10B981)),
    ('Arts & Culture', 'Paintings, literature & music', Icons.palette_rounded, Color(0xFFF59E0B)),
    ('Geography', 'Wonders, mountains & oceans', Icons.public_rounded, Color(0xFF3B82F6)),
    ('Wildlife', 'Fauna, marine life & flora', Icons.pets_rounded, Color(0xFF14B8A6)),
    ('Philosophy', 'Great thinkers & world logic', Icons.psychology_rounded, Color(0xFFEC4899)),
    ('Architecture', 'Monuments, bridges & design', Icons.apartment_rounded, Color(0xFFF97316)),
    ('Cinema', 'Film history & masterpieces', Icons.movie_rounded, Color(0xFF84CC16)),
    ('Mythology', 'Legends, gods & folklore', Icons.shield_rounded, Color(0xFFA855F7)),
    ('Sports', 'Athletic milestones & history', Icons.sports_volleyball_rounded, Color(0xFFEF4444)),
  ];

  Future<void> _openTopic(BuildContext context, String topic) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      final data = await ApiClient.instance.getArticleByTitle(topic);
      if (context.mounted) Navigator.of(context).pop();
      final article = ArticleModel.fromJson(data);
      if (context.mounted) {
        context.push('/article/reveal', extra: article);
      }
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BROWSE BY TOPIC',
                          style: AppTextStyles.overline(color: AppColors.accent)),
                      const SizedBox(height: 4),
                      Text('Explore Categories', style: AppTextStyles.screenTitle()),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 16),

                // ── Category Grid ──
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      return _CategoryCard(
                        name: cat.$1,
                        desc: cat.$2,
                        icon: cat.$3,
                        accentColor: cat.$4,
                        onTap: () => _openTopic(context, cat.$1),
                      )
                          .animate(delay: Duration(milliseconds: i * 30))
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.92, 0.92));
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

class _CategoryCard extends StatelessWidget {
  final String name;
  final String desc;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.desc,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: accentColor.withOpacity(0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const Spacer(),
          Text(
            name,
            style: AppTextStyles.cardTitle().copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.metadata(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
