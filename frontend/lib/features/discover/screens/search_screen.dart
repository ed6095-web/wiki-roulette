import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/models.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

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
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(400.ms, () async {
      setState(() => _loading = true);
      try {
        final data = await ApiClient.instance.searchArticles(query);
        if (!mounted) return;
        setState(() {
          _results = data.map((e) {
            final m = e as Map<String, dynamic>;
            return ArticleSearchResult(
              title: m['title'] as String,
              description: m['description'] as String?,
              thumbnailUrl: m['thumbnail_url'] as String?,
              url: m['url'] as String,
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
              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          hintText: 'Search Wikipedia...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          suffixIcon: _loading
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: AppColors.accent, strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Results ──
              Expanded(
                child: _results.isEmpty && _ctrl.text.length >= 2 && !_loading
                    ? Center(
                        child: Text('No results found for "${_ctrl.text}"',
                            style: AppTextStyles.body(color: AppColors.textMuted),
                            textAlign: TextAlign.center),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () {
          // For search results, navigate back with the selected article title
          // The user can then use the article via the random endpoint or by title
          context.pop();
        },
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🌐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: AppTextStyles.bodyMedium(),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (result.description != null && result.description!.isNotEmpty)
                    Text(result.description!,
                        style: AppTextStyles.metadata(),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 30))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05);
  }
}
