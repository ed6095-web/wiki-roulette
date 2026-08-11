import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = _extractKeyFacts(article);
    final categoryName =
        article.categories.isNotEmpty ? article.categories.first.name : 'Knowledge';
    final categoryIcon = _iconForCategory(categoryName);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Clean Vector App Bar ──
            SliverAppBar(
              expandedHeight: 140,
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
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E1B4B),
                        Color(0xFF0A0A0E),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(categoryIcon, size: 48, color: AppColors.accent.withOpacity(0.4)),
                  ),
                ),
              ),
            ),

            // ── Article Content ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

                  // ── Start Quiz CTA (Overflow-Proof) ──
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
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'START CHALLENGE',
                                style: AppTextStyles.button(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
