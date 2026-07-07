# Architectural Diagram Reference — SpeakUp! AAC Learning App

This document describes the full architecture of the SpeakUp! system. Use it as the authoritative reference to manually draw the architectural diagram in Canva. It covers the physical deployment view, the software component view, all communication paths, external resources, and the interface design of every entity.

---

## SECTION 1 — PHYSICAL ARCHITECTURE (DEPLOYMENT VIEW)

The SpeakUp! system spans three physical locations. No software component straddles two locations; components in different locations collaborate over defined protocols.

### Physical Nodes

| Node | Label | Hardware / Platform | Role |
|------|-------|---------------------|------|
| 1 | Android Tablet | Samsung SM-X510, Android 16 (API 36), ARM64 | The sole end-user device. Hosts and executes the entire Flutter application. Captures audio from the built-in microphone. Plays audio and TTS through the built-in speaker. Stores temporary .aac audio files in local device storage before cloud upload. Operates in landscape-only orientation at 1280 × 800 dp. |
| 2 | Google Firebase Cloud Platform | Google Cloud servers (asia-southeast1 region) | Remote backend infrastructure. Hosts three independent Firebase services: Authentication, Cloud Firestore, and Firebase Storage. Communicates with the tablet over the public internet via HTTPS and gRPC. Has no direct access to the tablet's local file system or hardware. |
| 3 | Android OS Services Layer | Same physical hardware as Node 1, managed by Android OS | A logical separation within the tablet. Provides system-level services consumed by the Flutter app through platform channels: the Google TTS engine (text-to-speech), the device microphone (audio recording), and the audio playback subsystem. These run in the Android OS process, not in the Flutter/Dart isolate. |

### Communication Links Between Nodes

| Link | From | To | Protocol | Medium |
|------|----|---|----------|--------|
| L1 | Android Tablet (Flutter App) | Firebase Cloud | HTTPS + gRPC (Firebase SDK) | Wi-Fi or mobile data |
| L2 | Firebase Cloud | Android Tablet (Flutter App) | HTTPS + gRPC real-time push (Firestore listeners) | Wi-Fi or mobile data |
| L3 | Flutter App (Dart isolate) | Android OS Services Layer | Flutter Platform Channel (Dart ↔ Kotlin/JVM method calls) | In-process IPC, no network |
| L4 | Android OS Services Layer | Flutter App (Dart isolate) | Platform Channel callback / event stream | In-process IPC, no network |

### Physical Node Diagram — Layout Guide for Canva

Draw three large rectangular boxes arranged horizontally:

```
┌──────────────────────┐      ┌───────────────────────────┐
│  NODE 1              │      │  NODE 2                   │
│  Android Tablet      │◄────►│  Firebase Cloud Platform  │
│  Samsung SM-X510     │ L1/L2│  (asia-southeast1)        │
│                      │      │                           │
│  [Flutter App]       │      │  [Firebase Auth]          │
│  [Local Storage]     │      │  [Cloud Firestore]        │
│                      │      │  [Firebase Storage]       │
└──────────────────────┘      └───────────────────────────┘
         │
         │ L3 / L4
         │ (Platform Channel)
         ▼
┌──────────────────────┐
│  NODE 3              │
│  Android OS Services │
│  (same hardware)     │
│                      │
│  [TTS Engine]        │
│  [Microphone / ADC]  │
│  [Audio Player]      │
└──────────────────────┘
```

---

## SECTION 2 — SOFTWARE ARCHITECTURE (COMPONENT VIEW)

### 2.1 Entities on Node 1 — Flutter Application

The Flutter application is structured in four layers. Each layer depends only on the layer below it.

#### Layer 1 — Presentation Layer (UI)

| Component | Location | Responsibility |
|-----------|----------|----------------|
| Profile Picker Screen | lib/screens/profile_picker_screen.dart | Entry point; shows child profile cards with countdown; admin login link |
| Confirm Profile Screen | lib/screens/confirm_profile_screen.dart | Full-screen identity confirmation before entering child home |
| Child Home Screen | lib/screens/child/child_home_screen.dart | Dashboard for child; module selector; badge progress; recent sessions |
| AAC Board Screen | lib/screens/child/aac_board_screen.dart | Symbol grid with category sidebar; sentence builder; TTS playback |
| Vocab Learning Screen | lib/screens/child/vocab_learning_screen.dart | Multiple-choice Q&A activity; 5-correct-answer completion |
| Speech Practice Screen | lib/screens/child/speech_practice_screen.dart | Word picker grid; single-word record / listen / play-back flow |
| Reward Screen | lib/screens/child/reward_screen.dart | Star award; badge unlock; confetti; session completion |
| Admin Login Screen | lib/screens/admin/admin_login_screen.dart | Email + password sign-in form |
| Admin Register Screen | lib/screens/admin/admin_register_screen.dart | Multi-step registration (4 steps Teacher / 3 steps Parent) |
| Admin Dashboard Screen | lib/screens/admin/admin_dashboard_screen.dart | Overview of linked children, accuracy chart, quick links |
| Add Child Screen | lib/screens/admin/add_child_screen.dart | Create child profile; generate 6-digit invite code |
| Vocab Manager Screen | lib/screens/admin/vocab_manager_screen.dart | CRUD for vocabulary items per child; Q&A mode toggle |
| Progress Screen | lib/screens/admin/progress_screen.dart | Accuracy trend chart; session history list; date filter |
| Recording Review Screen | lib/screens/admin/recording_review_screen.dart | List speech recordings; star rating; comment; audio playback |
| Enter Invite Code Screen | lib/screens/admin/enter_invite_code_screen.dart | 6-digit code input to link a child profile |
| Shared Widgets | lib/widgets/ | SpringTap, PrimaryButton, SecondaryButton, SymbolCard, ProfileCard, WordPill, FeedbackToast, Waveform, CountdownBar, ProgressBar, AdminSidebar |
| Theme System | lib/theme/ | AppColors, AppText (Plus Jakarta Sans), AppRadius, AppShadows, AppMotion |

#### Layer 2 — State Management Layer (Riverpod)

| Provider | File | State Managed |
|----------|------|---------------|
| authServiceProvider | lib/providers/auth_provider.dart | AuthService singleton |
| authStateProvider | lib/providers/auth_provider.dart | Stream\<User?\> — current Firebase Auth user |
| userRoleProvider | lib/providers/auth_provider.dart | FutureProvider\<String?\> — "teacher" or "parent" |
| isAdminProvider | lib/providers/auth_provider.dart | bool — has an authenticated role |
| childServiceProvider | lib/providers/child_provider.dart | ChildService singleton |
| linkedChildrenProvider | lib/providers/child_provider.dart | Stream\<List\<ChildModel\>\> — children linked to current user |
| activeChildProvider | lib/providers/child_provider.dart | StateProvider\<ChildModel?\> — child selected for this session |
| deviceActiveChildProvider | lib/providers/child_provider.dart | Convenience: child with isActiveOnDevice == true |
| inviteServiceProvider | lib/providers/child_provider.dart | InviteService singleton |
| vocabServiceProvider | lib/providers/vocab_provider.dart | VocabService singleton |
| selectedCategoryProvider | lib/providers/vocab_provider.dart | StateProvider\<String?\> — active category filter (AAC Board) |
| categoriesProvider | lib/providers/vocab_provider.dart | Stream\<List\<String\>\> — distinct categories for active child |
| vocabItemsProvider | lib/providers/vocab_provider.dart | Stream\<List\<VocabItem\>\> — items filtered by child + category |
| allVocabItemsProvider | lib/providers/vocab_provider.dart | Stream\<List\<VocabItem\>\> — all items for active child |
| adminAllVocabProvider | lib/providers/vocab_provider.dart | StreamProvider.family — all items for arbitrary childId |
| sessionServiceProvider | lib/providers/session_provider.dart | SessionService singleton |
| recentSessionsProvider | lib/providers/session_provider.dart | Stream\<List\<SessionModel\>\> — last 10 sessions for active child |
| childSessionsProvider | lib/providers/session_provider.dart | StreamProvider.family — sessions for arbitrary childId (limit 50) |
| adminSessionsProvider | lib/providers/admin_provider.dart | FutureProvider — recent sessions across all linked children |
| rewardProvider | lib/providers/reward_provider.dart | StreamProvider.family — RewardModel (stars + badges) by childId |

#### Layer 3 — Service Layer

| Service | File | Responsibility |
|---------|------|----------------|
| AuthService | lib/services/auth_service.dart | Firebase Auth: signIn, register (creates Auth user + Firestore document + sends verification email), signOut, getUserRole |
| ChildService | lib/services/child_service.dart | Firestore CRUD for children collection; setActiveChild |
| InviteService | lib/services/invite_service.dart | Generate 6-digit invite codes (48 h TTL); atomic redemption transaction |
| VocabService | lib/services/vocab_service.dart | Firestore CRUD for vocab/{childId}/items; watchCategories stream; watchVocabItems stream |
| SessionService | lib/services/session_provider.dart | Write session records to sessions/{childId}/sessions |

#### Layer 4 — Navigation Layer

| Component | File | Responsibility |
|-----------|------|----------------|
| GoRouter | lib/router.dart | Declares all 14 named routes; applies two redirect guards: (1) admin-auth guard — unauthenticated users cannot reach /admin/* except /admin/login and /admin/register; (2) active-child guard — /child/* requires activeChildProvider to be non-null |
| _RouterNotifier | lib/router.dart | ChangeNotifier that listens to authStateProvider and activeChildProvider; triggers GoRouter refresh on state changes |

---

### 2.2 Entities on Node 2 — Firebase Cloud Platform

| Entity | Firebase Service | Storage Location | Data Stored |
|--------|-----------------|-----------------|-------------|
| Firebase Authentication | Firebase Auth | Google Identity Platform | User accounts (email + hashed password), email verification status, UID mappings |
| Cloud Firestore | Firestore (NoSQL) | asia-southeast1 | users, children, inviteCodes, vocab/{childId}/items, sessions/{childId}/sessions, recordings/{childId}/recordings, rewards/{childId} |
| Firebase Storage | Cloud Storage | asia-southeast1 bucket | Audio recordings: recordings/{childId}/{word}_{timestamp}.aac; Vocab images: vocab_images/{childId}/{filename} |

#### Firestore Data Schema

```
users/{uid}
  role, fullName, icNumber, email, phone, address,
  emailVerified, createdAt,
  schoolName*, qualification*, specialisation*, yearsExp*  (* teacher only)

children/{childId}
  name, avatarEmoji, avatarGradientStart, avatarGradientEnd,
  difficulty, qaMode, linkedUsers[], createdBy, isActiveOnDevice

inviteCodes/{code}
  childId, createdBy, expiresAt, used

vocab/{childId}/items/{itemId}
  word, emoji, category, imageUrl, audioUrl

sessions/{childId}/sessions/{sessionId}
  childId, module, accuracy, wordsAttempted, durationSeconds, timestamp

recordings/{childId}/recordings/{recordingId}
  childId, storageUrl, word, timestamp, adminScore, adminComment

rewards/{childId}
  totalStars, badges[]
```

---

### 2.3 Entities on Node 3 — Android OS Services Layer

| Entity | Package / Driver | Role |
|--------|-----------------|------|
| Flutter TTS Engine | flutter_tts ^4.0.0 (Google TTS via Android TextToSpeech API) | Converts text strings to spoken audio output through the tablet speaker |
| Audio Recorder | record ^6.0.0 (Android AudioRecord / MediaRecorder API) | Captures audio from the device microphone; encodes to AAC-LC format; writes to a temp .aac file in the app's cache directory |
| Audio Player | audioplayers ^6.0.0 (Android MediaPlayer API) | Streams and plays local .aac files or remote URLs (Firebase Storage download URLs) |
| Local File System | Android temp directory (path_provider ^2.1.0) | Stores temporary audio files (speech_{timestamp}.aac) between recording and upload |

---

### 2.4 Actors and Their Interaction Points

| Actor | Physical Location | Entry Point | Layers Accessed |
|-------|-----------------|-------------|-----------------|
| Child | Physically at Node 1 (the tablet) | Profile Picker Screen | Presentation Layer only; the child never directly accesses services or cloud |
| Teacher | Physically at Node 1 (the tablet) | Admin Login Screen → Admin Dashboard | Presentation Layer (admin screens) → State Layer → Service Layer → Firebase Cloud |
| Parent | Physically at Node 1 (the tablet) | Admin Login Screen → Admin Dashboard | Same as Teacher; registration collects fewer fields |

---

## SECTION 3 — COMMUNICATION PATHS

| ID | From Entity | To Entity | Direction | Protocol / Mechanism | Data Exchanged |
|----|------------|-----------|-----------|----------------------|---------------|
| CP-01 | Flutter App (AuthService) | Firebase Authentication | Bidirectional | HTTPS (Firebase Auth REST SDK) | signIn request (email, password) → UserCredential (uid, token); registration request; email verification trigger |
| CP-02 | Flutter App (AuthService) | Cloud Firestore | Write | gRPC over HTTPS | users/{uid} document on registration; getUserRole query |
| CP-03 | Firebase Authentication | Flutter App | Push | WebSocket / long-poll (authStateChanges stream) | Auth state changes (signed in / signed out / token refresh) |
| CP-04 | Flutter App (ChildService, VocabService, SessionService) | Cloud Firestore | Write | gRPC over HTTPS | Create/update children, inviteCodes, vocab items, session records, reward increments, recording metadata |
| CP-05 | Cloud Firestore | Flutter App (Riverpod StreamProviders) | Real-time push | gRPC persistent stream (Firestore .snapshots()) | Live document/collection updates for children, vocab, sessions, rewards, recordings |
| CP-06 | Flutter App (SpeechPracticeScreen) | Firebase Storage | Write | HTTPS multipart upload (putFile) | Binary .aac audio file (avg 50–200 KB per recording) |
| CP-07 | Firebase Storage | Flutter App | Response | HTTPS | Download URL (gs://... public link) returned after upload |
| CP-08 | Flutter App (AudioPlayer) | Firebase Storage | Read | HTTPS range request (streaming) | Audio file bytes streamed for playback in Recording Review |
| CP-09 | Flutter App (Dart isolate) | Flutter TTS (Android TTS API) | Write | Flutter Platform Channel | Text string → synthesised speech via Android TextToSpeech |
| CP-10 | Flutter TTS | Flutter App | Callback | Platform Channel event | Completion notification when speech finishes |
| CP-11 | Flutter App (Dart isolate) | Audio Recorder (Android AudioRecord) | Write | Flutter Platform Channel | Start(config, path) / stop() commands |
| CP-12 | Audio Recorder | Flutter App | Callback | Platform Channel event | Local file path of completed .aac recording |
| CP-13 | Flutter App (Dart isolate) | Audio Player (Android MediaPlayer) | Write | Flutter Platform Channel | play(source) / stop() commands |
| CP-14 | Audio Player | Flutter App | Stream | Platform Channel event stream | PlayerState changes (playing / stopped / completed) |
| CP-15 | InviteService | Cloud Firestore | Atomic transaction | gRPC over HTTPS | Read inviteCodes/{code} → update used=true + arrayUnion(uid) on child's linkedUsers in a single transaction |

---

## SECTION 4 — RESOURCES

Resources are elements used by software entities that are external to the design itself.

### 4.1 Physical Devices

| Resource | Type | Used By | Purpose |
|----------|------|---------|---------|
| Device Microphone (built-in) | Hardware input | Audio Recorder (Node 3) | Captures child's voice during Speech Practice |
| Device Speaker (built-in) | Hardware output | Flutter TTS + Audio Player (Node 3) | Outputs TTS speech and recorded audio playback |
| Device Display (1280 × 800 dp, landscape) | Hardware output | Flutter Presentation Layer | Renders all UI; landscape orientation locked for child screens |
| Local Flash Storage | Hardware storage | Local File System (Node 3) | Holds temporary .aac recordings before upload (cache directory, auto-cleared by OS) |
| Wi-Fi / Mobile Radio | Hardware network | Firebase SDK (Node 1) | Network connectivity to Firebase Cloud (Node 2) |

### 4.2 Software Services (External)

| Resource | Provider | Used By | Purpose |
|----------|----------|---------|---------|
| Firebase Authentication | Google / Firebase | AuthService | Identity management: account creation, email/password sign-in, email verification |
| Cloud Firestore | Google / Firebase | All Services | Primary application database (NoSQL document store) |
| Firebase Storage | Google / Firebase | SpeechPracticeScreen, RecordingReviewScreen | Persistent storage for .aac audio files and vocab images |
| Google TTS Engine | Google / Android OS | Flutter TTS package | Text-to-speech synthesis; pre-installed on Android devices |
| Google Fonts CDN | Google | AppText (Plus Jakarta Sans) | Web font download; cached locally after first use |
| cached_network_image CDN | Any HTTP source | VocabLearningScreen, VocabManagerScreen | Downloads and caches vocab item images from admin-provided URLs |

### 4.3 Processing Resources (Libraries and Buffers)

| Resource | Package | Version | Used By | Purpose |
|----------|---------|---------|---------|---------|
| Riverpod State Container | flutter_riverpod | ^2.0.0 | All Providers | In-memory reactive state; holds auth state, active child, vocab lists, reward counts |
| GoRouter | go_router | ^14.0.0 | Navigation Layer | URL-based declarative navigation with redirect guards |
| Flutter Animate | flutter_animate | ^4.5.0 | All Screens | Declarative animation effects (fadeIn, slideY, scale) |
| Confetti Engine | confetti | ^0.7.0 | Reward Screen | Particle system for celebration animation |
| FL Chart | fl_chart | ^0.68.0 | Progress Screen, Admin Dashboard | Bar chart and line chart rendering |
| Image Picker | image_picker | ^1.0.0 | Vocab Manager Screen | Gallery access for vocab item image upload |
| Audio Temp Buffer | path_provider + record | — | SpeechPracticeScreen | Temporary .aac file in app cache directory during recording |

---

## SECTION 5 — INTERFACE DESIGN

The interface design lists the services (public API) each entity provides to its clients. This defines the contract between components.

---

### 5.1 Flutter Application — Services to Child (Actor)

| Service | Entry Point | Description |
|---------|-------------|-------------|
| Profile Selection | ProfilePickerScreen | Displays linked child profile cards; countdown auto-select for active child; 3-layer identity protection |
| Profile Confirmation | ConfirmProfileScreen | Full-screen "Is this you?" confirmation before entering child home |
| Child Home | ChildHomeScreen | Module selector (AAC Board, Vocab Learning, Speech Practice); badge progress; recent activity; switch-profile link |
| AAC Communication Board | AACBoardScreen | Symbol grid with category filter; sentence builder; TTS playback; session logging |
| Vocabulary Learning | VocabLearningScreen | Multiple-choice Q&A (2 or 4 choices per child.qaMode); TTS; correct/wrong feedback; reward on 5 correct |
| Speech Practice | SpeechPracticeScreen | Word picker grid; single-word Listen / Record / Play Back / Finish flow; reward on finish |
| Reward Screen | RewardScreen | Awards 5 stars; checks badge milestones; confetti; displays earned badges |

---

### 5.2 Flutter Application — Services to Teacher / Parent (Actor)

| Service | Entry Point | Description |
|---------|-------------|-------------|
| Registration | AdminRegisterScreen | 4-step (Teacher) or 3-step (Parent) form; validates IC, email, phone, address, password strength; creates Firebase Auth account + Firestore user document; sends verification email |
| Login | AdminLoginScreen | Email + password authentication; inline error handling; routes to dashboard on success |
| Admin Dashboard | AdminDashboardScreen | Weekly accuracy bar chart; stat cards (children count, avg accuracy, words today); per-child rows with Progress / Vocab / Recordings shortcuts and Launch Session button |
| Add Child | AddChildScreen | Name, avatar picker, difficulty, Q&A mode form; creates child document; generates 48-hour invite code |
| Link Child via Code | EnterInviteCodeScreen | Validates and atomically redeems 6-digit invite code; adds child to admin's linked profiles |
| Vocabulary Manager | VocabManagerScreen | Add / edit / delete vocab items (word, emoji, category, image, audio URL); category filter tabs; Q&A mode toggle |
| Progress Dashboard | ProgressScreen | Accuracy trend chart; session list with date filter; per-session detail expansion |
| Recording Review | RecordingReviewScreen | Streams child's speech recordings; play/stop audio; 1–5 star rating; free-text comment; save to Firestore |

---

### 5.3 Firebase Authentication — Interface to Flutter App

| Operation | Method Signature | Returns | Notes |
|-----------|-----------------|---------|-------|
| Sign in | signInWithEmailAndPassword(email, password) | UserCredential | Throws FirebaseAuthException on failure |
| Register | createUserWithEmailAndPassword(email, password) | UserCredential | Must be followed by Firestore user doc write and sendEmailVerification |
| Send verification email | user.sendEmailVerification() | Future\<void\> | Requires authenticated user |
| Sign out | signOut() | Future\<void\> | Called immediately after registration to force email verification before access |
| Auth state stream | authStateChanges() | Stream\<User?\> | Emits null on sign-out; used by authStateProvider and GoRouter guard |
| Get current user | FirebaseAuth.instance.currentUser | User? | Synchronous; null if not authenticated |

---

### 5.4 Cloud Firestore — Interface to Flutter App

| Operation | Collection | Method | Notes |
|-----------|------------|--------|-------|
| Create user profile | users/{uid} | set(data) | Called during registration with role, profile fields |
| Read user role | users/{uid} | get() → role field | Used by userRoleProvider on login |
| Create child | children/{childId} | add(data) | Sets linkedUsers=[currentUid], isActiveOnDevice=false |
| Update child | children/{childId} | update(fields) | Used for difficulty, qaMode, isActiveOnDevice, linkedUsers |
| Stream linked children | children where linkedUsers arrayContains uid | snapshots() | Powers linkedChildrenProvider real-time stream |
| Create invite code | inviteCodes/{code} | set(data) | TTL 48 h; used=false |
| Redeem invite code | inviteCodes/{code} + children/{childId} | runTransaction() | Atomic: marks used=true + arrayUnion(uid) on linkedUsers |
| Stream vocab items | vocab/{childId}/items | snapshots() / where('category') | Powers vocabItemsProvider and allVocabItemsProvider |
| CRUD vocab item | vocab/{childId}/items/{id} | add / update / delete | Used by VocabService |
| Write session | sessions/{childId}/sessions | add(data) | Fire-and-forget after each module completion |
| Stream sessions | sessions/{childId}/sessions orderBy timestamp | snapshots() limit N | Powers childSessionsProvider and recentSessionsProvider |
| Stream rewards | rewards/{childId} | snapshots() | Powers rewardProvider; real-time star count |
| Award stars | rewards/{childId} | update({totalStars: FieldValue.increment(5)}) | Atomic increment; called from RewardScreen.initState |
| Unlock badges | rewards/{childId} | update({badges: FieldValue.arrayUnion([...])}) | Called after threshold check in RewardScreen |
| Write recording metadata | recordings/{childId}/recordings | add(data) | storageUrl, word, timestamp, adminScore=null, adminComment=null |
| Stream recordings | recordings/{childId}/recordings orderBy timestamp | snapshots() | Powers Recording Review StreamBuilder |
| Update recording review | recordings/{childId}/recordings/{id} | update({adminScore, adminComment}) | Called from RecordingReviewScreen on Save |

---

### 5.5 Firebase Storage — Interface to Flutter App

| Operation | Method | Path Pattern | Notes |
|-----------|--------|-------------|-------|
| Upload audio file | ref.putFile(File) | recordings/{childId}/{word}_{timestamp}.aac | Called after recording stops; background task |
| Get download URL | ref.getDownloadURL() | — | Returns HTTPS URL; stored in Firestore recording document |
| Upload vocab image | ref.putData(bytes) | vocab_images/{childId}/{filename} | Called from Vocab Manager image picker |
| Stream audio playback | AudioPlayer.play(UrlSource(url)) | — | AudioPlayer downloads from the stored HTTPS URL |

---

### 5.6 Flutter TTS Engine — Interface to Flutter App

| Operation | Method | Description |
|-----------|--------|-------------|
| Speak text | speak(String text) | Sends text to Android TTS engine; plays through device speaker |
| Stop speech | stop() | Immediately halts current speech output |
| Set language | setLanguage('en-US') | Configures the TTS voice and language (called in initState) |
| Set speech rate | setSpeechRate(0.45) | Slows speech to child-friendly pace (0.45 = ~65% normal speed) |
| Set volume | setVolume(1.0) | Maximum volume |
| Completion callback | setCompletionHandler(callback) | Fires when TTS finishes; used by AAC Board to re-enable Speak button |

---

### 5.7 Audio Recorder — Interface to Flutter App

| Operation | Method | Returns | Description |
|-----------|--------|---------|-------------|
| Check permission | hasPermission() | Future\<bool\> | Requests microphone permission from Android OS if not already granted |
| Start recording | start(RecordConfig(encoder: aacLc, bitRate: 128000), path: filePath) | Future\<void\> | Begins audio capture; writes to specified temp .aac file path |
| Stop recording | stop() | Future\<String?\> | Ends capture; returns the final local file path of the saved recording |
| Check recording state | isRecording() | Future\<bool\> | Used in navigation handlers to ensure recorder is stopped before leaving screen |

---

### 5.8 Audio Player — Interface to Flutter App

| Operation | Method | Description |
|-----------|--------|-------------|
| Play local file | play(DeviceFileSource(path)) | Plays a local .aac file from the device temp directory |
| Play remote URL | play(UrlSource(url)) | Streams and plays an audio file from a Firebase Storage HTTPS URL |
| Stop playback | stop() | Halts current playback; triggers onPlayerStateChanged with PlayerState.stopped |
| Player state stream | onPlayerStateChanged | Stream\<PlayerState\> — values: playing, stopped, completed, paused |
| Completion stream | onPlayerComplete | Stream\<void\> — fires once when a track finishes naturally |
| Dispose | dispose() | Releases MediaPlayer resources; called in widget's dispose() |

---

### 5.9 GoRouter — Interface to Flutter App

| Route | Path | Screen | Guard |
|-------|------|--------|-------|
| Profile Picker | / | ProfilePickerScreen | None |
| Confirm Profile | /confirm/:childId | ConfirmProfileScreen | None |
| Child Home | /child/home | ChildHomeScreen | activeChildProvider must be non-null |
| AAC Board | /child/aac | AACBoardScreen | activeChildProvider must be non-null |
| Vocab Learning | /child/vocab | VocabLearningScreen | activeChildProvider must be non-null |
| Speech Practice | /child/speech | SpeechPracticeScreen | activeChildProvider must be non-null |
| Reward | /child/reward | RewardScreen | activeChildProvider must be non-null |
| Admin Login | /admin/login | AdminLoginScreen | Redirects to /admin/dashboard if already authenticated |
| Admin Register | /admin/register | AdminRegisterScreen | Redirects to /admin/dashboard if already authenticated |
| Admin Dashboard | /admin/dashboard | AdminDashboardScreen | Must be authenticated |
| Add Child | /admin/add-child | AddChildScreen | Must be authenticated |
| Progress | /admin/progress/:id | ProgressScreen | Must be authenticated |
| Vocab Manager | /admin/vocab/:id | VocabManagerScreen | Must be authenticated |
| Recordings | /admin/recordings/:id | RecordingReviewScreen | Must be authenticated |
| Enter Invite Code | /admin/link-code | EnterInviteCodeScreen | Must be authenticated |

**Redirect Logic:**
- Unauthenticated user attempts /admin/* (except login/register) → redirect to /admin/login
- Authenticated user attempts /admin/login or /admin/register → redirect to /admin/dashboard
- Any /child/* route without activeChildProvider set → redirect to /

---

### 5.10 Riverpod State Providers — Interface to Presentation Layer

| Provider | Type | Clients | What It Exposes |
|----------|------|---------|-----------------|
| authStateProvider | StreamProvider\<User?\> | GoRouter, ChildHomeScreen, AdminDashboard | Live Firebase Auth user; null when signed out |
| userRoleProvider | FutureProvider\<String?\> | AdminDashboard TopBar | "teacher" or "parent" |
| activeChildProvider | StateProvider\<ChildModel?\> | All child screens, GoRouter | Currently selected child for this session; set by ConfirmProfileScreen, cleared by switch-profile link |
| linkedChildrenProvider | StreamProvider\<List\<ChildModel\>\> | ProfilePickerScreen, Dashboard | Real-time list of children linked to the authenticated user |
| categoriesProvider | StreamProvider\<List\<String\>\> | AACBoardScreen | Sorted unique categories for active child |
| allVocabItemsProvider | StreamProvider\<List\<VocabItem\>\> | VocabLearningScreen, SpeechPracticeScreen | All vocab items for active child (no category filter) |
| vocabItemsProvider | StreamProvider\<List\<VocabItem\>\> | AACBoardScreen | Vocab items filtered by child + selectedCategoryProvider |
| recentSessionsProvider | StreamProvider\<List\<SessionModel\>\> | ChildHomeScreen | Last 10 sessions for active child |
| childSessionsProvider | StreamProvider.family | ProgressScreen | Up to 50 sessions for a given childId |
| rewardProvider | StreamProvider.family | ProfilePickerScreen, ChildHomeScreen, RewardScreen, AdminDashboard | Real-time RewardModel (totalStars, badges[]) for a given childId |

---

## SECTION 6 — DRAWING GUIDE FOR CANVA

Use this guide to lay out the architectural diagram manually in Canva.

### Step 1 — Physical Nodes (outer boxes)

Draw three large rounded rectangles with a thin border and light fill:
- **Node 1 (Android Tablet)** — left side, tall portrait rectangle. Label: "«device» Android Tablet / Samsung SM-X510 / Android 16"
- **Node 2 (Firebase Cloud)** — right side, tall rectangle. Label: "«cloud» Google Firebase Platform / asia-southeast1"
- **Node 3 (Android OS Services)** — below Node 1, smaller rectangle. Label: "«execution environment» Android OS Services Layer"

### Step 2 — Software Components (inner boxes)

Inside **Node 1**, draw four nested horizontal bands (top to bottom):
1. Presentation Layer — light green fill — list screen names
2. State Management Layer — light blue fill — list providers
3. Service Layer — light amber fill — list services
4. Navigation Layer — light grey fill — GoRouter

Inside **Node 2**, draw three side-by-side boxes:
- Firebase Auth (blue icon)
- Cloud Firestore (orange icon)
- Firebase Storage (yellow icon)

Inside **Node 3**, draw three boxes:
- Flutter TTS Engine
- Audio Recorder + Microphone
- Audio Player + Speaker

### Step 3 — Actors

Draw two stick figures to the left of Node 1:
- **Child** — connected with a solid line to "Presentation Layer (Child Screens)"
- **Teacher / Parent** — connected with a solid line to "Presentation Layer (Admin Screens)"

### Step 4 — Communication Links

Draw arrows between nodes:
- **Node 1 ↔ Node 2**: double-headed arrow labelled "HTTPS + gRPC / Firebase SDK / Wi-Fi or mobile data" (use a dashed line for async streams, solid for direct calls)
- **Node 1 ↔ Node 3**: double-headed arrow labelled "Flutter Platform Channel / in-process IPC"

Draw arrows between internal layers (Node 1):
- Presentation → State Management: solid arrow (watches providers)
- State Management → Service Layer: solid arrow (reads services)
- Service Layer → Firebase Cloud: continues via the Node 1 ↔ Node 2 arrow

### Step 5 — Key Communication Path Labels

Add small annotation labels on the arrows for the most important paths:
- **CP-01/03**: Auth sign-in & state stream
- **CP-04/05**: Firestore write & real-time stream
- **CP-06/07**: Storage upload & download URL
- **CP-09/10**: TTS speak & completion callback
- **CP-11/12**: Record start/stop & file path callback

### Step 6 — Colour Coding Legend

| Colour | Meaning |
|--------|---------|
| Green (#2D9B6F) | Application components (on-device Flutter) |
| Blue (#3D8FBF) | Firebase cloud services |
| Amber (#F0A500) | External/OS services |
| Grey | Navigation and infrastructure |
| White | Actor (human) |
