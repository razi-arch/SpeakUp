import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../models/session_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../services/reward_logic.dart';
import '../../services/vocab_fill_blank_service.dart';
import '../../services/vocab_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/vocab_image.dart';
import '../../widgets/feedback_toast.dart';
import '../../widgets/spring_tap.dart';

enum _AnswerState { idle, correct, wrong }

enum _VocabMode { guided, fillBlank }

class VocabLearningScreen extends ConsumerStatefulWidget {
  const VocabLearningScreen({super.key});

  @override
  ConsumerState<VocabLearningScreen> createState() =>
      _VocabLearningScreenState();
}

class _VocabLearningScreenState extends ConsumerState<VocabLearningScreen> {
  _VocabMode? _mode;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.mid,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: switch (_mode) {
            null => _VocabModePicker(
                key: const ValueKey('vocab-mode-picker'),
                onGoHome: () => context.go('/child/home'),
                onSelectMode: (mode) => setState(() => _mode = mode),
              ),
            _VocabMode.guided => _GuidedVocabActivity(
                key: const ValueKey('guided-vocab'),
                onBackToModes: () => setState(() => _mode = null),
              ),
            _VocabMode.fillBlank => _FillBlankVocabActivity(
                key: const ValueKey('fill-blank-vocab'),
                onBackToModes: () => setState(() => _mode = null),
              ),
          },
        ),
      ),
    );
  }
}

class _VocabModePicker extends StatelessWidget {
  const _VocabModePicker({
    required this.onGoHome,
    required this.onSelectMode,
    super.key,
  });

  final VoidCallback onGoHome;
  final ValueChanged<_VocabMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onGoHome,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.ink4, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.home_rounded,
                        color: AppColors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text('Home', style: AppText.caption(color: AppColors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Vocab Learning', style: AppText.display()),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to practise today.',
            style: AppText.body(color: AppColors.ink3),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 900;
                if (stacked) {
                  return Column(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          title: 'Guided Questions',
                          subtitle:
                              'See a picture, listen carefully, and choose the correct word.',
                          accent: AppColors.amber,
                          softColor: AppColors.amberLight,
                          icon: Icons.quiz_rounded,
                          buttonLabel: 'Start Guided',
                          onTap: () => onSelectMode(_VocabMode.guided),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _ModeCard(
                          title: 'Fill in the Blank',
                          subtitle:
                              'Read a short sentence and pick the word that completes it.',
                          accent: AppColors.green,
                          softColor: AppColors.greenLight,
                          icon: Icons.edit_note_rounded,
                          buttonLabel: 'Start Fill in the Blank',
                          onTap: () => onSelectMode(_VocabMode.fillBlank),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        title: 'Guided Questions',
                        subtitle:
                            'See a picture, listen carefully, and choose the correct word.',
                        accent: AppColors.amber,
                        softColor: AppColors.amberLight,
                        icon: Icons.quiz_rounded,
                        buttonLabel: 'Start Guided',
                        onTap: () => onSelectMode(_VocabMode.guided),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _ModeCard(
                        title: 'Fill in the Blank',
                        subtitle:
                            'Read a short sentence and pick the word that completes it.',
                        accent: AppColors.green,
                        softColor: AppColors.greenLight,
                        icon: Icons.edit_note_rounded,
                        buttonLabel: 'Start Fill in the Blank',
                        onTap: () => onSelectMode(_VocabMode.fillBlank),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ).animate().fadeIn(
            duration: AppMotion.slow,
            curve: AppMotion.easeOut,
          ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.softColor,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Color softColor;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [softColor, AppColors.bgCard],
          ),
          borderRadius: AppRadius.xl,
          border: Border.all(color: accent.withValues(alpha: 0.22), width: 1.5),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: AppRadius.lg,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 30),
            ),
            const Spacer(),
            Text(title, style: AppText.heading(color: accent)),
            const SizedBox(height: 8),
            Text(subtitle, style: AppText.body(color: AppColors.ink2)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: AppRadius.pill,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                buttonLabel,
                style: AppText.button(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidedVocabActivity extends ConsumerStatefulWidget {
  const _GuidedVocabActivity({required this.onBackToModes, super.key});

  final VoidCallback onBackToModes;

  @override
  ConsumerState<_GuidedVocabActivity> createState() =>
      _GuidedVocabActivityState();
}

class _GuidedVocabActivityState extends ConsumerState<_GuidedVocabActivity> {
  static const _targetQuestions = 5;
  static const _correctReveal = Duration(milliseconds: 1200);
  static const _wrongReveal = Duration(seconds: 4);

  final FlutterTts _tts = FlutterTts();
  final Random _rng = Random();

  List<VocabItem> _allItems = const [];
  String? _localCategory;
  List<VocabItem>? _items;
  int _currentIndex = 0;
  List<VocabItem> _choices = const [];
  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _selectedId;
  _AnswerState _answerState = _AnswerState.idle;
  DateTime _sessionStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tts
      ..setLanguage('en-US')
      ..setSpeechRate(0.45)
      ..setVolume(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  List<String> get _categories => _allItems
      .map((item) => item.category)
      .toSet()
      .toList()
    ..sort();

  void _syncItems(List<VocabItem> allItems, int qaMode) {
    _allItems = allItems;
    final categories = _categories;
    if (categories.isEmpty) {
      setState(() {
        _localCategory = null;
        _items = const [];
        _choices = const [];
      });
      return;
    }

    final targetCategory =
        (_localCategory != null && categories.contains(_localCategory))
            ? _localCategory!
            : categories.first;

    if (_localCategory != targetCategory || _items == null) {
      _selectCategory(targetCategory, qaMode);
      return;
    }

    final refreshed = _allItems
        .where((item) => item.category == _localCategory)
        .toList();
    if (_items!.length != refreshed.length) {
      _selectCategory(_localCategory!, qaMode);
    }
  }

  void _selectCategory(String category, int qaMode) {
    final filtered =
        _allItems.where((item) => item.category == category).toList();
    _initGame(category, filtered, qaMode);
  }

  void _initGame(String category, List<VocabItem> items, int qaMode) {
    if (items.isEmpty) {
      setState(() {
        _localCategory = category;
        _items = const [];
        _choices = const [];
      });
      return;
    }

    final shuffled = [...items]..shuffle(_rng);
    final effectiveCount = min(qaMode, shuffled.length);
    setState(() {
      _localCategory = category;
      _items = shuffled;
      _currentIndex = 0;
      _choices = _buildChoices(shuffled, shuffled[0], effectiveCount);
      _correctCount = 0;
      _totalAttempts = 0;
      _selectedId = null;
      _answerState = _AnswerState.idle;
      _sessionStart = DateTime.now();
    });
  }

  List<VocabItem> _buildChoices(
    List<VocabItem> items,
    VocabItem correct,
    int count,
  ) {
    final pool = items.where((item) => item.id != correct.id).toList()
      ..shuffle(_rng);
    return [correct, ...pool.take(count - 1)]..shuffle(_rng);
  }

  void _advanceItem(int qaMode) {
    final items = _items!;
    final nextIndex = (_currentIndex + 1) % items.length;
    final effectiveCount = min(qaMode, items.length);
    setState(() {
      _currentIndex = nextIndex;
      _choices = _buildChoices(items, items[nextIndex], effectiveCount);
      _selectedId = null;
      _answerState = _AnswerState.idle;
    });
  }

  Future<void> _onAnswerTap(VocabItem choice, int qaMode) async {
    if (_answerState != _AnswerState.idle || _items == null) return;

    final correct = _items![_currentIndex];
    final isCorrect = choice.id == correct.id;

    setState(() {
      _selectedId = choice.id;
      _answerState = isCorrect ? _AnswerState.correct : _AnswerState.wrong;
      _totalAttempts++;
    });

    FeedbackToast.show(
      context,
      message: isCorrect
          ? 'Great job!'
          : 'Nice try. The correct answer is ${correct.word}.',
      isCorrect: isCorrect,
      duration: isCorrect ? _correctReveal : _wrongReveal,
    );

    if (isCorrect) {
      _correctCount++;
    }

    await Future.delayed(isCorrect ? _correctReveal : _wrongReveal);
    if (!mounted) return;

    if (_totalAttempts >= _targetQuestions) {
      await _finishSession();
      if (mounted) context.go('/child/reward');
    } else {
      _advanceItem(qaMode);
    }
  }

  Future<void> _finishSession() async {
    final child = ref.read(activeChildProvider);
    if (child == null) return;

    final accuracy = _totalAttempts > 0 ? _correctCount / _totalAttempts : 0.0;
    ref.read(pendingRewardSummaryProvider.notifier).state = SessionRewardSummary(
      module: 'vocab',
      earnedStars: vocabStarsForAccuracy(accuracy),
      accuracy: accuracy,
      questionCount: _totalAttempts,
      correctCount: _correctCount,
    );

    await ref.read(sessionServiceProvider).createSession(
          SessionModel(
            id: '',
            childId: child.id,
            module: 'vocab',
            activityType: 'guided',
            accuracy: accuracy,
            scoreStatus: 'reviewed',
            wordsAttempted: _totalAttempts,
            durationSeconds:
                DateTime.now().difference(_sessionStart).inSeconds,
            timestamp: DateTime.now(),
          ),
        );
  }

  Future<void> _speakWord(String word) => _tts.speak(word);

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    final allVocabAsync = ref.watch(allVocabItemsProvider);

    if (child == null) {
      return const SizedBox.shrink();
    }

    ref.listen(allVocabItemsProvider, (_, next) {
      final allItems = next.valueOrNull;
      if (allItems == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncItems(allItems, child.qaMode);
      });
    });

    final seededItems = allVocabAsync.valueOrNull;
    if (seededItems != null && _allItems.isEmpty) {
      _syncItems(seededItems, child.qaMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityBar(
          title: 'Guided Questions',
          categories: _categories,
          selectedCategory: _localCategory,
          onSelectCategory: (category) => _selectCategory(category, child.qaMode),
          onBackToModes: widget.onBackToModes,
        ),
        const Divider(color: AppColors.ink4, height: 1),
        Expanded(
          child: _buildGameArea(
            qaMode: child.qaMode,
            loading: allVocabAsync.isLoading && _allItems.isEmpty,
          ),
        ),
      ],
    ).animate().fadeIn(
          duration: AppMotion.slow,
          curve: AppMotion.easeOut,
        );
  }

  Widget _buildGameArea({
    required int qaMode,
    required bool loading,
  }) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 3,
        ),
      );
    }

    if (_categories.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No words yet',
        body: 'An admin can add vocab items from the dashboard.',
      );
    }

    if (_localCategory == null) {
      return Center(
        child: Text(
          'Select a category above',
          style: AppText.body(color: AppColors.ink3),
        ),
      );
    }

    if (_items == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 3,
        ),
      );
    }

    if (_items!.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No words in this category yet',
        body: 'An admin can add vocab items from the dashboard.',
      );
    }

    final currentItem = _items![_currentIndex];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _GuidedPromptCard(
              item: currentItem,
              onSpeak: () => _speakWord(currentItem.word),
            ).animate(key: ValueKey(currentItem.id))
              .fadeIn(duration: AppMotion.mid, curve: AppMotion.easeOut)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: AppMotion.mid,
                curve: AppMotion.easeOut,
              ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _GuidedAnswerPanel(
              choices: _choices,
              correctId: currentItem.id,
              selectedId: _selectedId,
              answerState: _answerState,
              correctCount: _correctCount,
              targetCorrect: _targetQuestions,
              revealDuration:
                  _answerState == _AnswerState.wrong ? _wrongReveal : null,
              qaMode: qaMode,
              onTap: (choice) => _onAnswerTap(choice, qaMode),
            ),
          ),
        ],
      ),
    );
  }
}

class _FillBlankVocabActivity extends ConsumerStatefulWidget {
  const _FillBlankVocabActivity({required this.onBackToModes, super.key});

  final VoidCallback onBackToModes;

  @override
  ConsumerState<_FillBlankVocabActivity> createState() =>
      _FillBlankVocabActivityState();
}

class _FillBlankVocabActivityState
    extends ConsumerState<_FillBlankVocabActivity> {
  static const _targetQuestions = 5;
  static const _correctReveal = Duration(milliseconds: 1200);
  static const _wrongReveal = Duration(seconds: 4);
  static const VocabFillBlankService _promptService = VocabFillBlankService();

  final Random _rng = Random();

  List<VocabItem> _allItems = const [];
  List<String> _availableCategories = const [];
  String? _localCategory;
  List<FillBlankPrompt>? _prompts;
  int _currentIndex = 0;
  List<VocabItem> _choices = const [];
  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _selectedId;
  _AnswerState _answerState = _AnswerState.idle;
  DateTime _sessionStart = DateTime.now();

  void _syncItems(
    List<VocabItem> allItems,
    String difficulty,
    int qaMode,
  ) {
    _allItems = allItems;
    _availableCategories = _promptService.availableCategories(
      items: allItems,
      difficulty: difficulty,
      qaMode: qaMode,
    );

    if (_availableCategories.isEmpty) {
      setState(() {
        _localCategory = null;
        _prompts = const [];
        _choices = const [];
      });
      return;
    }

    final targetCategory =
        (_localCategory != null && _availableCategories.contains(_localCategory))
            ? _localCategory!
            : _availableCategories.first;

    if (_localCategory != targetCategory || _prompts == null) {
      _selectCategory(targetCategory, difficulty, qaMode);
    }
  }

  void _selectCategory(
    String category,
    String difficulty,
    int qaMode,
  ) {
    final categoryItems =
        _allItems.where((item) => item.category == category).toList();
    final prompts = _promptService.promptsForCategory(
      items: categoryItems,
      difficulty: difficulty,
      qaMode: qaMode,
    );
    _initGame(category, prompts, qaMode);
  }

  void _initGame(
    String category,
    List<FillBlankPrompt> prompts,
    int qaMode,
  ) {
    if (prompts.isEmpty) {
      setState(() {
        _localCategory = category;
        _prompts = const [];
        _choices = const [];
      });
      return;
    }

    final shuffled = [...prompts]..shuffle(_rng);
    final effectiveCount = min(qaMode, shuffled.length);
    setState(() {
      _localCategory = category;
      _prompts = shuffled;
      _currentIndex = 0;
      _choices = _buildChoices(shuffled, shuffled[0], effectiveCount);
      _correctCount = 0;
      _totalAttempts = 0;
      _selectedId = null;
      _answerState = _AnswerState.idle;
      _sessionStart = DateTime.now();
    });
  }

  List<VocabItem> _buildChoices(
    List<FillBlankPrompt> prompts,
    FillBlankPrompt correct,
    int count,
  ) {
    final pool = prompts
        .where((prompt) => prompt.item.id != correct.item.id)
        .map((prompt) => prompt.item)
        .toList()
      ..shuffle(_rng);
    return [correct.item, ...pool.take(count - 1)]..shuffle(_rng);
  }

  void _advanceItem(int qaMode) {
    final prompts = _prompts!;
    final nextIndex = (_currentIndex + 1) % prompts.length;
    final effectiveCount = min(qaMode, prompts.length);
    setState(() {
      _currentIndex = nextIndex;
      _choices = _buildChoices(prompts, prompts[nextIndex], effectiveCount);
      _selectedId = null;
      _answerState = _AnswerState.idle;
    });
  }

  Future<void> _onAnswerTap(VocabItem choice, int qaMode) async {
    if (_answerState != _AnswerState.idle || _prompts == null) return;

    final correct = _prompts![_currentIndex].item;
    final isCorrect = choice.id == correct.id;

    setState(() {
      _selectedId = choice.id;
      _answerState = isCorrect ? _AnswerState.correct : _AnswerState.wrong;
      _totalAttempts++;
    });

    FeedbackToast.show(
      context,
      message: isCorrect
          ? 'Great job!'
          : 'Nice try. The correct answer is ${correct.word}.',
      isCorrect: isCorrect,
      duration: isCorrect ? _correctReveal : _wrongReveal,
    );

    if (isCorrect) {
      _correctCount++;
    }

    await Future.delayed(isCorrect ? _correctReveal : _wrongReveal);
    if (!mounted) return;

    if (_totalAttempts >= _targetQuestions) {
      await _finishSession();
      if (mounted) context.go('/child/reward');
    } else {
      _advanceItem(qaMode);
    }
  }

  Future<void> _finishSession() async {
    final child = ref.read(activeChildProvider);
    if (child == null) return;

    final accuracy = _totalAttempts > 0 ? _correctCount / _totalAttempts : 0.0;
    ref.read(pendingRewardSummaryProvider.notifier).state = SessionRewardSummary(
      module: 'vocab',
      earnedStars: vocabStarsForAccuracy(accuracy),
      accuracy: accuracy,
      questionCount: _totalAttempts,
      correctCount: _correctCount,
    );

    await ref.read(sessionServiceProvider).createSession(
          SessionModel(
            id: '',
            childId: child.id,
            module: 'vocab',
            activityType: 'fill_blank',
            accuracy: accuracy,
            scoreStatus: 'reviewed',
            wordsAttempted: _totalAttempts,
            durationSeconds:
                DateTime.now().difference(_sessionStart).inSeconds,
            timestamp: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    final allVocabAsync = ref.watch(allVocabItemsProvider);

    if (child == null) {
      return const SizedBox.shrink();
    }

    ref.listen(allVocabItemsProvider, (_, next) {
      final allItems = next.valueOrNull;
      if (allItems == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncItems(allItems, child.difficulty, child.qaMode);
      });
    });

    final seededItems = allVocabAsync.valueOrNull;
    if (seededItems != null && _allItems.isEmpty) {
      _syncItems(seededItems, child.difficulty, child.qaMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityBar(
          title: 'Fill in the Blank',
          categories: _availableCategories,
          selectedCategory: _localCategory,
          onSelectCategory: (category) =>
              _selectCategory(category, child.difficulty, child.qaMode),
          onBackToModes: widget.onBackToModes,
        ),
        const Divider(color: AppColors.ink4, height: 1),
        Expanded(
          child: _buildGameArea(
            qaMode: child.qaMode,
            loading: allVocabAsync.isLoading && _allItems.isEmpty,
          ),
        ),
      ],
    ).animate().fadeIn(
          duration: AppMotion.slow,
          curve: AppMotion.easeOut,
        );
  }

  Widget _buildGameArea({
    required int qaMode,
    required bool loading,
  }) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.green,
          strokeWidth: 3,
        ),
      );
    }

    if (_availableCategories.isEmpty) {
      return const _EmptyState(
        icon: Icons.edit_note_rounded,
        title: 'No fill-in-the-blank words yet',
        body:
            'This activity appears when a category has enough natural-fit words to make a sentence.',
      );
    }

    if (_localCategory == null) {
      return Center(
        child: Text(
          'Select a category above',
          style: AppText.body(color: AppColors.ink3),
        ),
      );
    }

    if (_prompts == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.green,
          strokeWidth: 3,
        ),
      );
    }

    if (_prompts!.isEmpty) {
      return const _EmptyState(
        icon: Icons.edit_note_rounded,
        title: 'No fill-in-the-blank words here',
        body:
            'Try another category or add more simple single-word vocab items for this category.',
      );
    }

    final currentPrompt = _prompts![_currentIndex];
    final sentence = _answerState == _AnswerState.idle
        ? currentPrompt.sentenceWithBlank
        : currentPrompt.sentenceWithAnswer;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _FillPromptCard(
              item: currentPrompt.item,
              sentence: sentence,
              showVisualHint: currentPrompt.showVisualHint,
              isCorrect: _answerState != _AnswerState.idle,
            ).animate(key: ValueKey('${currentPrompt.item.id}-$sentence'))
              .fadeIn(duration: AppMotion.mid, curve: AppMotion.easeOut)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: AppMotion.mid,
                curve: AppMotion.easeOut,
              ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _FillAnswerPanel(
              choices: _choices,
              correctId: currentPrompt.item.id,
              selectedId: _selectedId,
              answerState: _answerState,
              correctCount: _correctCount,
              targetCorrect: _targetQuestions,
              revealDuration:
                  _answerState == _AnswerState.wrong ? _wrongReveal : null,
              qaMode: qaMode,
              onTap: (choice) => _onAnswerTap(choice, qaMode),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.title,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onBackToModes,
  });

  final String title;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onBackToModes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          _BarButton(
            icon: Icons.home_rounded,
            label: 'Home',
            color: AppColors.green,
            onTap: () => context.go('/child/home'),
          ),
          _BarButton(
            icon: Icons.grid_view_rounded,
            label: 'Modes',
            color: AppColors.ink2,
            onTap: onBackToModes,
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      title,
                      style: AppText.heading(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                        child: Text(
                          title,
                          style: AppText.caption(color: AppColors.ink3),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final category = categories[index];
                            final isSelected = category == selectedCategory;
                            return GestureDetector(
                              onTap: () => onSelectCategory(category),
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                curve: AppMotion.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.amberLight
                                      : AppColors.bgCard,
                                  borderRadius: AppRadius.pill,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.amberMid
                                        : AppColors.ink4,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: AppText.button(
                                    color: isSelected
                                        ? AppColors.amberDark
                                        : AppColors.ink2,
                                  ),
                                ),
                              ),
                            );
                          },
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

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.ink4, width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label, style: AppText.caption(color: color)),
          ],
        ),
      ),
    );
  }
}

class _GuidedPromptCard extends StatelessWidget {
  const _GuidedPromptCard({
    required this.item,
    required this.onSpeak,
  });

  final VocabItem item;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImage()),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.ink4, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.word,
                    style: AppText.display(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _SpeakButton(onTap: onSpeak),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return VocabImage(
      localImagePath: item.localImagePath,
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      placeholder: Container(
        color: AppColors.amberLight,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 2,
        ),
      ),
      fallback: _EmojiPlaceholder(emoji: item.emoji),
    );
  }
}

class _GuidedAnswerPanel extends StatelessWidget {
  const _GuidedAnswerPanel({
    required this.choices,
    required this.correctId,
    required this.selectedId,
    required this.answerState,
    required this.correctCount,
    required this.targetCorrect,
    required this.revealDuration,
    required this.qaMode,
    required this.onTap,
  });

  final List<VocabItem> choices;
  final String correctId;
  final String? selectedId;
  final _AnswerState answerState;
  final int correctCount;
  final int targetCorrect;
  final Duration? revealDuration;
  final int qaMode;
  final ValueChanged<VocabItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What is this?',
          style: AppText.heading(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ChoiceGrid(
            qaMode: qaMode,
            itemCount: choices.length,
            itemBuilder: (index) => _TextChoiceButton(
              item: choices[index],
              correctId: correctId,
              selectedId: selectedId,
              answerState: answerState,
              onTap: onTap,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StarProgress(current: correctCount, total: targetCorrect),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: revealDuration == null
              ? const SizedBox(
                  key: ValueKey('guided-no-reveal'),
                  height: 6,
                )
              : _RevealCountdownBar(
                  key: ValueKey('guided-$selectedId-$correctId'),
                  duration: revealDuration!,
                ),
        ),
      ],
    );
  }
}

class _FillPromptCard extends StatelessWidget {
  const _FillPromptCard({
    required this.item,
    required this.sentence,
    required this.showVisualHint,
    required this.isCorrect,
  });

  final VocabItem item;
  final String sentence;
  final bool showVisualHint;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.lg,
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Fill in the blank',
              style: AppText.caption(color: AppColors.green),
            ),
          ),
          if (showVisualHint) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 170,
              child: _PromptVisual(item: item),
            ),
          ],
          const Spacer(),
          Text(
            'Choose the word that completes the sentence.',
            style: AppText.body(color: AppColors.ink3),
          ),
          const SizedBox(height: 18),
          AnimatedDefaultTextStyle(
            duration: AppMotion.mid,
            curve: AppMotion.easeOut,
            style: AppText.display(
              color: isCorrect ? AppColors.green : AppColors.ink,
            ),
            child: Text(sentence),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PromptVisual extends StatelessWidget {
  const _PromptVisual({required this.item});

  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    return VocabImage(
      localImagePath: item.localImagePath,
      imageUrl: item.imageUrl,
      fit: BoxFit.contain,
      borderRadius: AppRadius.lg,
      fallback: _ChoiceEmojiFallback(emoji: item.emoji),
    );
  }
}

class _FillAnswerPanel extends StatelessWidget {
  const _FillAnswerPanel({
    required this.choices,
    required this.correctId,
    required this.selectedId,
    required this.answerState,
    required this.correctCount,
    required this.targetCorrect,
    required this.revealDuration,
    required this.qaMode,
    required this.onTap,
  });

  final List<VocabItem> choices;
  final String correctId;
  final String? selectedId;
  final _AnswerState answerState;
  final int correctCount;
  final int targetCorrect;
  final Duration? revealDuration;
  final int qaMode;
  final ValueChanged<VocabItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick the missing word',
          style: AppText.heading(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ChoiceGrid(
            qaMode: qaMode,
            itemCount: choices.length,
            itemBuilder: (index) => _VisualChoiceButton(
              item: choices[index],
              correctId: correctId,
              selectedId: selectedId,
              answerState: answerState,
              onTap: onTap,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StarProgress(current: correctCount, total: targetCorrect),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: revealDuration == null
              ? const SizedBox(
                  key: ValueKey('fill-no-reveal'),
                  height: 6,
                )
              : _RevealCountdownBar(
                  key: ValueKey('fill-$selectedId-$correctId'),
                  duration: revealDuration!,
                ),
        ),
      ],
    );
  }
}

class _RevealCountdownBar extends StatelessWidget {
  const _RevealCountdownBar({
    required this.duration,
    super.key,
  });

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: duration,
        curve: Curves.linear,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.ink5,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
          );
        },
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.qaMode,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int qaMode;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (qaMode <= 2 || itemCount <= 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: itemBuilder(0)),
          const SizedBox(width: 12),
          if (itemCount > 1) Expanded(child: itemBuilder(1)),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: itemBuilder(0)),
              const SizedBox(width: 12),
              Expanded(child: itemBuilder(1)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: itemBuilder(2)),
              const SizedBox(width: 12),
              if (itemCount > 3) Expanded(child: itemBuilder(3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextChoiceButton extends StatelessWidget {
  const _TextChoiceButton({
    required this.item,
    required this.correctId,
    required this.selectedId,
    required this.answerState,
    required this.onTap,
  });

  final VocabItem item;
  final String correctId;
  final String? selectedId;
  final _AnswerState answerState;
  final ValueChanged<VocabItem> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == item.id;
    final answered = answerState != _AnswerState.idle;
    final isThisCorrect = item.id == correctId;
    final revealCorrect =
        answerState == _AnswerState.wrong && isThisCorrect && !isSelected;

    Color bg;
    Color border;
    Color textColor;

    if (isSelected) {
      if (answerState == _AnswerState.correct) {
        bg = AppColors.greenLight;
        border = AppColors.green;
        textColor = AppColors.green;
      } else {
        bg = AppColors.roseLight;
        border = AppColors.rose;
        textColor = AppColors.rose;
      }
    } else if (revealCorrect) {
      bg = AppColors.greenLight;
      border = AppColors.green;
      textColor = AppColors.green;
    } else {
      bg = AppColors.bgCard;
      border = AppColors.ink4;
      textColor = AppColors.ink;
    }

    final dimmed = answered && !isSelected && !revealCorrect;

    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: SpringTap(
        onTap: answered ? null : () => onTap(item),
        child: AnimatedContainer(
          duration: AppMotion.mid,
          curve: AppMotion.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.lg,
            border: Border.all(color: border, width: 2),
            boxShadow: AppShadows.sm,
          ),
          child: Text(
            item.word,
            style: AppText.title(color: textColor),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _VisualChoiceButton extends StatelessWidget {
  const _VisualChoiceButton({
    required this.item,
    required this.correctId,
    required this.selectedId,
    required this.answerState,
    required this.onTap,
  });

  final VocabItem item;
  final String correctId;
  final String? selectedId;
  final _AnswerState answerState;
  final ValueChanged<VocabItem> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == item.id;
    final answered = answerState != _AnswerState.idle;
    final isThisCorrect = item.id == correctId;
    final revealCorrect =
        answerState == _AnswerState.wrong && isThisCorrect && !isSelected;

    Color bg;
    Color border;
    Color textColor;

    if (isSelected) {
      if (answerState == _AnswerState.correct) {
        bg = AppColors.greenLight;
        border = AppColors.green;
        textColor = AppColors.green;
      } else {
        bg = AppColors.roseLight;
        border = AppColors.rose;
        textColor = AppColors.rose;
      }
    } else if (revealCorrect) {
      bg = AppColors.greenLight;
      border = AppColors.green;
      textColor = AppColors.green;
    } else {
      bg = AppColors.bgCard;
      border = AppColors.ink4;
      textColor = AppColors.ink;
    }

    final dimmed = answered && !isSelected && !revealCorrect;

    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: SpringTap(
        onTap: answered ? null : () => onTap(item),
        child: AnimatedContainer(
          duration: AppMotion.mid,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.lg,
            border: Border.all(color: border, width: 2),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _ChoiceVisual(item: item)),
              const SizedBox(height: 10),
              Text(
                item.word,
                style: AppText.title(color: textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceVisual extends StatelessWidget {
  const _ChoiceVisual({required this.item});

  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    return VocabImage(
      localImagePath: item.localImagePath,
      imageUrl: item.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: AppRadius.md,
      fallback: _ChoiceEmojiFallback(emoji: item.emoji),
    );
  }
}

class _ChoiceEmojiFallback extends StatelessWidget {
  const _ChoiceEmojiFallback({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final trimmedEmoji = emoji.trim();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        borderRadius: AppRadius.md,
      ),
      alignment: Alignment.center,
      child: trimmedEmoji.isNotEmpty
          ? Text(trimmedEmoji, style: const TextStyle(fontSize: 54))
          : const Icon(
              Icons.image_outlined,
              size: 44,
              color: AppColors.ink3,
            ),
    );
  }
}

class _EmojiPlaceholder extends StatelessWidget {
  const _EmojiPlaceholder({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final trimmedEmoji = emoji.trim();
    return Container(
      color: AppColors.amberLight,
      alignment: Alignment.center,
      child: trimmedEmoji.isNotEmpty
          ? Text(trimmedEmoji, style: const TextStyle(fontSize: 96))
          : const Icon(
              Icons.image_outlined,
              size: 72,
              color: AppColors.ink3,
            ),
    );
  }
}

class _SpeakButton extends StatefulWidget {
  const _SpeakButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<_SpeakButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.mid,
        curve: AppMotion.spring,
        width: 52,
        height: 52,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        transformAlignment: Alignment.center,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.skyDark,
              blurRadius: 0,
              offset: Offset(0, _pressed ? 1 : 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _StarProgress extends StatelessWidget {
  const _StarProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < total; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: AppMotion.mid,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                index < current ? Icons.star_rounded : Icons.star_border_rounded,
                key: ValueKey('star_$index-${index < current}'),
                color: index < current ? AppColors.amber : AppColors.ink4,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.ink3),
          const SizedBox(height: 16),
          Text(title, style: AppText.heading()),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.body(color: AppColors.ink3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
