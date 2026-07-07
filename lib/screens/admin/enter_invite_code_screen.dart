import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/primary_button.dart';

// ─── Screen state ─────────────────────────────────────────────────────────────

enum _Status { idle, loading, success, error }

// ─── Screen ───────────────────────────────────────────────────────────────────

class EnterInviteCodeScreen extends ConsumerStatefulWidget {
  const EnterInviteCodeScreen({super.key});

  @override
  ConsumerState<EnterInviteCodeScreen> createState() =>
      _EnterInviteCodeScreenState();
}

class _EnterInviteCodeScreenState
    extends ConsumerState<EnterInviteCodeScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  _Status _status = _Status.idle;
  String? _errorMessage;
  String? _linkedChildName;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Redeem logic ───────────────────────────────────────────────────────────

  Future<void> _link() async {
    if (_ctrl.text.length != 6 || _status == _Status.loading) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _status = _Status.loading);
    _focus.unfocus();

    try {
      final child = await ref
          .read(inviteServiceProvider)
          .redeemCode(_ctrl.text, uid);
      if (!mounted) return;
      setState(() {
        _status          = _Status.success;
        _linkedChildName = child.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status       = _Status.error;
        _errorMessage = _mapError(e.toString());
      });
    }
  }

  static String _mapError(String msg) {
    if (msg.contains('already used')) {
      return 'This code has already been used.';
    }
    if (msg.contains('expired')) {
      return 'This code has expired. Ask the admin to generate a new one.';
    }
    if (msg.contains('Invalid') || msg.contains('invalid')) {
      return 'Code not found. Please check the digits and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _reset() {
    _ctrl.clear();
    setState(() {
      _status       = _Status.idle;
      _errorMessage = null;
      _linkedChildName = null;
    });
    _focus.requestFocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _ctrl.text.length == 6 && _status != _Status.loading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSidebar(currentPath: '/admin/link-code'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(),
                  const Divider(color: AppColors.ink4, height: 1),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 32),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔗',
                                  style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text('Link a Child Profile',
                                  style: AppText.heading()),
                              const SizedBox(height: 6),
                              Text(
                                'Enter the 6-digit invite code generated when the child profile was created.',
                                style:
                                    AppText.body(color: AppColors.ink3),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              // ── OTP input ─────────────────────────
                              _OtpInput(
                                ctrl:     _ctrl,
                                focus:    _focus,
                                enabled:  _status != _Status.success,
                                onChanged: (_) => setState(() {
                                  _status       = _Status.idle;
                                  _errorMessage = null;
                                }),
                              ),
                              const SizedBox(height: 28),
                              // ── Status feedback ───────────────────
                              if (_status == _Status.error &&
                                  _errorMessage != null)
                                _FeedbackBanner(
                                  key: const ValueKey('error'),
                                  message: _errorMessage!,
                                  isSuccess: false,
                                ),
                              if (_status == _Status.success &&
                                  _linkedChildName != null)
                                _FeedbackBanner(
                                  key: const ValueKey('success'),
                                  message:
                                      '${_linkedChildName!} has been linked to your account! 🎉',
                                  isSuccess: true,
                                ),
                              const SizedBox(height: 28),
                              // ── Action button ─────────────────────
                              if (_status == _Status.success) ...[
                                PrimaryButton(
                                  label: 'View Dashboard →',
                                  width: 280,
                                  onPressed: () =>
                                      context.go('/admin/dashboard'),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _reset,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Link another code',
                                      style: AppText.caption(
                                          color: AppColors.ink3),
                                    ),
                                  ),
                                ),
                              ] else if (_status == _Status.loading)
                                Container(
                                  width: 280,
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
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  ),
                                )
                              else
                                PrimaryButton(
                                  label: 'Link Child',
                                  width: 280,
                                  onPressed: canSubmit ? _link : null,
                                ),
                            ],
                          ).animate()
                            .fadeIn(
                                duration: AppMotion.slow,
                                curve: AppMotion.easeOut)
                            .slideY(
                                begin: 0.03,
                                end: 0,
                                duration: AppMotion.slow,
                                curve: AppMotion.easeOut),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Text('Link Code', style: AppText.heading()),
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

// ─── OTP input ────────────────────────────────────────────────────────────────

/// Six digit boxes backed by a single invisible TextField.
/// The invisible field sits exactly over the visual display so tapping
/// anywhere on the row naturally opens the keyboard.
class _OtpInput extends StatefulWidget {
  const _OtpInput({
    required this.ctrl,
    required this.focus,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  // Width of the digit row: 6 boxes × 56dp + 5 gaps × 10dp
  static const _rowWidth  = 6 * 56.0 + 5 * 10.0;
  static const _rowHeight = 68.0;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final code     = widget.ctrl.text;
    final hasFocus = widget.focus.hasFocus;

    return GestureDetector(
      onTap: widget.enabled ? () => widget.focus.requestFocus() : null,
      child: SizedBox(
        width: _rowWidth,
        height: _rowHeight,
        child: Stack(
          children: [
            // ── Visual digit boxes ────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 6; i++) ...[
                  _DigitBox(
                    digit:    code.length > i ? code[i] : null,
                    isActive: hasFocus && code.length == i,
                    filled:   code.length > i,
                  ),
                  if (i < 5) const SizedBox(width: 10),
                ],
              ],
            ),
            // ── Invisible input ───────────────────────────────────
            if (widget.enabled)
              SizedBox(
                width: _rowWidth,
                height: _rowHeight,
                child: TextField(
                  controller: widget.ctrl,
                  focusNode: widget.focus,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  showCursor: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 0.1,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.filled,
  });

  final String? digit;
  final bool isActive;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (filled) {
      borderColor = AppColors.green;
    } else if (isActive) {
      borderColor = AppColors.green;
    } else {
      borderColor = AppColors.ink4;
    }

    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 56,
      height: 68,
      decoration: BoxDecoration(
        color: filled ? AppColors.greenLight : AppColors.bgCard,
        borderRadius: AppRadius.md,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isActive ? AppShadows.sm : [],
      ),
      alignment: Alignment.center,
      child: digit != null
          ? Text(
              digit!,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0,
              ),
            )
          : isActive
              ? _Cursor()
              : const SizedBox.shrink(),
    );
  }
}

/// Blinking cursor shown in the active empty box.
class _Cursor extends StatefulWidget {
  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 32,
        color: AppColors.green,
      ),
    );
  }
}

// ─── Feedback banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isSuccess,
    super.key,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final bg     = isSuccess ? AppColors.greenLight : AppColors.roseLight;
    final border = isSuccess ? AppColors.greenMid    : AppColors.roseMid;
    final fg     = isSuccess ? AppColors.green       : AppColors.rose;
    final icon   = isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.md,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppText.body(color: fg)),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.mid, curve: AppMotion.easeOut)
        .slideY(
            begin: -0.08,
            end: 0,
            duration: AppMotion.mid,
            curve: AppMotion.easeOut);
  }
}
