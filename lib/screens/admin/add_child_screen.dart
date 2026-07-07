import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

// ─── Avatar presets ───────────────────────────────────────────────────────────

// (emoji, gradientStart hex, gradientEnd hex)
const _avatarPresets = [
  ('🦁', '#E8F7F1', '#2D9B6F'),
  ('🐰', '#E8F3FA', '#3D8FBF'),
  ('🐻', '#FEF4DC', '#F0A500'),
  ('🦊', '#FCEEE9', '#E8634A'),
  ('🐼', '#F5F4F2', '#57534E'),
  ('🦋', '#F3E8FF', '#7C3AED'),
  ('🐸', '#DCFCE7', '#16A34A'),
  ('🦄', '#FCE7F3', '#DB2777'),
  ('🐯', '#FEF3C7', '#D97706'),
  ('🦉', '#E0E7FF', '#4F46E5'),
  ('🐨', '#DBEAFE', '#1D4ED8'),
  ('🐧', '#D1FAE5', '#065F46'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  int    _avatar     = 0;
  String _difficulty = 'beginner';
  int    _qaMode     = 2;
  bool   _submitting = false;
  String? _generatedCode;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Create & generate ──────────────────────────────────────────────────────

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Please enter the child's name.");
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() { _submitting = true; _error = null; });

    try {
      final preset = _avatarPresets[_avatar];
      final child = ChildModel(
        id: '',
        name: name,
        avatarEmoji: preset.$1,
        avatarGradientStart: preset.$2,
        avatarGradientEnd: preset.$3,
        difficulty: _difficulty,
        qaMode: _qaMode,
        linkedUsers: [uid],
        createdBy: uid,
        isActiveOnDevice: false,
      );

      final childId = await ref.read(childServiceProvider).createChild(child);
      final code    = await ref.read(inviteServiceProvider).generateCode(childId, uid);

      if (!mounted) return;
      setState(() { _submitting = false; _generatedCode = code; });
    } catch (e) {
      if (mounted) {
        setState(() { _submitting = false; _error = 'Failed to create profile. Please try again.'; });
      }
    }
  }

  void _reset() => setState(() {
    _nameCtrl.clear();
    _avatar = 0;
    _difficulty = 'beginner';
    _qaMode = 2;
    _generatedCode = null;
    _error = null;
  });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSidebar(currentPath: '/admin/add-child'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(),
                  const Divider(color: AppColors.ink4, height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Form ──────────────────────────────────
                          Expanded(
                            flex: 5,
                            child: _FormPanel(
                              nameCtrl:   _nameCtrl,
                              avatar:     _avatar,
                              difficulty: _difficulty,
                              qaMode:     _qaMode,
                              submitting: _submitting,
                              error:      _error,
                              onAvatarSelect: (i) =>
                                  setState(() => _avatar = i),
                              onDifficultySelect: (d) =>
                                  setState(() => _difficulty = d),
                              onQaModeSelect: (m) =>
                                  setState(() => _qaMode = m),
                              onCreate: _create,
                            ),
                          ),
                          const SizedBox(width: 24),
                          // ── Code panel ────────────────────────────
                          Expanded(
                            flex: 3,
                            child: _CodePanel(
                              code: _generatedCode,
                              onCreateAnother: _reset,
                            ),
                          ),
                        ],
                      ),
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Text('Add Child', style: AppText.heading()),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/admin/dashboard'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '← Dashboard',
                style: AppText.caption(color: AppColors.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form panel ───────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.nameCtrl,
    required this.avatar,
    required this.difficulty,
    required this.qaMode,
    required this.submitting,
    required this.error,
    required this.onAvatarSelect,
    required this.onDifficultySelect,
    required this.onQaModeSelect,
    required this.onCreate,
  });

  final TextEditingController nameCtrl;
  final int avatar;
  final String difficulty;
  final int qaMode;
  final bool submitting;
  final String? error;
  final ValueChanged<int> onAvatarSelect;
  final ValueChanged<String> onDifficultySelect;
  final ValueChanged<int> onQaModeSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name
          _FormLabel("Child's name"),
          const SizedBox(height: 6),
          _NameField(controller: nameCtrl),
          const SizedBox(height: 22),

          // Avatar picker
          _FormLabel('Choose avatar'),
          const SizedBox(height: 10),
          _AvatarPicker(
            selected: avatar,
            onSelect: onAvatarSelect,
          ),
          const SizedBox(height: 22),

          // Difficulty
          _FormLabel('Learning difficulty'),
          const SizedBox(height: 8),
          _ChipSelector(
            options: const [
              ('Beginner', 'beginner'),
              ('Intermediate', 'intermediate'),
              ('Advanced', 'advanced'),
            ],
            selected: difficulty,
            onSelect: onDifficultySelect,
          ),
          const SizedBox(height: 22),

          // Q&A mode
          _FormLabel('Q&A choices'),
          const SizedBox(height: 4),
          Text(
            'How many answer choices to show during vocab learning',
            style: AppText.caption(),
          ),
          const SizedBox(height: 8),
          _ChipSelector(
            options: const [
              ('2 choices (easier)', '2'),
              ('4 choices (harder)', '4'),
            ],
            selected: '$qaMode',
            onSelect: (v) => onQaModeSelect(int.parse(v)),
          ),
          const SizedBox(height: 28),

          // Error
          if (error != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.roseLight,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.roseMid, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.rose, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: AppText.caption(color: AppColors.rose)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit
          if (submitting)
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
            )
          else
            PrimaryButton(
              label: 'Create Profile & Generate Code',
              width: double.infinity,
              onPressed: onCreate,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.title());
}

// ─── Name field ───────────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppText.body(),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide:
              const BorderSide(color: AppColors.ink4, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide:
              const BorderSide(color: AppColors.green, width: 1.5),
        ),
        hintText: "e.g. Sarah",
        hintStyle: AppText.body(color: AppColors.ink3),
      ),
    );
  }
}

// ─── Avatar picker ────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static Color _hex(String h) {
    final c = h.replaceFirst('#', '');
    return Color(int.parse('FF$c', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _avatarPresets.length,
      itemBuilder: (_, i) {
        final (emoji, start, end) = _avatarPresets[i];
        final isSelected = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_hex(start), _hex(end)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: isSelected
                  ? Border.all(color: AppColors.green, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: isSelected ? AppShadows.sm : [],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        );
      },
    );
  }
}

// ─── Chip selector ────────────────────────────────────────────────────────────

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i].$2),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == options[i].$2
                      ? AppColors.green
                      : AppColors.bgCard,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: selected == options[i].$2
                        ? AppColors.green
                        : AppColors.ink4,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i].$1,
                  style: AppText.button(
                    color: selected == options[i].$2
                        ? Colors.white
                        : AppColors.ink2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (i < options.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

// ─── Code panel ───────────────────────────────────────────────────────────────

class _CodePanel extends StatefulWidget {
  const _CodePanel({required this.code, required this.onCreateAnother});
  final String? code;
  final VoidCallback onCreateAnother;

  @override
  State<_CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<_CodePanel> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code!));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.md,
      ),
      padding: const EdgeInsets.all(28),
      child: widget.code == null ? _empty() : _withCode(),
    );
  }

  Widget _empty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📋', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Invite code', style: AppText.heading()),
        const SizedBox(height: 8),
        Text(
          'Fill in the form and create a profile — an invite code will appear here.',
          style: AppText.body(color: AppColors.ink3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _withCode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('Profile created!',
            style: AppText.heading(), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'Share this code with the parent or teacher',
          style: AppText.body(color: AppColors.ink3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        // Code display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: AppRadius.xl,
            border: Border.all(color: AppColors.greenMid, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.code!,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Copy button
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: _copied
              ? Container(
                  key: const ValueKey('copied'),
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.greenMid, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('✓ Copied!',
                      style: AppText.button(color: AppColors.green)),
                )
              : SecondaryButton(
                  key: const ValueKey('copy'),
                  label: 'Copy Code',
                  width: double.infinity,
                  onPressed: _copy,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          'Expires in 48 hours',
          style: AppText.caption(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: widget.onCreateAnother,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '+ Add another child',
              style: AppText.caption(color: AppColors.green),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
        .slideY(begin: 0.04, end: 0, duration: AppMotion.slow,
            curve: AppMotion.easeOut);
  }
}
