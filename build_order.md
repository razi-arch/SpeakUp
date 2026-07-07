# SpeakUp! — Build Order Guide
> Follow this top to bottom. Never skip a phase.
> Each phase must work before moving to the next.
> Last updated: May 2026

---

## The Rule
> **Foundation → Skeleton → Child Side → Admin Side → Polish**
>
> Build vertically (one full feature at a time), not horizontally.
> A working AAC board with real Firebase data is worth more than
> 10 screens with fake data.

---

## Phase 1 — Project Foundation ✅ DONE
*Nothing else works without this.*

### 1.1 Flutter project setup ✅
### 1.2 Design token files ✅
```
lib/theme/app_colors.dart
lib/theme/app_text.dart
lib/theme/app_radius.dart
lib/theme/app_shadows.dart
lib/theme/app_motion.dart
lib/theme/app_theme.dart
```

### 1.3 Firebase setup ✅
```
Firebase project: speakup-69ed7
Android app registered, google-services.json in android/app/
Firebase Auth enabled (email/password)
Firestore enabled (test mode, asia-southeast1)
firebase_options.dart generated via FlutterFire CLI
Firebase.initializeApp() in main.dart
```

### 1.4 Folder structure ✅
```
lib/
├── theme/
├── models/
├── providers/
├── screens/
│   ├── child/
│   └── admin/
├── services/
├── widgets/
└── main.dart
```

### Known environment notes
```
Device ID:        R52WA004XLL  (Samsung SM-X510)
Run command:      flutter run -d R52WA004XLL
Android SDK:      D:\Android\SDK
Gradle memory:    android/gradle.properties →
                  org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=512m
                  org.gradle.daemon=false
Commented out:    record and audio_waveforms in pubspec.yaml (add back Phase 5.6)
```

**✅ Phase 1 complete**

---

## Phase 2 — Data Models & Services ✅ DONE

### 2.1 Models ✅
```
lib/models/child_model.dart
lib/models/session_model.dart
lib/models/recording_model.dart
lib/models/reward_model.dart
lib/models/invite_code_model.dart
```

### 2.2 Services ✅
```
lib/services/auth_service.dart     — signIn, signOut, register, getUserRole
lib/services/child_service.dart    — getLinkedChildren, createChild, setActiveChild
lib/services/invite_service.dart   — generateCode, redeemCode
lib/services/session_service.dart  — createSession, getSessionsForChild
lib/services/vocab_service.dart    — getVocabItems, addVocabItem, updateVocabItem
```

### 2.3 Riverpod providers ✅
```
lib/providers/auth_provider.dart
lib/providers/child_provider.dart
lib/providers/vocab_provider.dart
lib/providers/session_provider.dart
```

**✅ Phase 2 complete**

---

## Phase 3 — Navigation Skeleton ✅ DONE

### Routes wired up ✅
```
/                        → ProfilePickerScreen (placeholder)
/confirm/:childId        → ConfirmProfileScreen (placeholder)
/child/home              → ChildHomeScreen (placeholder)
/child/aac               → AACBoardScreen (placeholder)
/child/vocab             → VocabLearningScreen (placeholder)
/child/speech            → SpeechPracticeScreen (placeholder)
/child/reward            → RewardScreen (placeholder)
/admin/login             → AdminLoginScreen (placeholder)
/admin/register          → AdminRegisterScreen (placeholder)  ← NEW
/admin/dashboard         → AdminDashboardScreen (placeholder)
/admin/add-child         → AddChildScreen (placeholder)
/admin/progress/:id      → ProgressScreen (placeholder)
/admin/vocab/:id         → VocabManagerScreen (placeholder)
/admin/recordings/:id    → RecordingReviewScreen (placeholder)
/admin/link-code         → EnterInviteCodeScreen (placeholder)
```

**✅ Phase 3 complete**

---

## Phase 4 — Shared Widgets ✅ DONE

```
lib/widgets/spring_tap.dart
lib/widgets/primary_button.dart
lib/widgets/secondary_button.dart
lib/widgets/icon_button_widget.dart
lib/widgets/symbol_card.dart
lib/widgets/profile_card.dart        ← fix AnimationController type error if not done
lib/widgets/progress_bar.dart
lib/widgets/word_pill.dart
lib/widgets/feedback_toast.dart
lib/widgets/waveform.dart
lib/widgets/countdown_bar.dart
```

**Known issue:** `profile_card.dart` had AnimationController typed as Object — fix if not already resolved.

**✅ Phase 4 complete**

---

## Phase 5 — Child Side ✅ DONE

### 5.1 Profile Picker ✅
### 5.2 "Is this you?" Confirmation ✅
### 5.3 Child Home Dashboard ✅
### 5.4 AAC Board ✅
### 5.5 Vocab Learning ✅
### 5.6 Speech Practice ✅
### 5.7 Reward Screen ✅

**✅ Phase 5 complete**

---

## Phase 6 — Admin Side ✅ DONE

### 6.1 Admin Login ✅
### 6.2 Admin Registration ✅
### 6.3 Admin Dashboard ✅
### 6.4 Add Child ✅
### 6.5 Enter Invite Code ✅
### 6.6 Progress Dashboard ✅
### 6.7 Vocab Manager ✅
### 6.8 Recording Review ✅

**✅ Phase 6 complete**

---

## Phase 7 — Polish & Edge Cases
*Only start after Phase 5 and 6 are fully working.*

```
✅ Error states: covered in all screens (Firestore fails, network errors in registration)
✅ Empty states: covered in all screens (no vocab, no sessions, no children)
✅ Loading states: spinners on all async data screens
✅ Form validation: registration fully validated (IC, email, phone, password strength); add-child name validated
✅ Email verification gate: admin_login_screen checks emailVerified after signIn, signs out + shows error if unverified
✅ Firestore security rules: firestore.rules created — users own their doc, children locked to linkedUsers, invite redemption special-cased
✅ Performance: const constructors added to zero-field private widgets (_SidebarHomeButton, _Header, _AdminLoginLink, _GoBackLink)
✅ Orientation lock: sensorLandscape added to AndroidManifest activity (backs up runtime setPreferredOrientations)
✅ Offline handling: Firestore unlimited cache configured in main.dart — vocab/sessions/rewards readable offline
✅ App icon + splash screen: assets generated, launcher_icon in all mipmap densities, splash in all drawable densities, pubspec config blocks added
□ Accessibility: test with tablet font size at largest (device test)
□ Test full flow on real Samsung tablet (not emulator)
```

---

## What to tell Claude Code at each step

| Step | Prompt |
|---|---|
| Fix profile_card.dart | "Fix the AnimationController type error in lib/widgets/profile_card.dart — it is typed as Object, change to AnimationController" |
| 5.1 Profile Picker | "Build lib/screens/child/profile_picker_screen.dart. Read DESIGN.md for the 3-layer safety spec, Profile Card specs, CountdownBar widget, and screen background." |
| Each child screen | "Build [screen]. Read DESIGN.md for colours, animations, component specs." |
| 6.1 Admin Login | "Build lib/screens/admin/admin_login_screen.dart. Include the 'Create an Account' secondary button linking to /admin/register. Read DESIGN.md." |
| 6.2 Registration | "Build the admin registration flow in lib/screens/admin/admin_register_screen.dart. It has 4 steps for Teachers and 3 for Parents. Read DESIGN.md Registration Flow section for all field specs, validation rules, sidebar layout, and Firestore structure." |
| 6.3 Dashboard | "Build lib/screens/admin/admin_dashboard_screen.dart using NavigationRail sidebar. Read DESIGN.md." |

---

## Estimated effort remaining
```
Phase 5 — Child side      ~8–12 hours  (5.1 in progress)
Phase 6 — Admin side      ~8–10 hours  (registration adds ~2h vs original)
Phase 7 — Polish          ~4–6 hours
──────────────────────────────────────
Remaining                 ~20–28 hours
```

---

## Red flags — stop and fix before continuing
- 🚨 Hardcoded colours anywhere → use AppColors tokens only
- 🚨 Interactive widget with no press feedback → add SpringTap
- 🚨 Firestore reads in widget build() → move to provider
- 🚨 Registration form submits without validation → add all validators
- 🚨 Phase 5 screens use fake data → connect to Firestore before Phase 6
- 🚨 Email not verified but admin can access dashboard → add email gate in Phase 7