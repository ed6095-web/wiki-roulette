import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _spinCtrl;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSpin() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);
    HapticFeedback.mediumImpact();

    // Start fetching article
    ref.read(rouletteProvider.notifier).spin();

    // Play spin animation
    _spinCtrl.forward(from: 0);

    // Show roulette overlay
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (_) => const _RouletteOverlay(),
      );
    }

    if (mounted) setState(() => _isAnimating = false);

    final state = ref.read(rouletteProvider);
    if (state.article != null && mounted) {
      context.push('/article/reveal', extra: state.article!);
    } else if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.error!),
        backgroundColor: AppColors.error,
      ));
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).profile;
    final roulette = ref.watch(rouletteProvider);
    final daily = ref.watch(dailyChallengeProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Press back again to exit Wiki Roulette',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.surfaceElevated,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: AtmosphericBackground(
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
                    // ── Header Bar ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.casino_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('WIKI ROULETTE',
                                style: AppTextStyles.overline(color: AppColors.accent)),
                          ],
                        ),

                        // Streak badge
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.streak,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.currentStreak}',
                                style: AppTextStyles.bodyMedium(color: AppColors.streak),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    // ── Greeting ──
                    Text('${_greeting()},',
                        style: AppTextStyles.body(color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      user.name,
                      style: AppTextStyles.screenTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to explore the unknown?',
                      style: AppTextStyles.body(),
                    ),

                    const SizedBox(height: 36),

                    // ── Central SPIN Button ──
                    Center(
                      child: _SpinButton(
                        onTap: _onSpin,
                        isLoading: roulette.status == RouletteStatus.spinning,
                        glowCtrl: _glowCtrl,
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Tap to discover an article',
                        style: AppTextStyles.metadata(color: AppColors.textMuted),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Quick Actions ──
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.auto_stories_rounded,
                            label: 'DISCOVER\nTOPICS',
                            color: AppColors.secondaryAccent,
                            onTap: () => context.go('/discover'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.search_rounded,
                            label: 'SEARCH\nWIKIPEDIA',
                            color: AppColors.accent,
                            onTap: () => context.push('/search'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // ── Daily Challenge Card ──
                    daily.when(
                      data: (data) => data != null
                          ? _DailyChallengeCard(
                              data: data,
                              onTap: () {
                                final articleMap = data['article'] as Map<String, dynamic>?;
                                final article = ArticleModel.fromJson(articleMap ??
                                    {
                                      'id': 10,
                                      'wiki_page_id': 10,
                                      'title': 'James Webb Space Telescope',
                                      'slug': 'James_Webb_Space_Telescope',
                                      'url':
                                          'https://en.wikipedia.org/wiki/James_Webb_Space_Telescope',
                                      'description': 'Space telescope for infrared astronomy',
                                      'extract':
                                          'The James Webb Space Telescope is a space telescope designed primarily to conduct infrared astronomy.',
                                      'difficulty': 'medium',
                                      'quiz_available': true,
                                      'categories': [
                                        {'id': 1, 'name': 'Space', 'icon': 'space'}
                                      ],
                                    });
                                context.push('/article/reveal', extra: article);
                              },
                            )
                          : const SizedBox(),
                      loading: () => const SkeletonLoader(height: 80),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Spin Button
// ──────────────────────────────────────────────────────
class _SpinButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final AnimationController glowCtrl;

  const _SpinButton({
    required this.onTap,
    required this.isLoading,
    required this.glowCtrl,
  });

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: 150.ms);
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.glowCtrl, _scale]),
      builder: (_, child) {
        final glowOpacity = 0.3 + (widget.glowCtrl.value * 0.4);
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: (_) => _pressCtrl.forward(),
            onTapUp: (_) {
              _pressCtrl.reverse();
              widget.onTap();
            },
            onTapCancel: () => _pressCtrl.reverse(),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B72FF), Color(0xFF6D28D9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(glowOpacity),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.casino_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SPIN',
                          style: AppTextStyles.button().copyWith(
                            fontSize: 18,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────
// Roulette Animation Overlay
// ──────────────────────────────────────────────────────
class _RouletteOverlay extends StatefulWidget {
  const _RouletteOverlay();

  @override
  State<_RouletteOverlay> createState() => _RouletteOverlayState();
}

class _RouletteOverlayState extends State<_RouletteOverlay>
    with SingleTickerProviderStateMixin {
  static const List<(String, IconData)> _categories = [
    ('History', Icons.history_edu_rounded),
    ('Space & Astronomy', Icons.rocket_launch_rounded),
    ('Science & Physics', Icons.biotech_rounded),
    ('Architecture', Icons.apartment_rounded),
    ('Technology', Icons.memory_rounded),
    ('Arts & Culture', Icons.palette_rounded),
    ('Wildlife & Animals', Icons.pets_rounded),
    ('World Geography', Icons.public_rounded),
    ('Cinema & Film', Icons.movie_rounded),
    ('Global Sports', Icons.sports_volleyball_rounded),
  ];

  int _displayedIndex = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < 18; i++) {
      await Future.delayed(Duration(milliseconds: 60 + (i * 12)));
      if (!mounted) return;
      setState(() {
        _displayedIndex = (_displayedIndex + 1) % _categories.length;
      });
      HapticFeedback.selectionClick();
    }
    for (int i = 0; i < 4; i++) {
      await Future.delayed(Duration(milliseconds: 180 + (i * 70)));
      if (!mounted) return;
      setState(() {
        _displayedIndex = (_displayedIndex + 1) % _categories.length;
      });
    }

    await Future.delayed(400.ms);
    if (!mounted) return;
    setState(() => _revealed = true);
    HapticFeedback.heavyImpact();
    await Future.delayed(900.ms);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = _categories[_displayedIndex];

    return Center(
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: _revealed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accent,
                      size: 48,
                    ),
                  ).animate().scale(duration: 350.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    'DISCOVERED',
                    style: AppTextStyles.overline(color: AppColors.accent).copyWith(
                      fontSize: 14,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                key: ValueKey(_displayedIndex),
                children: [
                  Text(
                    'FINDING ARTICLE...',
                    style: AppTextStyles.overline(color: AppColors.textMuted)
                        .copyWith(letterSpacing: 3),
                  ),
                  const SizedBox(height: 20),
                  Icon(current.$2, color: AppColors.accent, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    current.$1,
                    style: AppTextStyles.cardTitle().copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Quick Action Card
// ──────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label(color: AppColors.textPrimary).copyWith(height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Daily Challenge Card
// ──────────────────────────────────────────────────────
class _DailyChallengeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _DailyChallengeCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final article = data['article'] as Map<String, dynamic>?;
    final title = article?['title'] as String? ?? 'Daily Discovery';
    final difficulty = article?['difficulty'] as String? ?? 'medium';

    return GlassCard(
      onTap: onTap,
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.today_rounded, color: AppColors.warning, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY CHALLENGE',
                    style: AppTextStyles.overline(color: AppColors.warning)),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Difficulty: ${difficulty[0].toUpperCase()}${difficulty.substring(1)}',
                  style: AppTextStyles.metadata(),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
