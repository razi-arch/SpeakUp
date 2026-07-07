import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../models/session_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../services/vocab_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text.dart';
import '../../widgets/symbol_card.dart';
import '../../widgets/word_pill.dart';

class AACBoardScreen extends ConsumerStatefulWidget {
  const AACBoardScreen({super.key});

  @override
  ConsumerState<AACBoardScreen> createState() => _AACBoardScreenState();
}

class _AACBoardScreenState extends ConsumerState<AACBoardScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<String> _sentence = [];
  final DateTime _sessionStart = DateTime.now();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts
      ..setLanguage('en-US')
      ..setSpeechRate(0.4)
      ..setVolume(1.0)
      ..setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _addWord(String word) => setState(() => _sentence.add(word));
  void _removeWord(int i) => setState(() => _sentence.removeAt(i));
  void _clear() => setState(() => _sentence.clear());

  Future<void> _speak() async {
    if (_sentence.isEmpty || _speaking) return;
    setState(() => _speaking = true);
    await _tts.speak(_sentence.join(' '));

    // Fire-and-forget session log
    final child = ref.read(activeChildProvider);
    if (child != null && mounted) {
      ref.read(sessionServiceProvider).createSession(SessionModel(
            id: '',
            childId: child.id,
            module: 'aac',
            accuracy: null,
            scoreStatus: 'not_applicable',
            wordsAttempted: _sentence.length,
            durationSeconds:
                DateTime.now().difference(_sessionStart).inSeconds,
            timestamp: DateTime.now(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final vocabAsync = ref.watch(vocabItemsProvider);

    // Map each category to the emoji of its first vocab item, so the
    // sidebar is navigable by non-readers (icon + label, not text-only).
    final categoryIcons = <String, String>{};
    for (final item in ref.watch(allVocabItemsProvider).valueOrNull ?? const <VocabItem>[]) {
      final trimmedEmoji = item.emoji.trim();
      if (trimmedEmoji.isNotEmpty) {
        categoryIcons.putIfAbsent(item.category, () => trimmedEmoji);
      }
    }

    // Auto-select first category once loaded
    ref.listen(categoriesProvider, (_, next) {
      final cats = next.valueOrNull;
      if (cats == null || cats.isEmpty) return;
      final current = ref.read(selectedCategoryProvider);
      if (current == null || !cats.contains(current)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedCategoryProvider.notifier).state = cats.first;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Category sidebar ──────────────────────────────────────────
            _CategorySidebar(
              categoriesAsync: categoriesAsync,
              categoryIcons: categoryIcons,
              selectedCategory: selectedCategory,
              onSelect: (cat) =>
                  ref.read(selectedCategoryProvider.notifier).state = cat,
            ),
            // ── Main area ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SentenceBar(
                    sentence: _sentence,
                    speaking: _speaking,
                    onRemove: _removeWord,
                    onClear: _clear,
                    onSpeak: _speak,
                  ),
                  Expanded(
                    child: _SymbolGrid(
                      vocabAsync: vocabAsync,
                      selectedCategory: selectedCategory,
                      onWordTap: _addWord,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate()
          .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut),
      ),
    );
  }
}

// ─── Category sidebar ─────────────────────────────────────────────────────────

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.categoriesAsync,
    required this.categoryIcons,
    required this.selectedCategory,
    required this.onSelect,
  });

  final AsyncValue<List<String>> categoriesAsync;
  final Map<String, String> categoryIcons;
  final String? selectedCategory;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          right: BorderSide(color: AppColors.ink4, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Home button
          const _SidebarHomeButton(),
          const Divider(color: AppColors.ink4, height: 1),
          // Category list
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.green, strokeWidth: 2),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (cats) {
                if (cats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No categories yet',
                        style: AppText.caption(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: cats.length,
                  itemBuilder: (_, i) => _CategoryItem(
                    label: cats[i],
                    icon: categoryIcons[cats[i]] ?? '🔖',
                    selected: cats[i] == selectedCategory,
                    onTap: () => onSelect(cats[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHomeButton extends StatelessWidget {
  const _SidebarHomeButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/child/home'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded,
                color: AppColors.green, size: 22),
            const SizedBox(height: 2),
            Text('Home', style: AppText.caption(color: AppColors.green)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        constraints: const BoxConstraints(minHeight: 64),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : Colors.transparent,
          borderRadius: AppRadius.md,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.symbolLabel(
                color: selected ? AppColors.green : AppColors.ink2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sentence bar ─────────────────────────────────────────────────────────────

class _SentenceBar extends StatelessWidget {
  const _SentenceBar({
    required this.sentence,
    required this.speaking,
    required this.onRemove,
    required this.onClear,
    required this.onSpeak,
  });

  final List<String> sentence;
  final bool speaking;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final hasWords = sentence.isNotEmpty;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          bottom: BorderSide(color: AppColors.ink4, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Word pills — scrollable
          Expanded(
            child: hasWords
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < sentence.length; i++) ...[
                          WordPill(
                            word: sentence[i],
                            onRemove: () => onRemove(i),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  )
                : Text(
                    'Tap symbols to build a sentence…',
                    style: AppText.body(color: AppColors.ink3),
                  ),
          ),
          const SizedBox(width: 12),
          // Clear button
          if (hasWords) ...[
            _BarButton(
              label: 'Clear',
              color: AppColors.ink2,
              bgColor: AppColors.bgCard,
              borderColor: AppColors.ink4,
              onTap: onClear,
            ),
            const SizedBox(width: 8),
          ],
          // Speak button
          _BarButton(
            label: speaking ? 'Speaking…' : '🔊 Speak',
            color: Colors.white,
            bgColor: hasWords && !speaking
                ? AppColors.green
                : AppColors.ink4,
            borderColor: Colors.transparent,
            shadowColor:
                hasWords && !speaking ? AppColors.greenDark : null,
            onTap: hasWords && !speaking ? onSpeak : null,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatefulWidget {
  const _BarButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    this.shadowColor,
    this.onTap,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.mid,
        curve: AppMotion.spring,
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        transformAlignment: Alignment.center,
        padding:
            const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: AppRadius.pill,
          border: Border.all(color: widget.borderColor, width: 1.5),
          boxShadow: widget.shadowColor != null
              ? [
                  BoxShadow(
                    color: widget.shadowColor!,
                    blurRadius: 0,
                    offset: Offset(0, _pressed ? 1 : 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: AppText.button(color: widget.color),
        ),
      ),
    );
  }
}

// ─── Symbol grid ──────────────────────────────────────────────────────────────

class _SymbolGrid extends StatelessWidget {
  const _SymbolGrid({
    required this.vocabAsync,
    required this.selectedCategory,
    required this.onWordTap,
  });

  final AsyncValue<List<VocabItem>> vocabAsync;
  final String? selectedCategory;
  final ValueChanged<String> onWordTap;

  @override
  Widget build(BuildContext context) {
    if (selectedCategory == null) {
      return Center(
        child: Text(
          'Select a category from the sidebar',
          style: AppText.body(color: AppColors.ink3),
        ),
      );
    }

    return vocabAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.green, strokeWidth: 3),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Could not load symbols',
            style: AppText.body(color: AppColors.ink3)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('No symbols in "$selectedCategory" yet',
                    style: AppText.heading()),
                const SizedBox(height: 6),
                Text('An admin can add vocab items from the dashboard.',
                    style: AppText.body(color: AppColors.ink3)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return SymbolCard(
              key: ValueKey(item.id),
              emoji: item.emoji,
              label: item.word,
              localImagePath: item.localImagePath,
              imageUrl: item.imageUrl,
              onTap: () => onWordTap(item.word),
            );
          },
        );
      },
    );
  }
}
