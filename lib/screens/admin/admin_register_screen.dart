import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/spring_tap.dart';

// â”€â”€â”€ Data collected across all steps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RegData {
  String role        = '';
  String fullName    = '';
  String icNumber    = '';
  String email       = '';
  String phone       = '';
  String address     = '';
  String schoolName  = '';
  String qualification = '';
  String specialisation = '';
  String yearsExp    = '';
  String password    = '';
  String pinCode     = '';
}

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _data       = _RegData();
  final _controller = PageController();

  bool get _isTeacher => _data.role == 'teacher';

  // Fixed 5-page layout â€” count never changes:
  // 0 = Role Selection
  // 1 = Personal Info
  // 2 = Professional Info  (teacher goes here; parent skips over it)
  // 3 = Password
  // 4 = Success

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: AppMotion.slow,
      curve: AppMotion.easeOut,
    );
  }

  void _onRoleSelected(String role) => setState(() => _data.role = role);

  void _nextFromRole()         => _data.role.isNotEmpty ? _goTo(1) : null;
  void _nextFromPersonal()     => _isTeacher ? _goTo(2) : _goTo(3);
  void _nextFromProfessional() => _goTo(3);
  void _onSuccess()            => _goTo(4);

  void _backFromPassword()     => _isTeacher ? _goTo(2) : _goTo(1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Page 0 â€” Role Selection
            _RoleSelectionPage(
              selectedRole: _data.role,
              onRoleSelected: _onRoleSelected,
              onContinue: _nextFromRole,
            ),
            // Page 1 â€” Personal Info
            _FormPage(
              data: _data,
              step: _RegStep.personal,
              sidebarStep: 1,
              onBack: () => _goTo(0),
              onNext: _nextFromPersonal,
            ),
            // Page 2 â€” Professional Info (teacher only; parent never lands here)
            _FormPage(
              data: _data,
              step: _RegStep.professional,
              sidebarStep: 2,
              onBack: () => _goTo(1),
              onNext: _nextFromProfessional,
            ),
            // Page 3 â€” Password
            _PasswordPage(
              data: _data,
              sidebarStep: _isTeacher ? 3 : 2,
              onBack: _backFromPassword,
              onSuccess: _onSuccess,
            ),
            // Page 4 â€” Success
            _SuccessPage(),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Step enum â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _RegStep { personal, professional }

// â”€â”€â”€ Page 0 â€” Role Selection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleSelectionPage extends StatelessWidget {
  const _RoleSelectionPage({
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onContinue,
  });

  final String   selectedRole;
  final void Function(String) onRoleSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenLight, AppColors.bg, AppColors.skyLight],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.waving_hand_rounded,
                  size: 56,
                  color: AppColors.green,
                ),
                const SizedBox(height: 16),
                Text('How will you use SpeakUp?', style: AppText.heading()),
                const SizedBox(height: 8),
                Text(
                  'Choose your role to get started',
                  style: AppText.body(color: AppColors.ink3),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        emoji: '',
                        title: 'Teacher',
                        description:
                            'School or therapy centre staff managing multiple children',
                        selected: selectedRole == 'teacher',
                        accent: AppColors.green,
                        accentLight: AppColors.greenLight,
                        onTap: () => onRoleSelected('teacher'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleCard(
                        emoji: '',
                        title: 'Parent',
                        description:
                            'Family member supporting their child at home',
                        selected: selectedRole == 'parent',
                        accent: AppColors.sky,
                        accentLight: AppColors.skyLight,
                        onTap: () => onRoleSelected('parent'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: selectedRole.isNotEmpty
                      ? Container(
                          key: ValueKey(selectedRole),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedRole == 'teacher'
                                ? AppColors.greenLight
                                : AppColors.skyLight,
                            borderRadius: AppRadius.md,
                          ),
                          child: Text(
                            selectedRole == 'teacher'
                                ? '4 quick steps â€” includes your professional details'
                                : '3 quick steps â€” you can add your child\'s profile after signing in',
                            style: AppText.caption(
                              color: selectedRole == 'teacher'
                                  ? AppColors.green
                                  : AppColors.sky,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), height: 0),
                ),
                const SizedBox(height: 28),
                AnimatedOpacity(
                  opacity: selectedRole.isNotEmpty ? 1.0 : 0.4,
                  duration: AppMotion.fast,
                  child: PrimaryButton(
                    label: 'Continue',
                    width: double.infinity,
                    onPressed: selectedRole.isNotEmpty ? onContinue : null,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go('/admin/login'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: Text(
                      'Back to sign in',
                      style: AppText.caption(color: AppColors.ink3),
                    ),
                  ),
                ),
              ],
            ).animate()
              .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
              .slideY(
                begin: 0.03, end: 0,
                duration: AppMotion.slow, curve: AppMotion.easeOut),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.selected,
    required this.accent,
    required this.accentLight,
    required this.onTap,
  });

  final String   emoji;
  final String   title;
  final String   description;
  final bool     selected;
  final Color    accent;
  final Color    accentLight;
  final VoidCallback onTap;

  IconData get _icon {
    switch (title) {
      case 'Teacher':
        return Icons.school_rounded;
      case 'Parent':
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? accentLight : AppColors.bgCard,
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: selected ? accent : AppColors.ink4,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? AppShadows.md : AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 36, color: accent),
            const SizedBox(height: 10),
            Text(title, style: AppText.title()),
            const SizedBox(height: 6),
            Text(description,
                style: AppText.body(color: AppColors.ink3),
                maxLines: 3),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Sidebar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.role,
    required this.currentStep, // 1-based: 1=Personal, 2=Professional, 3/4=Password
  });

  final String role;
  final int    currentStep;

  bool get _isTeacher => role == 'teacher';

  @override
  Widget build(BuildContext context) {
    final steps = _isTeacher
        ? ['Personal Info', 'Professional Info', 'Set Password']
        : ['Personal Info', 'Set Password'];

    return Container(
      width: 220,
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('SpeakUp!',
                  style: AppText.title(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 36),
          // Steps
          for (int i = 0; i < steps.length; i++) ...[
            _SidebarStep(
              number: i + 1,
              label: steps[i],
              state: i + 1 < currentStep
                  ? _StepState.done
                  : i + 1 == currentStep
                      ? _StepState.active
                      : _StepState.upcoming,
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
          ],
          const Spacer(),
          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isTeacher
                  ? AppColors.green.withValues(alpha: 0.2)
                  : AppColors.sky.withValues(alpha: 0.2),
              borderRadius: AppRadius.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isTeacher
                      ? Icons.school_rounded
                      : Icons.family_restroom_rounded,
                  size: 16,
                  color: _isTeacher ? AppColors.greenMid : AppColors.skyMid,
                ),
                const SizedBox(width: 6),
                Text(
                  _isTeacher ? 'Teacher' : 'Parent',
                  style: AppText.caption(
                    color: _isTeacher ? AppColors.greenMid : AppColors.skyMid,
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

enum _StepState { done, active, upcoming }

class _SidebarStep extends StatelessWidget {
  const _SidebarStep({
    required this.number,
    required this.label,
    required this.state,
  });

  final int        number;
  final String     label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isActive   = state == _StepState.active;
    final isDone     = state == _StepState.done;
    final textOpacity = isDone ? 0.6 : (isActive ? 1.0 : 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDone || isActive)
                  ? AppColors.green
                  : Colors.white.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 13)
                : Text(
                    '$number',
                    style: AppText.caption(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: textOpacity,
              child: Text(label,
                  style: AppText.caption(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Page layout wrapper (sidebar + scrollable form) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FormLayout extends StatelessWidget {
  const _FormLayout({
    required this.role,
    required this.step,
    required this.child,
  });

  final String role;
  final int    step; // 1-based sidebar step
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Sidebar(role: role, currentStep: step),
        Expanded(
          child: Container(
            color: AppColors.bg,
            child: child,
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Shared form field widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String                    label;
  final TextEditingController     controller;
  final String?                   hint;
  final String?                   error;
  final bool                      obscure;
  final TextInputType             keyboardType;
  final TextInputAction           textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int                       maxLines;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused      = false;
  bool _showPassword = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  bool get _filled =>
      widget.controller.text.isNotEmpty && widget.error == null;
  bool get _hasError => widget.error != null && widget.error!.isNotEmpty;

  Color get _borderColor {
    if (_hasError)  return AppColors.rose;
    if (_focused)   return AppColors.green;
    if (_filled)    return AppColors.greenMid;
    return AppColors.ink4;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.caption()),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: (_hasError ? AppColors.roseMid : AppColors.greenMid)
                          .withValues(alpha: 0.55),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller:       widget.controller,
            focusNode:        _focus,
            obscureText:      widget.obscure && !_showPassword,
            keyboardType:     widget.keyboardType,
            textInputAction:  widget.textInputAction,
            inputFormatters:  widget.inputFormatters,
            maxLines:         widget.obscure ? 1 : widget.maxLines,
            onChanged:        (_) => setState(() {}),
            style:            AppText.body(),
            decoration: InputDecoration(
              filled:       true,
              fillColor:    AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: _borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: _borderColor, width: 1.5),
              ),
              hintText:  widget.hint ?? widget.label,
              hintStyle: AppText.body(color: AppColors.ink3),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.ink3,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    )
                  : null,
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 4),
          Text(widget.error!,
              style: AppText.caption(color: AppColors.rose)),
        ],
      ],
    );
  }
}

// â”€â”€â”€ IC Number formatter: 000000-00-0000 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IcFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i == 6 || i == 8) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

// â”€â”€â”€ Page 1 â€” Personal Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FormPage extends StatefulWidget {
  const _FormPage({
    required this.data,
    required this.step,
    required this.sidebarStep,
    required this.onBack,
    required this.onNext,
  });

  final _RegData     data;
  final _RegStep     step;
  final int          sidebarStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  // Personal controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _icCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  // Professional controllers
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _qualCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _yearsCtrl;

  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill from data so back-nav restores values
    _nameCtrl    = TextEditingController(text: widget.data.fullName);
    _icCtrl      = TextEditingController(text: widget.data.icNumber);
    _emailCtrl   = TextEditingController(text: widget.data.email);
    _phoneCtrl   = TextEditingController(text: widget.data.phone);
    _addressCtrl = TextEditingController(text: widget.data.address);
    _schoolCtrl  = TextEditingController(text: widget.data.schoolName);
    _qualCtrl    = TextEditingController(text: widget.data.qualification);
    _specCtrl    = TextEditingController(text: widget.data.specialisation);
    _yearsCtrl   = TextEditingController(text: widget.data.yearsExp);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _icCtrl, _emailCtrl, _phoneCtrl, _addressCtrl,
                     _schoolCtrl, _qualCtrl, _specCtrl, _yearsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // â”€â”€ Validators â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool _validatePersonal() {
    final errs = <String, String>{};

    if (_nameCtrl.text.trim().isEmpty) {
      errs['name'] = 'Full name is required.';
    }

    final ic = _icCtrl.text.replaceAll('-', '');
    if (ic.length != 12 || !RegExp(r'^\d{12}$').hasMatch(ic)) {
      errs['ic'] = 'Enter a valid IC number (e.g. 900101-01-1234).';
    }

    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(email)) {
      errs['email'] = 'Enter a valid email address.';
    }

    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^(\+?60|0)[1-9][0-9]{7,9}$').hasMatch(phone)) {
      errs['phone'] = 'Enter a valid Malaysian phone number (e.g. 0123456789).';
    }

    if (_addressCtrl.text.trim().isEmpty) {
      errs['address'] = 'Home address is required.';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  bool _validateProfessional() {
    final errs = <String, String>{};

    if (_schoolCtrl.text.trim().isEmpty) {
      errs['school'] = 'School or centre name is required.';
    }
    if (_qualCtrl.text.trim().isEmpty) {
      errs['qual'] = 'Highest qualification is required.';
    }
    if (_specCtrl.text.trim().isEmpty) {
      errs['spec'] = 'Specialisation is required.';
    }
    final yrs = int.tryParse(_yearsCtrl.text.trim());
    if (yrs == null || yrs < 0 || yrs > 60) {
      errs['years'] = 'Enter valid years of experience.';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  void _next() {
    if (widget.step == _RegStep.personal) {
      if (!_validatePersonal()) return;

      widget.data
        ..fullName = _nameCtrl.text.trim()
        ..icNumber = _icCtrl.text.trim()
        ..email    = _emailCtrl.text.trim()
        ..phone    = _phoneCtrl.text.trim()
        ..address  = _addressCtrl.text.trim();

      widget.onNext();
    } else {
      if (!_validateProfessional()) return;

      widget.data
        ..schoolName     = _schoolCtrl.text.trim()
        ..qualification  = _qualCtrl.text.trim()
        ..specialisation = _specCtrl.text.trim()
        ..yearsExp       = _yearsCtrl.text.trim();

      widget.onNext();
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final isPersonal = widget.step == _RegStep.personal;

    return _FormLayout(
      role: widget.data.role,
      step: widget.sidebarStep,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isPersonal ? 'Personal Information' : 'Professional Details',
              style: AppText.heading(),
            ),
            const SizedBox(height: 4),
            Text(
              isPersonal
                  ? 'Tell us a bit about yourself'
                  : 'Your professional background',
              style: AppText.body(color: AppColors.ink3),
            ),
            const SizedBox(height: 28),

            if (isPersonal) ..._personalFields()
            else            ..._professionalFields(),

            const SizedBox(height: 32),
            Row(
              children: [
                SecondaryButton(
                  label: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.ink2,
                  ),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Continue',
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    width: double.infinity,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _personalFields() => [
    _Field(
      label: 'Full Name *',
      controller: _nameCtrl,
      hint: 'e.g. Siti Aishah binti Ahmad',
      error: _errors['name'],
    ),
    const SizedBox(height: 16),
    _Field(
      label: 'IC / ID Number *',
      controller: _icCtrl,
      hint: '000000-00-0000',
      error: _errors['ic'],
      keyboardType: TextInputType.number,
      inputFormatters: [_IcFormatter()],
    ),
    const SizedBox(height: 16),
    _Field(
      label: 'Email Address *',
      controller: _emailCtrl,
      hint: 'you@example.com',
      error: _errors['email'],
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 16),
    _Field(
      label: 'Phone Number *',
      controller: _phoneCtrl,
      hint: 'e.g. 0123456789',
      error: _errors['phone'],
      keyboardType: TextInputType.phone,
    ),
    const SizedBox(height: 16),
    _Field(
      label: 'Home Address *',
      controller: _addressCtrl,
      hint: 'Street, City, State',
      error: _errors['address'],
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 2,
    ),
  ];

  List<Widget> _professionalFields() => [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.greenMid, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 18,
                color: AppColors.green,
              ),
              const SizedBox(width: 6),
              Text('School / Centre Details',
                  style: AppText.caption(color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'School / Centre Name *',
            controller: _schoolCtrl,
            hint: 'e.g. SK Bukit Damansara',
            error: _errors['school'],
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Highest Qualification *',
            controller: _qualCtrl,
            hint: 'e.g. Bachelor of Special Education',
            error: _errors['qual'],
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Specialisation *',
            controller: _specCtrl,
            hint: 'e.g. Autism Spectrum Disorder',
            error: _errors['spec'],
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Years of Experience *',
            controller: _yearsCtrl,
            hint: 'e.g. 5',
            error: _errors['years'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ink5,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.ink3),
          const SizedBox(width: 6),
          Text(
            'Your professional info is not shared publicly.',
            style: AppText.caption(color: AppColors.ink3),
          ),
        ],
      ),
    ),
  ];
}

// â”€â”€â”€ Password page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PasswordPage extends ConsumerStatefulWidget {
  const _PasswordPage({
    required this.data,
    required this.sidebarStep,
    required this.onBack,
    required this.onSuccess,
  });

  final _RegData     data;
  final int          sidebarStep;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<_PasswordPage> {
  final _pwCtrl      = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  final Map<String, String> _errors = {};
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  bool get _isParent => widget.data.role == 'parent';

  bool _validate() {
    final errs = <String, String>{};
    final pw = _pwCtrl.text;

    if (pw.length < 8) {
      errs['pw'] = 'Password must be at least 8 characters.';
    } else if (!pw.contains(RegExp(r'[A-Z]'))) {
      errs['pw'] = 'Password must contain at least one uppercase letter.';
    } else if (!pw.contains(RegExp(r'[0-9]'))) {
      errs['pw'] = 'Password must contain at least one number.';
    }

    if (_confirmCtrl.text != pw) {
      errs['confirm'] = 'Passwords do not match.';
    }

    final pin = _pinCtrl.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      errs['pin'] = 'PIN must be exactly 4 digits.';
    }

    if (_pinConfirmCtrl.text.trim() != pin) {
      errs['pinConfirm'] = 'PINs do not match.';
    }

    setState(() {
      _errors..clear()..addAll(errs);
    });
    return errs.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    widget.data.password = _pwCtrl.text;
    widget.data.pinCode = _pinCtrl.text.trim();

    setState(() { _submitting = true; _submitError = null; });

    try {
      final profileData = <String, dynamic>{
        'fullName':  widget.data.fullName,
        'icNumber':  widget.data.icNumber,
        'phone':     widget.data.phone,
        'address':   widget.data.address,
        // Teacher fields â€” always written; null for parents
        'schoolName':     _isParent ? null : widget.data.schoolName,
        'qualification':  _isParent ? null : widget.data.qualification,
        'specialisation': _isParent ? null : widget.data.specialisation,
        'yearsExp':       _isParent
            ? null
            : int.tryParse(widget.data.yearsExp),
        'pinCode': widget.data.pinCode,
      };

      await ref.read(authServiceProvider).register(
        email:       widget.data.email,
        password:    widget.data.password,
        role:        widget.data.role,
        profileData: profileData,
      );

      if (mounted) widget.onSuccess();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = _mapError(e.toString());
        });
      }
    }
  }

  static String _mapError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Registration failed. Please try again.';
  }

  // Strength bar â€” 0..4
  int get _strength {
    final pw = _pwCtrl.text;
    int s = 0;
    if (pw.length >= 8)                          s++;
    if (pw.contains(RegExp(r'[A-Z]')))           s++;
    if (pw.contains(RegExp(r'[0-9]')))           s++;
    if (pw.contains(RegExp(r'[^A-Za-z0-9]')))    s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return _FormLayout(
      role: widget.data.role,
      step: widget.sidebarStep,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set Your Password', style: AppText.heading()),
              const SizedBox(height: 4),
              Text(
                'Choose a strong password for your account',
                style: AppText.body(color: AppColors.ink3),
              ),
              const SizedBox(height: 28),

              _Field(
                label: 'Password *',
                controller: _pwCtrl,
                obscure: true,
                error: _errors['pw'],
              ),
              const SizedBox(height: 8),
              _StrengthBar(strength: _strength),
              const SizedBox(height: 16),

              _Field(
                label: 'Confirm Password *',
                controller: _confirmCtrl,
                obscure: true,
                textInputAction: TextInputAction.done,
                error: _errors['confirm'],
              ),
              const SizedBox(height: 24),

              Text('Create Your 4-Digit PIN', style: AppText.title()),
              const SizedBox(height: 6),
              Text(
                'This PIN will be used to unlock the parent and teacher area from the profile picker.',
                style: AppText.body(color: AppColors.ink3),
              ),
              const SizedBox(height: 16),
              _Field(
                label: '4-Digit PIN *',
                controller: _pinCtrl,
                obscure: true,
                keyboardType: TextInputType.number,
                error: _errors['pin'],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Confirm PIN *',
                controller: _pinConfirmCtrl,
                obscure: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                error: _errors['pinConfirm'],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),

              if (_isParent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.skyLight,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.skyMid, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.child_care_rounded,
                        size: 18,
                        color: AppColors.sky,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'After signing in, you can add your child\'s profile '
                          'from your dashboard using an invite code.',
                          style: AppText.caption(color: AppColors.sky),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_submitError != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: _submitError!),
              ],

              const SizedBox(height: 32),
              Row(
                children: [
                  SecondaryButton(
                    label: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.ink2,
                    ),
                    onPressed: _submitting ? null : widget.onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _submitting
                        ? _SpinnerButton()
                        : PrimaryButton(
                            label: 'Create Account',
                            width: double.infinity,
                            onPressed: _submit,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final int strength; // 0..4

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    AppColors.ink4,
    AppColors.rose,
    AppColors.amber,
    AppColors.greenMid,
    AppColors.green,
  ];

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (int i = 1; i <= 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 4,
              decoration: BoxDecoration(
                color: i <= strength ? _colors[strength] : AppColors.ink4,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 4),
        ],
        const SizedBox(width: 10),
        Text(
          _labels[strength],
          style: AppText.caption(color: _colors[strength]),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Success page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenLight, AppColors.bg],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: AppMotion.slow,
                      curve: AppMotion.spring,
                    ),
                const SizedBox(height: 20),
                Text("You're all set!", style: AppText.heading())
                    .animate()
                    .fadeIn(delay: 200.ms, duration: AppMotion.slow),
                const SizedBox(height: 6),
                Text(
                  'Your parent or teacher account has been created successfully.',
                  style: AppText.body(color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: AppMotion.slow),
                const SizedBox(height: 28),
                // Email card
                _InfoCard(
                  emoji: '',
                  title: 'Sign in next',
                  body:
                      'Your account is ready. Use your email and password to sign in.',
                ).animate().fadeIn(delay: 400.ms).slideY(
                    begin: 0.04, end: 0, delay: 400.ms,
                    duration: AppMotion.slow, curve: AppMotion.easeOut),
                const SizedBox(height: 12),
                // Next step card
                _InfoCard(
                  emoji: '',
                  title: 'Next: add a child profile',
                  body: 'From your dashboard, add a child and share the invite code.',
                ).animate().fadeIn(delay: 500.ms).slideY(
                    begin: 0.04, end: 0, delay: 500.ms,
                    duration: AppMotion.slow, curve: AppMotion.easeOut),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Go to Sign In',
                  width: double.infinity,
                  onPressed: () => context.go('/admin/login'),
                ).animate().fadeIn(delay: 600.ms, duration: AppMotion.slow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.emoji, required this.title, required this.body});
  final String emoji;
  final String title;
  final String body;

  IconData get _icon {
    switch (title) {
      case 'Check your email':
        return Icons.mark_email_read_rounded;
      case 'Next: add a child profile':
        return Icons.child_care_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 24, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title()),
                const SizedBox(height: 4),
                Text(body, style: AppText.body(color: AppColors.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Shared widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SpinnerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Text(message,
                style: AppText.caption(color: AppColors.rose)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.fast);
  }
}

