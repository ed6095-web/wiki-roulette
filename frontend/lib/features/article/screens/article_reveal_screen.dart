import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final stars = _interestScore(article);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Hero image backdrop ──
          if (article.thumbnailUrl != null)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.65],
                ).createShader(rect),
                blendMode: BlendMode.darken,
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.multiply,
                ),
              ),
            ),

          // ── Scrollable Content ──
          SafeArea(
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

                        const SizedBox(height: 20),

                        // Hero image card
                        if (article.thumbnailUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: article.thumbnailUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 20),

                        // ── Metadata Badges Row (Flexible & Overflow Proof) ──
                        Row(
                          children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
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
                                padding: const EdgeInsets.all(14),
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

                        // Action button
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
        ],
      ),
    );
  }
}
