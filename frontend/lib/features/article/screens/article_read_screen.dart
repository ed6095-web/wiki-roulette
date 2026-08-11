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

  List<Map<String, String>> _extractKeyFacts(ArticleModel article) {
    final facts = <Map<String, String>>[];
    final extract = article.extract ?? '';

    // Extract years
    final yearMatches = RegExp(r'\b(1[0-9]{3}|20[0-9]{2})\b').allMatches(extract);
    for (final m in yearMatches.take(1)) {
      facts.add({'icon': '📅', 'text': m.group(0)!});
    }

    // Extract numeric quantities
    final numMatches = RegExp(r'\b(\d{2,}(?:,\d{3})*)\s*(people|deaths?|km|miles?)\b',
        caseSensitive: false).allMatches(extract);
    for (final m in numMatches.take(2)) {
      facts.add({'icon': '📊', 'text': '${m.group(1)!} ${m.group(2)!}'});
    }

    // Add difficulty as a fact
    facts.add({'icon': '⚡', 'text': 'Difficulty: ${article.difficultyLabel}'});

    return facts.take(4).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = _extractKeyFacts(article);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── App bar with hero image ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_browser_outlined),
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
                          gradient: LinearGradient(
                            colors: AppColors.cardGradient,
                          ),
                        ),
                        child: const Center(
                          child: Text('🌐', style: TextStyle(fontSize: 60)),
                        ),
                      ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title
                  Text(article.title, style: AppTextStyles.screenTitle())
                      .animate().fadeIn(duration: 400.ms),
                  if (article.description != null) ...[
                    const SizedBox(height: 8),
                    Text(article.description!,
                        style: AppTextStyles.body(color: AppColors.textMuted))
                        .animate().fadeIn(delay: 100.ms),
                  ],

                  // Categories
                  if (article.categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: article.categories.map((c) => Chip(
                        label: Text('${c.icon ?? ''} ${c.name}',
                            style: AppTextStyles.metadata(color: AppColors.textSecondary)),
                        backgroundColor: AppColors.glass,
                        side: const BorderSide(color: AppColors.glassBorder),
                      )).toList(),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 28),
                  const Divider(color: AppColors.glassBorder),
                  const SizedBox(height: 20),

                  // ── Key Facts ──
                  if (facts.isNotEmpty) ...[
                    Text('KEY FACTS',
                        style: AppTextStyles.overline(color: AppColors.accent)),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        children: facts.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Text(entry.value['icon']!,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(entry.value['text']!,
                                      style: AppTextStyles.bodyMedium()),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── Summary text ──
                  Text('ABOUT',
                      style: AppTextStyles.overline(color: AppColors.accent)),
                  const SizedBox(height: 12),
                  Text(article.shortExtract ?? article.extract ?? '',
                      style: AppTextStyles.body())
                      .animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),
                  // Attribution
                  Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Content from Wikipedia, the free encyclopedia. CC BY-SA 4.0',
                          style: AppTextStyles.metadata(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ── Start Challenge CTA ──
                  if (article.quizAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/quiz', extra: article);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🧠', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            const Text('START CHALLENGE',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                )),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, delay: 500.ms)
                  else
                    GlassCard(
                      child: Center(
                        child: Text(
                          'No quiz available for this article yet',
                          style: AppTextStyles.body(color: AppColors.textMuted),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
