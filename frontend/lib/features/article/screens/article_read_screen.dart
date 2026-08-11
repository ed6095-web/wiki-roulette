import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class ArticleReadScreen extends ConsumerWidget {
  final ArticleModel article;
  const ArticleReadScreen({super.key, required this.article});

  List<(IconData, String)> _extractKeyFacts(ArticleModel article) {
    final facts = <(IconData, String)>[];
    final extract = article.extract ?? '';

    // Extract years
    final yearMatches = RegExp(r'\b(1[0-9]{3}|20[0-9]{2})\b').allMatches(extract);
    for (final m in yearMatches.take(1)) {
      facts.add((Icons.calendar_today_rounded, 'Key Year: ${m.group(0)!}'));
    }

    // Extract numeric quantities
    final numMatches = RegExp(
      r'\b(\d{2,}(?:,\d{3})*)\s*(people|deaths?|km|miles?|metres?|feet)\b',
      caseSensitive: false,
    ).allMatches(extract);
    for (final m in numMatches.take(2)) {
      facts.add((Icons.insights_rounded, '${m.group(1)!} ${m.group(2)!}'));
    }

    // Add reading level
    facts.add((Icons.bolt_rounded, 'Difficulty Level: ${article.difficultyLabel}'));

    return facts.take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = _extractKeyFacts(article);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar with Hero Image ──
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_browser_rounded),
                  tooltip: 'View on Wikipedia',
                  onPressed: () async {
                    final uri = Uri.parse(article.url);
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: article.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.thumbnailUrl!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.4),
                        colorBlendMode: BlendMode.darken,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: AppColors.cardGradient),
                        ),
                        child: const Center(
                          child: Icon(Icons.public_rounded, size: 54, color: AppColors.textMuted),
                        ),
                      ),
              ),
            ),

            // ── Article Content ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title
                  Text(article.title, style: AppTextStyles.screenTitle())
                      .animate()
                      .fadeIn(duration: 400.ms),

                  if (article.description != null && article.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.description!,
                      style: AppTextStyles.body(color: AppColors.textMuted),
                    ).animate().fadeIn(delay: 100.ms),
                  ],

                  // Category Chips
                  if (article.categories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: article.categories.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            c.name,
                            style: AppTextStyles.metadata(color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.glassBorder),
                  const SizedBox(height: 16),

                  // ── Key Facts Panel ──
                  if (facts.isNotEmpty) ...[
                    Text('KEY HIGHLIGHTS',
                        style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: facts.map((fact) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(fact.$1, size: 18, color: AppColors.accent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(fact.$2, style: AppTextStyles.bodyMedium()),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 20),
                  ],

                  // ── Article Summary ──
                  Text('OVERVIEW', style: AppTextStyles.overline(color: AppColors.accent)),
                  const SizedBox(height: 10),
                  Text(
                    article.shortExtract ?? article.extract ?? 'No content available.',
                    style: AppTextStyles.body(),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  // Attribution
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Content licensed under CC BY-SA 4.0 from Wikipedia.',
                          style: AppTextStyles.metadata(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // ── Start Quiz CTA ──
                  if (article.quizAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/quiz', extra: article);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('START KNOWLEDGE CHALLENGE', style: AppTextStyles.button()),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15)
                  else
                    GlassCard(
                      child: Center(
                        child: Text(
                          'No quiz available for this article',
                          style: AppTextStyles.body(color: AppColors.textMuted),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
