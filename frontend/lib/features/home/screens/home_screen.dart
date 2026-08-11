import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
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

    // Start fetching article (in background)
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

    setState(() => _isAnimating = false);

    // Navigate to reveal screen once loaded
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final roulette = ref.watch(rouletteProvider);
    final daily = ref.watch(dailyChallengeProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🎲', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text('WIKI ROULETTE',
                                style: AppTextStyles.overline(color: AppColors.accent)),
                          ],
                        ),
                        // Streak badge
                        if (user != null && user.currentStreak > 0)
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Text('${user.currentStreak}',
                                    style: AppTextStyles.bodyMedium(
                                        color: AppColors.streak)),
                              ],
                            ),
                          ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // ── Greeting ──
                    Text('${_greeting()},',
                        style: AppTextStyles.body(color: AppColors.textMuted)),
                    Text(user?.username ?? 'Explorer',
                        style: AppTextStyles.screenTitle()),
                    const SizedBox(height: 4),
                    Text('Ready to fall down a Wikipedia rabbit hole?',
                        style: AppTextStyles.body()),

                    const SizedBox(height: 48),

                    // ── SPIN Button ──
                    Center(
                      child: _SpinButton(
                        onTap: _onSpin,
                        isLoading: roulette.status == RouletteStatus.spinning,
                        glowCtrl: _glowCtrl,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Random discovery',
                        style: AppTextStyles.metadata(color: AppColors.textMuted),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Quick Actions ──
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: '📅',
                            label: 'DAILY\nCHALLENGE',
                            color: AppColors.warning,
                            onTap: () {}, // TODO: navigate to daily
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: '🔍',
                            label: 'SEARCH\nWIKI',
                            color: AppColors.secondaryAccent,
                            onTap: () => context.push('/search'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // ── Daily challenge card ──
                    daily.when(
                      data: (data) => data != null ? _DailyChallengeCard(data: data) : const SizedBox(),
                      loading: () => const SkeletonLoader(height: 90),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
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

class _SpinButtonState extends State<_SpinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: 150.ms);
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
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
              width: 200,
              height: 200,
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
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎲', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text('SPIN',
                            style: AppTextStyles.button().copyWith(
                              fontSize: 20,
                              letterSpacing: 3,
                              color: Colors.white,
                            )),
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
  late AnimationController _ctrl;
  late ScrollController _scrollCtrl;

  static const _categories = [
    '📜 History', '🌌 Space', '🧪 Biology',
    '🏛 Architecture', '⚙️ Physics', '🎨 Art',
    '💻 Technology', '🐾 Animals', '🌍 Geography',
    '🎬 Movies', '???', '🏆 Sports',
    '🎵 Music', '🍜 Food', '???',
  ];

  int _displayedIndex = 0;
  bool _revealed = false;
  String _discoveredText = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 2200.ms);
    _scrollCtrl = ScrollController();
    _startAnimation();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    // Cycle through categories fast, then slow
    for (int i = 0; i < 20; i++) {
      await Future.delayed(Duration(milliseconds: 60 + (i * 15)));
      if (!mounted) return;
      setState(() {
        _displayedIndex = (_displayedIndex + 1) % _categories.length;
      });
      HapticFeedback.selectionClick();
    }
    // Slow down
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 200 + (i * 80)));
      if (!mounted) return;
      setState(() {
        _displayedIndex = (_displayedIndex + 1) % _categories.length;
      });
    }

    await Future.delayed(500.ms);
    if (!mounted) return;
    setState(() => _revealed = true);
    HapticFeedback.heavyImpact();
    await Future.delayed(1200.ms);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: _revealed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✨', style: const TextStyle(fontSize: 48))
                      .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text('DISCOVERED',
                      style: AppTextStyles.overline(color: AppColors.accent)
                          .copyWith(fontSize: 14, letterSpacing: 4)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                key: ValueKey(_displayedIndex),
                children: [
                  Text('SPINNING...',
                      style: AppTextStyles.overline(color: AppColors.textMuted)
                          .copyWith(letterSpacing: 3)),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: 100.ms,
                    child: Text(
                      _categories[_displayedIndex],
                      key: ValueKey(_displayedIndex),
                      style: AppTextStyles.cardTitle()
                          .copyWith(fontSize: 22, color: AppColors.textPrimary),
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
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTextStyles.label(color: AppColors.textPrimary)
                    .copyWith(height: 1.4)),
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
  const _DailyChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final article = data['article'] as Map<String, dynamic>?;
    final title = article?['title'] as String? ?? 'Today\'s Challenge';
    final difficulty = article?['difficulty'] as String? ?? 'medium';

    return GlassCard(
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('📅', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY\'S WIKI',
                    style: AppTextStyles.overline(color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(title, style: AppTextStyles.bodyMedium(), maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Difficulty: ${difficulty[0].toUpperCase()}${difficulty.substring(1)}',
                    style: AppTextStyles.metadata()),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }
}
