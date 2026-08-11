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

class _ArticleRevealScreenState extends State<ArticleRevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: 800.ms,
    )..forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  String _interestingRating(ArticleModel a) {
    // Heuristic based on description length + word count
    final score = (a.wordCount ?? 100) + (a.description?.length ?? 0);
    if (score > 400) return '🔥🔥🔥🔥🔥';
    if (score > 250) return '🔥🔥🔥🔥';
    if (score > 150) return '🔥🔥🔥';
    return '🔥🔥';
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Hero blurred background image ──
          if (article.thumbnailUrl != null)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.55],
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

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.glass,
                        side: const BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // "DISCOVERED" label
                        Text('DISCOVERED',
                            style: AppTextStyles.overline(color: AppColors.accent))
                            .animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 12),

                        // Title
                        Text(article.title,
                            style: AppTextStyles.hero())
                            .animate().fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideY(begin: 0.2, delay: 150.ms),

                        const SizedBox(height: 12),

                        // Description
                        if (article.description != null)
                          Text(article.description!,
                              style: AppTextStyles.body(color: AppColors.textSecondary))
                              .animate().fadeIn(delay: 250.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // ── Hero image ──
                        if (article.thumbnailUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: article.thumbnailUrl!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ).animate().fadeIn(delay: 300.ms).scale(
                                begin: const Offset(0.95, 0.95),
                                delay: 300.ms,
                              ),

                        const SizedBox(height: 24),

                        // ── Meta cards ──
                        Row(
                          children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('INTERESTING RATING',
                                        style: AppTextStyles.overline(
                                            color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Text(_interestingRating(article),
                                        style: const TextStyle(fontSize: 18)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DIFFICULTY',
                                        style: AppTextStyles.overline(
                                            color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(article.difficultyEmoji,
                                            style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(article.difficultyLabel,
                                            style: AppTextStyles.bodyMedium()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // ── Action buttons ──
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/article/read', extra: article);
                            },
                            child: const Text('READ ARTICLE'),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, delay: 500.ms),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('SKIP →'),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 40),
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
