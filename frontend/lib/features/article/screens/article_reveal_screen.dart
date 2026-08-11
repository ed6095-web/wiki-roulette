import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class ArticleRevealScreen extends StatefulWidget {
  final ArticleModel article;
  const ArticleRevealScreen({super.key, required this.article});

  @override
  State<ArticleRevealScreen> createState() => _ArticleRevealScreenState();
}

class _ArticleRevealScreenState extends State<ArticleRevealScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  int _interestScore(ArticleModel a) {
    final score = (a.wordCount ?? 100) + (a.description?.length ?? 0);
    if (score > 400) return 5;
    if (score > 250) return 4;
    if (score > 150) return 3;
    return 2;
  }

  IconData _iconForCategory(String? name) {
    final cat = (name ?? '').toLowerCase();
    if (cat.contains('space') || cat.contains('astron')) return Icons.rocket_launch_rounded;
    if (cat.contains('sci') || cat.contains('phys')) return Icons.biotech_rounded;
    if (cat.contains('tech') || cat.contains('comput')) return Icons.memory_rounded;
    if (cat.contains('art') || cat.contains('music')) return Icons.palette_rounded;
    if (cat.contains('geo') || cat.contains('world')) return Icons.public_rounded;
    if (cat.contains('anim') || cat.contains('bio')) return Icons.pets_rounded;
    return Icons.history_edu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final stars = _interestScore(article);
    final categoryName =
        article.categories.isNotEmpty ? article.categories.first.name : 'Knowledge';
    final categoryIcon = _iconForCategory(categoryName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.glass,
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Overline Badge
                      Row(
                        children: [
                          const Icon(
                            Icons.explore_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ARTICLE DISCOVERED',
                            style: AppTextStyles.overline(color: AppColors.accent),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        article.title,
                        style: AppTextStyles.screenTitle(),
                      ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1),

                      if (article.description != null && article.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          article.description!,
                          style: AppTextStyles.body(color: AppColors.textSecondary),
                        ).animate().fadeIn(delay: 200.ms),
                      ],

                      const SizedBox(height: 24),

                      // ── Sleek Vector Illustration Card (No 403 Images) ──
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E1B4B),
                              Color(0xFF0F172A),
                            ],
                          ),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.15),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(
                                categoryIcon,
                                size: 120,
                                color: AppColors.accent.withOpacity(0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      color: AppColors.accent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    categoryName.toUpperCase(),
                                    style: AppTextStyles.overline(color: AppColors.accent),
                                  ),
                                  Text(
                                    'Wikipedia Curated Archive',
                                    style: AppTextStyles.metadata(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms).scale(duration: 400.ms, begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 24),

                      // ── Metadata Badges Row ──
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DEPTH SCORE',
                                    style: AppTextStyles.overline(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: i < stars ? AppColors.warning : AppColors.textDisabled,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DIFFICULTY',
                                    style: AppTextStyles.overline(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: AppColors.secondaryAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        article.difficultyLabel,
                                        style: AppTextStyles.bodyMedium(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 28),

                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/article/read', extra: article);
                          },
                          child: const Text('READ ARTICLE'),
                        ),
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('DISCOVER ANOTHER →'),
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
