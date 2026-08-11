import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<ArticleSearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loading = true);
      try {
        final data = await ApiClient.instance.searchArticles(query.trim());
        if (!mounted) return;
        setState(() {
          _results = data.map((e) {
            final m = e as Map<String, dynamic>;
            return ArticleSearchResult(
              title: m['title'] as String? ?? 'Untitled',
              description: m['description'] as String?,
              thumbnailUrl: m['thumbnail_url'] as String?,
              url: m['url'] as String? ?? '',
            );
          }).toList();
        });
      } catch (_) {}
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Search Input Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        onChanged: _onSearch,
                        style: AppTextStyles.bodyMedium(),
                        decoration: InputDecoration(
                          hintText: 'Search Wikipedia topics...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, color: AppColors.textMuted),
                          suffixIcon: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Results List ──
              Expanded(
                child: _results.isEmpty && _ctrl.text.length >= 2 && !_loading
                    ? Center(
                        child: Text(
                          'No articles found for "${_ctrl.text}"',
                          style: AppTextStyles.body(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          return _SearchResultTile(result: r, index: i);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleSearchResult {
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String url;

  const ArticleSearchResult({
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.url,
  });
}

class _SearchResultTile extends StatelessWidget {
  final ArticleSearchResult result;
  final int index;
  const _SearchResultTile({required this.result, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => context.pop(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: AppTextStyles.bodyMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.description != null && result.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.description!,
                      style: AppTextStyles.metadata(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 25))
          .fadeIn(duration: 250.ms)
          .slideX(begin: 0.04),
    );
  }
}
