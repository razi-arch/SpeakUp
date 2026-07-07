# SpeakUp! — Design System v2
> Place this file in your Flutter project root. Claude Code reads it automatically.
> Last updated: May 2026

---

## What this app is
**SpeakUp!** is an AAC (Augmentative and Alternative Communication) app for children with autism. It runs on a **10" Android tablet in landscape orientation**. The design direction is: clean and modern like Canva, warm and calm like Headspace, content-driven playfulness like Duolingo ABC. The UI frame is restrained — the fun lives in the emoji, avatars, and content, not in the chrome.

---

## User Roles
| Role | Entry method |
|---|---|
| **Child** | Taps their profile card on the home screen. No login, no password. |
| **Parent / Teacher** | Taps the small "Admin Login" link → Firebase email/password. New users tap "Create an Account" to register. |

---

## App Flow
```
Splash Screen
  └─→ Profile Picker  ← single entry point for everyone
        ├─→ [Child taps card]
        │     └─→ "Is this you?" Confirmation Screen
        │           ├─→ [Yes] → Child Home Dashboard
        │           │     ├─→ AAC Board
        │           │     ├─→ Vocab Learning → Reward Screen
        │           │     └─→ Speech Practice → Reward Screen
        │           └─→ [No]  → back to Profile Picker
        └─→ [Admin Login link]
              └─→ Admin Login Screen
                    ├─→ [Sign In] → Admin Dashboard
                    │                 ├─→ Add Child (generates 6-digit invite code)
                    │                 ├─→ Progress Dashboard
                    │                 ├─→ Vocab Manager
                    │                 ├─→ Recording Review
                    │                 ├─→ Enter Invite Code (link to child)
                    │                 └─→ Launch Session → Child Home Dashboard
                    └─→ [Create an Account] → Registration Flow
                              └─→ Step 1: Choose Role (Teacher / Parent)
                                    └─→ Step 2: Personal Information (both roles)
                                          └─→ Step 3: Professional Info (Teacher only)
                                                └─→ Step 4: Set Password → Success Screen
                                                      └─→ → Admin Login
```

### Profile Picker — 3-layer protection (no PIN needed)
1. **Layer 1 — Admin sets default:** Admin taps "Set Active" on one child before handing the tablet over. That card gets a pulsing green ring + a 3-second auto-select countdown bar.
2. **Layer 2 — Personalised avatar:** Each child has a unique colour gradient + animal emoji (e.g. 🦁 green, 🐰 blue). Visually unmistakable.
3. **Layer 3 — Confirmation screen:** Tapping ANY card triggers a full-screen "Is this you?" screen. One giant "Yes, that's me! 🎉" button dominates. A tiny low-contrast "go back" link exists for adults.

---

## Registration Flow

### Overview
- Teachers register in **4 steps**: Choose Role → Personal Info → Professional Info → Set Password
- Parents register in **3 steps**: Choose Role → Personal Info → Set Password (no Professional Info step)
- Sidebar always shows current step + role badge
- Back button on every step — progress is preserved
- On success: email verification sent → navigate to Login

### Fields — Shared (both roles)
| Field | Validation |
|---|---|
| Full Name | Required |
| IC / ID Number | Malaysian format: 000000-00-0000 |
| Email Address | Valid format + not already registered in Firebase |
| Phone Number | Malaysian format (+60 or 01x) |
| Home Address | Required |
| Password | Min 8 chars, 1 uppercase, 1 number |
| Confirm Password | Must match password exactly |

### Fields — Teacher only (Professional Info step)
| Field | Validation |
|---|---|
| School / Centre Name | Required |
| Highest Qualification | Required (e.g. Bachelor of Special Education) |
| Specialisation | Required (e.g. Autism Spectrum Disorder) |
| Years of Experience | Required, numeric |

### Fields — Parent only
No extra fields. Parents add their child profile after signing in via "Add Child" in the dashboard.

### Registration UI rules
- Continue button on Role Selection is **disabled (40% opacity)** until a role is tapped
- Teacher-only fields shown in a **green-tinted section** so it's clear they're role-specific
- Parent sidebar shows **3 steps**, Teacher sidebar shows **4 steps** — adjusts automatically
- Filled fields show **green border** (AppColors.greenMid) as positive feedback
- Errors appear **inline below the field**, not as a toast
- "Create Account" button shows inline spinner on submit — no full-page loading
- Success screen: no confetti (reserved for child rewards) — clean confirmation card layout

### Registration Firestore structure
```dart
// users/{uid} — updated to include all registration fields
users/{uid}
  role:           "teacher" | "parent"
  fullName:       string
  icNumber:       string          // stored but never displayed publicly
  email:          string
  phone:          string
  address:        string
  emailVerified:  bool            // set true after email link clicked
  createdAt:      Timestamp

  // Teacher-only (null for parents)
  schoolName:     string | null
  qualification:  string | null
  specialisation: string | null
  yearsExp:       int    | null
```

### Registration Flutter code pattern
```dart
// lib/services/auth_service.dart — register method
Future<void> register({
  required String email,
  required String password,
  required String role,
  required Map<String, dynamic> profileData,
}) async {
  final credential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(email: email, password: password);

  await FirebaseFirestore.instance
    .collection('users')
    .doc(credential.user!.uid)
    .set({
      'role':      role,
      'email':     email,
      'createdAt': FieldValue.serverTimestamp(),
      ...profileData,  // fullName, icNumber, phone, address, + teacher fields
    });

  await credential.user!.sendEmailVerification();
}
```

---

## Colour Tokens

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Forest Green — primary action, success, child home, confirm
  static const green      = Color(0xFF2D9B6F);
  static const greenMid   = Color(0xFFA8DFC8);
  static const greenLight = Color(0xFFE8F7F1);
  static const greenDark  = Color(0xFF1E7050); // button press-depth shadow

  // Amber — stars, rewards, badges, highlights
  static const amber      = Color(0xFFF0A500);
  static const amberMid   = Color(0xFFF9D87A);
  static const amberLight = Color(0xFFFEF4DC);
  static const amberDark  = Color(0xFFB07800);

  // Terracotta — speech practice, record button, wrong answer
  static const rose       = Color(0xFFE8634A);
  static const roseMid    = Color(0xFFF2B9AD);
  static const roseLight  = Color(0xFFFCEEE9);
  static const roseDark   = Color(0xFFB04030);

  // Denim Blue — AAC board, info states, calm learning, Parent role accent
  static const sky        = Color(0xFF3D8FBF);
  static const skyMid     = Color(0xFFA8CDE8);
  static const skyLight   = Color(0xFFE8F3FA);
  static const skyDark    = Color(0xFF2A6A96);

  // Ink neutrals — warm stone, NOT cold grey
  static const ink        = Color(0xFF1C1917); // primary text
  static const ink2       = Color(0xFF57534E); // secondary text
  static const ink3       = Color(0xFFA8A29E); // captions, placeholders
  static const ink4       = Color(0xFFD6D3D1); // dividers, borders
  static const ink5       = Color(0xFFF5F4F2); // subtle backgrounds, tags
  static const bg         = Color(0xFFF7F4EF); // page/screen background (warm off-white)
  static const bgCard     = Color(0xFFFFFFFF); // card surface
  static const bgRaised   = Color(0xFFF0EDE8); // slightly raised surface
}
```

### Colour role rules
| Colour | Role |
|---|---|
| `green` | Primary action, success, child home, Teacher role accent |
| `amber` | Stars, rewards, badges only |
| `rose` | Speech, record button, wrong answer feedback |
| `sky` | AAC board, info states, Parent role accent |
| `ink → ink5` | All text and neutral UI — never pure black or cool grey |
| `bg` | All screen backgrounds — warm off-white |

---

## Typography

**Single font family: Plus Jakarta Sans**
- Never use Inter, Roboto, or system fonts
- Add via `google_fonts: ^6.2.1`

```dart
// lib/theme/app_text.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle display({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800,
      color: color, letterSpacing: -0.8, height: 1.1);

  static TextStyle heading({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700,
      color: color, letterSpacing: -0.4, height: 1.2);

  static TextStyle title({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: color);

  static TextStyle button({Color color = Colors.white}) =>
    GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700,
      color: color, letterSpacing: -0.2);

  static TextStyle symbolLabel({Color color = AppColors.ink2}) =>
    GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({Color color = AppColors.ink2}) =>
    GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400,
      color: color, height: 1.6);

  static TextStyle caption({Color color = AppColors.ink3}) =>
    GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: color);
}
```

### Type scale
| Token | Size | Weight | Usage |
|---|---|---|---|
| `display` | 30sp | 800 | Reward screen titles, celebration text |
| `heading` | 22sp | 700 | Screen headings, greeting text |
| `title` | 17sp | 700 | Module card titles, section names |
| `button` | 15sp | 700 | All button labels |
| `symbolLabel` | 12sp | 600 | AAC symbol card labels |
| `body` | 14sp | 400 | Admin descriptions, body copy |
| `caption` | 11sp | 500 | Timestamps, hints, metadata |

---

## Border Radius

```dart
// lib/theme/app_radius.dart
import 'package:flutter/material.dart';

class AppRadius {
  static const sm   = BorderRadius.all(Radius.circular(10));  // chips, tags, inputs
  static const md   = BorderRadius.all(Radius.circular(14));  // symbol cards, fields
  static const lg   = BorderRadius.all(Radius.circular(20));  // module cards
  static const xl   = BorderRadius.all(Radius.circular(26));  // profile cards, panels
  static const pill = BorderRadius.all(Radius.circular(999)); // buttons, progress bars
}
```

**Rule: everything is round. Never use sharp corners.**

---

## Shadows

```dart
// lib/theme/app_shadows.dart
import 'package:flutter/material.dart';

class AppShadows {
  static const _c1 = Color(0x0F1C1917); // 6% ink
  static const _c2 = Color(0x141C1917); // 8% ink
  static const _c3 = Color(0x1A1C1917); // 10% ink

  static const xs = [BoxShadow(color: _c1, blurRadius: 2, offset: Offset(0, 1))];
  static const sm = [
    BoxShadow(color: _c2, blurRadius: 8,  offset: Offset(0, 2)),
    BoxShadow(color: _c1, blurRadius: 2,  offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: _c2, blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: _c1, blurRadius: 4,  offset: Offset(0, 2)),
  ];
  static const lg = [
    BoxShadow(color: _c3, blurRadius: 40, offset: Offset(0, 12)),
    BoxShadow(color: _c2, blurRadius: 8,  offset: Offset(0, 4)),
  ];
}
```

### 3D press-depth on primary buttons
```dart
// Normal: 3dp solid bottom shadow
BoxShadow(color: AppColors.greenDark, blurRadius: 0, offset: Offset(0, 3))
// Pressed: collapses to 1dp + translateY +2dp
BoxShadow(color: AppColors.greenDark, blurRadius: 0, offset: Offset(0, 1))
```

---

## Motion & Animation

```dart
// lib/theme/app_motion.dart
import 'package:flutter/material.dart';

class AppMotion {
  static const spring  = Curves.elasticOut;   // all tap/press interactions
  static const easeOut = Curves.easeOutCubic; // all screen entrances
  // Never use Curves.linear except for countdown progress bars

  static const fast  = Duration(milliseconds: 160);
  static const mid   = Duration(milliseconds: 280);
  static const slow  = Duration(milliseconds: 400);
}
```

### Animation rules
| Interaction | What happens | Duration | Curve |
|---|---|---|---|
| Button tap | Scale 1→0.95 + shadow 3dp→1dp + translateY +2dp | 280ms | spring |
| Symbol card tap | Scale 1→0.93→1 | 200ms | spring |
| Card hover | translateY -3px + shadow upgrade | 160ms | easeOut |
| Screen entrance | opacity 0→1 + translateY +10→0 | 400ms | easeOut |
| Profile active ring | box-shadow pulse, 2s loop | 2s | ease-in-out |
| Reward trophy | translateY float 0→-8px, 3s loop | 3s | ease-in-out |
| Stars awarded | scale 0→1.2→1, 100ms stagger | 360ms each | spring |
| Waveform bars | scaleY 0.25→1, staggered 0.1s | 0.7s loop | ease-in-out |
| Countdown bar | width 100%→0% | 3s | linear |
| Toast feedback | opacity 0→1 + slideUp, dismiss 1.5s | 300ms | easeOut |

### Spring tap wrapper — apply to every interactive widget
```dart
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const SpringTap({required this.child, this.onTap, super.key});

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.93 : 1.0,
        duration: AppMotion.mid,
        curve:    AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}
```

### Screen entrance — apply to every screen
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: YourContent()
      .animate()
      .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
      .slideY(begin: 0.03, end: 0, duration: AppMotion.slow, curve: AppMotion.easeOut),
  );
}
```

---

## Component Specs

### AAC Symbol Card
```
Size:        min 80 × 80dp
Emoji:       30sp centred
Label:       AppText.symbolLabel()
Radius:      AppRadius.md
Shadow:      AppShadows.xs (idle) → AppShadows.md (selected)
Border:      1.5dp AppColors.ink4 (idle) → AppColors.greenMid (selected)
Background:  AppColors.bgCard (idle) → AppColors.greenLight (selected)
On tap:      SpringTap wrapper
```

### Primary Button
```
Height:      min 52dp
Padding:     14dp vertical, 26dp horizontal
Radius:      AppRadius.pill
Font:        AppText.button() — white
Background:  AppColors.green
Shadow:      0 3dp 0 AppColors.greenDark + AppShadows.sm
On press:    shadow 3dp→1dp + translateY +2dp + scale 0.97
```

### Secondary Button
```
Height:      min 48dp
Padding:     13dp vertical, 24dp horizontal
Radius:      AppRadius.pill
Font:        AppText.button(color: AppColors.ink)
Background:  AppColors.bgCard
Border:      1.5dp AppColors.ink4
On press:    scale 0.95 spring
```

### Profile Card
```
Width:       ~144dp
Radius:      AppRadius.xl
Shadow:      AppShadows.md
Avatar:      60dp circle, gradient + animal emoji 32sp
Name:        AppText.title()
Stars:       AppText.caption()
Active:      2dp border AppColors.green + pulseRing + countdown bar
Inactive:    65% opacity, border AppColors.ink4
On tap:      always → ConfirmProfileScreen
```

### Registration Form Field
```
Background:  AppColors.bg
Border:      1.5dp AppColors.ink4 (idle)
             AppColors.greenMid (filled/valid)
             AppColors.green (focused)
             AppColors.rose (error)
Focus ring:  3dp AppColors.greenLight
Radius:      AppRadius.md
Font:        AppText.body(), placeholder AppColors.ink3
Error text:  AppText.caption(color: AppColors.rose), shown inline below field
```

### Registration Sidebar
```
Width:       220dp
Background:  AppColors.ink
Step item:   22dp circle num + label
Active step: white 10% opacity bg, circle AppColors.green
Done step:   60% opacity, circle AppColors.green with ✓
Role badge:  at bottom, Teacher = green tint, Parent = sky tint
```

### Admin Sidebar (Dashboard)
```
Width:       120dp fixed
Background:  Color(0xFF1A5C42) — darkened green
Nav item:    22sp icon + AppText.caption (white 60% opacity)
Active item: white 18% opacity background + white 100% text
```

### Progress Bar
```
Track:       9dp height, AppColors.ink5, AppRadius.pill
Fill green:  AppColors.green (AAC Board)
Fill sky:    AppColors.sky (Vocab)
Fill rose:   AppColors.rose (Speech)
```

### Input Field (general)
```
Background:  AppColors.bg
Border:      1.5dp AppColors.ink4 → AppColors.green on focus
Focus ring:  3dp AppColors.greenLight
Radius:      AppRadius.md
Font:        AppText.body(), placeholder AppColors.ink3
```

---

## Screen Backgrounds
| Screen | Background |
|---|---|
| Profile Picker | Gradient: `greenLight` → `bg` → `amberLight` |
| "Is this you?" | Gradient: `greenLight` → `bg` |
| Child Home | `AppColors.bg` |
| AAC Board | `AppColors.bg` (grid), `AppColors.bgCard` (sidebar) |
| Vocab Learning | `AppColors.bg` |
| Speech Practice | `AppColors.roseLight` |
| Reward Screen | Gradient: `amberLight` → `greenLight` |
| Admin Login | `AppColors.bg` |
| Admin Register — Role Select | Gradient: `greenLight` → `bg` → `skyLight` |
| Admin Register — Form steps | `AppColors.bg` with `AppColors.ink` sidebar |
| Admin Register — Success | Gradient: `greenLight` → `bg` |
| Admin Dashboard | `Color(0xFFF0EDE8)` |
| Add Child | `AppColors.bg` |

---

## Firebase Data Structure
```
users/{uid}
  role:           "teacher" | "parent"
  fullName:       string
  icNumber:       string
  email:          string
  phone:          string
  address:        string
  emailVerified:  bool
  createdAt:      Timestamp
  schoolName:     string | null   // teacher only
  qualification:  string | null   // teacher only
  specialisation: string | null   // teacher only
  yearsExp:       int    | null   // teacher only

children/{childId}
  name:                 string
  avatarEmoji:          string
  avatarGradientStart:  string
  avatarGradientEnd:    string
  difficulty:           "beginner" | "intermediate" | "advanced"
  qaMode:               2 | 4
  linkedUsers:          [uid, uid]
  createdBy:            uid
  isActiveOnDevice:     bool

inviteCodes/{code}
  childId:    string
  createdBy:  uid
  expiresAt:  Timestamp
  used:       bool

sessions/{childId}/{sessionId}
  module:          "aac" | "vocab" | "speech"
  accuracy:        double
  wordsAttempted:  int
  durationSeconds: int
  timestamp:       Timestamp

recordings/{childId}/{recordingId}
  storageUrl:    string
  word:          string
  timestamp:     Timestamp
  adminScore:    int?
  adminComment:  string?

rewards/{childId}
  totalStars: int
  badges:     [string]
```

### Key Firestore queries
```dart
// Children linked to current admin
FirebaseFirestore.instance
  .collection('children')
  .where('linkedUsers', arrayContains: currentUser.uid)
  .get();

// Redeem invite code
final doc = await FirebaseFirestore.instance
  .collection('inviteCodes').doc(enteredCode).get();
if (!doc.exists || doc['used'] == true) throw 'Invalid code';
if ((doc['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now()))
  throw 'Code expired';
await FirebaseFirestore.instance
  .collection('children').doc(doc['childId'])
  .update({'linkedUsers': FieldValue.arrayUnion([currentUser.uid])});
await doc.reference.update({'used': true});
```

---

## Key Flutter Packages
```yaml
dependencies:
  # Firebase
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_storage: ^12.x

  # Navigation
  go_router: ^14.x

  # UI & Typography
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  confetti: ^0.7.0

  # AAC & Speech
  flutter_tts: ^4.x
  # record: ^5.1.2          # uncomment in Phase 5.6
  # audio_waveforms: ^1.0.0 # uncomment in Phase 5.6

  # Data & Charts
  fl_chart: ^0.68.x
  cached_network_image: ^3.x

  # State
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
```

---

## Navigation & Routes
```dart
/                        → ProfilePickerScreen
/confirm/:childId        → ConfirmProfileScreen
/child/home              → ChildHomeScreen
/child/aac               → AACBoardScreen
/child/vocab             → VocabLearningScreen
/child/speech            → SpeechPracticeScreen
/child/reward            → RewardScreen
/admin/login             → AdminLoginScreen
/admin/register          → AdminRegisterScreen  ← NEW
/admin/dashboard         → AdminDashboardScreen
/admin/add-child         → AddChildScreen
/admin/progress/:id      → ProgressScreen
/admin/vocab/:id         → VocabManagerScreen
/admin/recordings/:id    → RecordingReviewScreen
/admin/link-code         → EnterInviteCodeScreen

// Auth guard:
// Unauthenticated → /  (Profile Picker)
// Authenticated   → /admin/dashboard
// Child mode:     → store activeChildId in Riverpod provider

// Child navigation:  IndexedStack — no back button
// Admin navigation:  NavigationRail (120dp sidebar) + content panel
// Register:          PageView with step controller — back/next buttons
```

---

## Device & Layout Rules
```
Target:      10" Android tablet, landscape orientation
Resolution:  ~1280 × 800dp
Android:     8.0 (Oreo / API 26) minimum

Landscape lock: child home, AAC, vocab, speech, reward
Portrait ok:    admin login, registration form, add child form

Min tap:     48 × 48dp (WCAG 2.5.5)
Symbol card: 80 × 80dp minimum
Card gap:    12dp minimum
```

---

## Design Principles
1. **Playfulness in content, not chrome** — clean UI frame; fun lives in emoji, avatars, rewards
2. **One primary action per screen** — biggest, most colourful = what to do next
3. **Every tap feels real** — SpringTap on every interactive element, no exceptions
4. **Calm by default** — nothing moves until triggered; no auto-sound, no aggressive loops
5. **Earn the celebration** — full reward stack only on genuine completion
6. **Big targets** — 48dp minimum everywhere, 80dp for symbol cards
7. **Warm neutrals only** — never pure `#000` or cool grey; always use ink/bg scale
8. **No popup dialogs for children** — full-screen transitions or bottom sheets only
9. **Inline errors on forms** — never toast for validation errors; show below the field