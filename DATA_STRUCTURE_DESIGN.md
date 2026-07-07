# Data Structure Design — SpeakUp! AAC Learning App

This document describes the complete data structure of the SpeakUp! system. It covers the persistent data store (Cloud Firestore), the binary file store (Firebase Storage), the in-memory reactive state (Riverpod), and the Dart model classes that bridge all three. Use it as the authoritative reference for the data design section of the thesis.

---

## SECTION 1 — DATA ARCHITECTURE OVERVIEW

SpeakUp! uses a **three-tier data architecture**:

| Tier | Technology | Purpose | Scope |
|------|-----------|---------|-------|
| Persistent Document Store | Cloud Firestore (NoSQL) | All structured application data — users, children, vocabulary, sessions, recordings, rewards, invite codes | Permanent; shared across devices |
| Binary File Store | Firebase Storage | Audio recordings (.aac) and vocabulary images (.jpg/.png) | Permanent; referenced by Firestore URLs |
| In-Memory Reactive State | Riverpod Providers (Dart) | Active session state, provider caches, UI state | Session-scoped; cleared on app restart |

There is no local SQL database and no offline cache. All reads go to Firestore's real-time streams; all writes go directly to Firestore or Firebase Storage.

---

## SECTION 2 — ENTITY RELATIONSHIP DIAGRAM (ERD) REFERENCE

### Entities and Relationships

| Entity | Multiplicity | Related To | Relationship Description |
|--------|-------------|------------|--------------------------|
| User | 1 | Child | One User can be linked to many Children (via linkedUsers array). Many Users can be linked to the same Child (teacher + parent). Many-to-many. |
| Child | 1 | User | A Child has exactly one creator (createdBy) but may have many linked Users. |
| Child | 1 | VocabItem | One Child owns a private vocabulary collection. One-to-many. |
| Child | 1 | Session | One Child has many Session records. One-to-many. |
| Child | 1 | Recording | One Child has many Recording records. One-to-many. |
| Child | 1 | Reward | One Child has exactly one Reward document. One-to-one. |
| Child | 1 | InviteCode | One Child may have one or more invite codes generated for it, but each code can only be used once. One-to-many. |
| InviteCode | 1 | User | An InviteCode is redeemed by exactly one User (or not at all). One-to-one (at redemption). |
| VocabItem | 1 | Session | Vocab items appear in Session activities but are not directly foreign-keyed in a Session document. Logical relationship only. |

### ERD Table (Crow's Foot Notation Description)

```
User ──────────< LinkedUsers >────────── Child
                (array on Child)
                many-to-many

User ──────────── createdBy ──────────── Child
                (string on Child)
                one-to-many

Child ──────────────────────────────────< VocabItem
                (subcollection vocab/{childId}/items)
                one-to-many

Child ──────────────────────────────────< Session
                (subcollection sessions/{childId}/sessions)
                one-to-many

Child ──────────────────────────────────< Recording
                (subcollection recordings/{childId}/recordings)
                one-to-many

Child ────────────────────────────────── Reward
                (document rewards/{childId})
                one-to-one

Child ──────────────────────────────────< InviteCode
                (collection inviteCodes, childId field)
                one-to-many

InviteCode ────────────────────────────── User
                (redeemed by one user; createdBy field)
                one-to-one (at redemption)
```

---

## SECTION 3 — FIRESTORE COLLECTION HIERARCHY

Firestore organises data as documents inside collections. SpeakUp! uses three top-level collections and four subcollection structures.

```
firestore/
│
├── users/
│     └── {uid}                          ← User profile document
│
├── children/
│     └── {childId}                      ← Child profile document
│
├── inviteCodes/
│     └── {6-digit code}                 ← Invite code document
│
├── vocab/
│     └── {childId}/
│           └── items/
│                 └── {itemId}           ← VocabItem document (subcollection)
│
├── sessions/
│     └── {childId}/
│           └── sessions/
│                 └── {sessionId}        ← SessionModel document (subcollection)
│
├── recordings/
│     └── {childId}/
│           └── recordings/
│                 └── {recordingId}      ← RecordingModel document (subcollection)
│
└── rewards/
      └── {childId}                      ← RewardModel document
```

**Design rationale for subcollections:**
Using `vocab/{childId}/items`, `sessions/{childId}/sessions`, and `recordings/{childId}/recordings` as subcollections rather than top-level collections ensures that queries are always scoped to a single child. This avoids cross-child data leakage and makes Firestore security rules simpler (rules can match on the childId path segment).

---

## SECTION 4 — COMPLETE FIELD SCHEMAS

### 4.1 User Document — `users/{uid}`

Stores the profile and credentials metadata for every Teacher and Parent who registers.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| role | String | String | No | Enum: "teacher" \| "parent" | Role selected during registration; determines which registration steps are shown and which UI features are accessible |
| fullName | String | String | No | Non-empty | Full legal name as entered during registration |
| icNumber | String | String | No | 12 digits stored as "XXXXXX-XX-XXXX" format | Malaysian identity card number; never displayed publicly |
| email | String | String | No | Valid email format; unique across Firebase Auth | Primary login credential and contact address |
| phone | String | String | No | Malaysian format: (+60\|0)[1-9][0-9]{7,9} | Contact phone number |
| address | String | String | No | Non-empty | Home address |
| emailVerified | bool | Boolean | No | Default: false; set to true after email link clicked | Gate for dashboard access; must be true before first login is permitted |
| createdAt | DateTime | Timestamp | No | Server timestamp; set once on creation | Account creation date and time |
| schoolName | String? | String \| null | Yes (null for Parent) | Required for Teacher | Name of the school or therapy centre |
| qualification | String? | String \| null | Yes (null for Parent) | Required for Teacher | Highest academic qualification (e.g., "Bachelor of Special Education") |
| specialisation | String? | String \| null | Yes (null for Parent) | Required for Teacher | Area of specialisation (e.g., "Autism Spectrum Disorder") |
| yearsExp | int? | Integer \| null | Yes (null for Parent) | Required for Teacher; 0 ≤ value ≤ 60 | Years of professional experience |

**Document ID:** Firebase Authentication UID (auto-assigned by Firebase Auth on account creation).

**Who writes it:** `AuthService.register()` — called once during Step 4 of the registration flow.

**Who reads it:** `AuthService.getUserRole()` on login; AdminDashboard TopBar for display name.

---

### 4.2 Child Document — `children/{childId}`

Stores the profile settings for one child. This document is the central linking point between admin users and the child's learning data.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| name | String | String | No | Non-empty | Child's display name shown on profile card and home screen |
| avatarEmoji | String | String | No | Single Unicode emoji character | Animal emoji representing the child (e.g., "🦁") |
| avatarGradientStart | String | String | No | Hex colour: "#RRGGBB" | Start colour of the avatar's circular gradient background |
| avatarGradientEnd | String | String | No | Hex colour: "#RRGGBB" | End colour of the avatar's circular gradient background |
| difficulty | String | String | No | Enum: "beginner" \| "intermediate" \| "advanced" | Learning difficulty level; currently used to inform content selection |
| qaMode | int | Integer | No | Enum: 2 \| 4 | Number of answer choices in Vocabulary Learning (2 = easier, 4 = harder) |
| linkedUsers | List\<String\> | Array of String | No | Each element is a valid Firebase Auth UID; initially contains only createdBy | All admin users (teachers and parents) who have access to this child's data |
| createdBy | String | String | No | Valid Firebase Auth UID | UID of the admin who created this child profile |
| isActiveOnDevice | bool | Boolean | No | Default: false | When true, this child's card shows the pulsing ring and 3-second auto-select countdown on the Profile Picker. Only one child per device should have this set to true at a time. |

**Document ID:** Auto-generated Firestore document ID.

**Who writes it:** `ChildService.createChild()` on Add Child; `ChildService.updateChild()` for settings changes; `InviteService.redeemCode()` for linkedUsers updates.

**Who reads it:** `ChildService.getLinkedChildren()` — queries where linkedUsers arrayContains currentUid.

---

### 4.3 InviteCode Document — `inviteCodes/{code}`

A short-lived, single-use code that a Teacher generates and shares with a Parent to grant them access to a child profile.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| childId | String | String | No | Valid Firestore children document ID | The child this code grants access to |
| createdBy | String | String | No | Valid Firebase Auth UID | UID of the admin who generated this code |
| expiresAt | DateTime | Timestamp | No | Exactly 48 hours after document creation | After this time the code is rejected; checked at redemption time |
| used | bool | Boolean | No | Default: false; set to true atomically on redemption | Prevents the same code from being redeemed more than once |

**Document ID:** A randomly generated 6-digit numeric string (e.g., "849372"). Generated by `InviteService.generateCode()`. The 6-digit string is used directly as the Firestore document ID so lookup is a single `get()` call with no query needed.

**Computed properties (Dart only):**
- `isExpired` → `DateTime.now().isAfter(expiresAt)`
- `isValid` → `!used && !isExpired`

**Who writes it:** `InviteService.generateCode()` on Add Child; `InviteService.redeemCode()` atomically sets used = true.

---

### 4.4 VocabItem Document — `vocab/{childId}/items/{itemId}`

Each document represents one vocabulary word in a child's personalised word list.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| word | String | String | No | Non-empty | The vocabulary word (e.g., "Cat", "Eat") displayed on cards and spoken by TTS |
| emoji | String | String | No | Non-empty; single Unicode emoji | Visual symbol representing the word; shown on AAC Board, Vocab Learning, and Speech Practice |
| category | String | String | No | Non-empty; free-text (admin-defined) | Groups items together (e.g., "Animals", "Food", "Actions"); drives category chip filters |
| imageUrl | String? | String \| null | Yes | Valid HTTPS URL to Firebase Storage or any CDN | Optional photo/illustration for Vocab Learning card; falls back to emoji if null or load fails |
| audioUrl | String? | String \| null | Yes | Valid HTTPS URL | Optional custom audio pronunciation; reserved for future use (TTS is used currently) |

**Document ID:** Auto-generated Firestore document ID.

**Who writes it:** `VocabService.addVocabItem()`, `updateVocabItem()`, `deleteVocabItem()` — called from VocabManagerScreen.

**Who reads it:** `VocabService.watchVocabItems()` and `watchAllVocabItems()` — consumed by Riverpod providers.

---

### 4.5 Session Document — `sessions/{childId}/sessions/{sessionId}`

Records the outcome of one completed learning activity. One document is written per activity completion.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| childId | String | String | No | Valid Firestore children document ID | Child who completed this session; denormalised for easier admin queries |
| module | String | String | No | Enum: "aac" \| "vocab" \| "speech" | Which learning module was used |
| accuracy | double | Number (double) | No | Range: 0.0 to 1.0 | Proportion of correct answers. AAC and Speech sessions always record 1.0. Vocab sessions record correctCount / totalAttempts. |
| wordsAttempted | int | Integer | No | ≥ 0 | Number of words the child interacted with during the session |
| durationSeconds | int | Integer | No | ≥ 0 | Total elapsed time from session start to completion in seconds |
| timestamp | DateTime | Timestamp | No | Server timestamp at write time | Date and time the session was completed; used for ordering and date filtering in Progress Dashboard |

**Document ID:** Auto-generated Firestore document ID.

**Who writes it:** `SessionService.createSession()` — fire-and-forget call from each module screen after completion.

**Who reads it:** `childSessionsProvider` (Progress Screen, limit 50); `recentSessionsProvider` (Child Home Screen, limit 10); `adminSessionsProvider` (Admin Dashboard, across all linked children).

---

### 4.6 Recording Document — `recordings/{childId}/recordings/{recordingId}`

Records metadata about one speech recording submitted by a child during Speech Practice.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| childId | String | String | No | Valid Firestore children document ID | Child who made the recording; denormalised for admin queries |
| storageUrl | String | String | No | Valid Firebase Storage download URL (HTTPS) | Full URL to the .aac audio file in Firebase Storage; used for playback in both Speech Practice and Recording Review |
| word | String | String | No | Non-empty | The target vocabulary word the child was practising when this recording was made |
| timestamp | DateTime | Timestamp | No | Server timestamp at write time | Date and time of the recording; used for ordering in Recording Review |
| adminScore | int? | Integer \| null | Yes | Null until reviewed; range 1–5 when set | Star rating assigned by the teacher or parent during Recording Review |
| adminComment | String? | String \| null | Yes | Null until reviewed; trimmed, non-empty string | Text feedback from the teacher or parent about the child's pronunciation |

**Document ID:** Auto-generated Firestore document ID.

**Who writes it:** `SpeechPracticeScreen._uploadRecording()` on initial creation (adminScore and adminComment are null); `RecordingReviewScreen._save()` updates adminScore and adminComment.

**Who reads it:** `RecordingReviewScreen` via StreamBuilder; `RecordingModel.fromDoc()`.

**Storage path convention:**
The corresponding .aac file in Firebase Storage follows the path: `recordings/{childId}/{word}_{timestamp_ms}.aac`

---

### 4.7 Reward Document — `rewards/{childId}`

Tracks the cumulative stars and earned badges for one child. One document per child; auto-created on first session completion.

| Field | Dart Type | Firestore Type | Nullable | Constraints | Description |
|-------|-----------|----------------|----------|-------------|-------------|
| totalStars | int | Integer | No | ≥ 0; incremented by 5 on each session completion | Running total of stars earned by the child across all activities |
| badges | List\<String\> | Array of String | No | Each element is a badge ID string; see badge table below | Ordered list of badge IDs the child has unlocked; new IDs are appended via FieldValue.arrayUnion |

**Document ID:** The child's Firestore document ID (same as `{childId}`), enabling a direct `get()` without a query.

**Badge ID Milestone Table:**

| Badge ID | Stars Threshold | Label | Emoji |
|----------|----------------|-------|-------|
| badge_10 | 10 | Star Collector | 🌟 |
| badge_25 | 25 | Champion | 🏅 |
| badge_50 | 50 | Brave Explorer | 🦁 |
| badge_100 | 100 | Word Master | 📚 |
| badge_200 | 200 | Super Learner | 🚀 |
| badge_500 | 500 | Legend | 👑 |

**Who writes it:** `RewardScreen.initState()` — calls `FieldValue.increment(5)` on totalStars and `FieldValue.arrayUnion([newBadgeIds])` on badges atomically. If the document does not exist, it is created with `{totalStars: 5, badges: []}`.

**Who reads it:** `rewardProvider` (real-time stream); ChildHomeScreen, ProfilePickerScreen, RewardScreen, AdminDashboard.

---

## SECTION 5 — DART MODEL CLASS SPECIFICATIONS

Each Firestore document type has a corresponding Dart class that handles serialisation and deserialisation.

### 5.1 ChildModel

```
File: lib/models/child_model.dart

Fields:
  id                  String        — Firestore document ID
  name                String
  avatarEmoji         String
  avatarGradientStart String        — hex colour "#RRGGBB"
  avatarGradientEnd   String        — hex colour "#RRGGBB"
  difficulty          String        — "beginner" | "intermediate" | "advanced"
  qaMode              int           — 2 | 4
  linkedUsers         List<String>  — list of Firebase Auth UIDs
  createdBy           String        — Firebase Auth UID
  isActiveOnDevice    bool

Constructors:
  ChildModel({...})                        — named, all required
  ChildModel.fromJson(id, Map)             — deserialises from Firestore document data
  ChildModel.fromDoc(DocumentSnapshot)     — deserialises from Firestore snapshot

Methods:
  Map<String, dynamic> toJson()            — serialises for Firestore write (excludes id)
  ChildModel copyWith({...})               — immutable update pattern
```

### 5.2 RewardModel

```
File: lib/models/reward_model.dart

Fields:
  childId      String        — Firestore document ID (same as child ID)
  totalStars   int           — cumulative star count; default 0
  badges       List<String>  — list of earned badge ID strings; default []

Constructors:
  RewardModel({...})
  RewardModel.fromJson(childId, Map)
  RewardModel.fromDoc(DocumentSnapshot)

Methods:
  Map<String, dynamic> toJson()
  RewardModel copyWith({...})
```

### 5.3 SessionModel

```
File: lib/models/session_model.dart

Fields:
  id               String    — Firestore document ID
  childId          String    — references children/{childId}
  module           String    — "aac" | "vocab" | "speech"
  accuracy         double    — 0.0 to 1.0
  wordsAttempted   int       — ≥ 0
  durationSeconds  int       — ≥ 0
  timestamp        DateTime  — converted from Firestore Timestamp

Constructors:
  SessionModel({...})
  SessionModel.fromJson(id, Map)
  SessionModel.fromDoc(DocumentSnapshot)

Methods:
  Map<String, dynamic> toJson()             — converts DateTime back to Timestamp
  SessionModel copyWith({...})
```

### 5.4 RecordingModel

```
File: lib/models/recording_model.dart

Fields:
  id             String    — Firestore document ID
  childId        String    — references children/{childId}
  storageUrl     String    — Firebase Storage download URL
  word           String    — target vocabulary word
  timestamp      DateTime
  adminScore     int?      — 1 to 5; null until reviewed
  adminComment   String?   — null until reviewed

Constructors:
  RecordingModel({...})
  RecordingModel.fromJson(id, Map)
  RecordingModel.fromDoc(DocumentSnapshot)

Methods:
  Map<String, dynamic> toJson()
  RecordingModel copyWith({...})
```

### 5.5 InviteCodeModel

```
File: lib/models/invite_code_model.dart

Fields:
  code        String    — 6-digit numeric string; also the Firestore document ID
  childId     String    — references children/{childId}
  createdBy   String    — Firebase Auth UID
  expiresAt   DateTime  — exactly 48 hours after creation
  used        bool      — default false

Constructors:
  InviteCodeModel({...})
  InviteCodeModel.fromJson(code, Map)
  InviteCodeModel.fromDoc(DocumentSnapshot)

Computed properties:
  bool get isExpired  — DateTime.now().isAfter(expiresAt)
  bool get isValid    — !used && !isExpired

Methods:
  Map<String, dynamic> toJson()
  InviteCodeModel copyWith({...})
```

### 5.6 VocabItem

```
File: lib/services/vocab_service.dart  (defined inline with VocabService)

Fields:
  id         String    — Firestore document ID
  word       String
  emoji      String
  category   String
  imageUrl   String?
  audioUrl   String?

Constructors:
  VocabItem({...})
  VocabItem.fromDoc(DocumentSnapshot)

Methods:
  Map<String, dynamic> toJson()
  VocabItem copyWith({...})
```

---

## SECTION 6 — DATA RELATIONSHIPS AND FOREIGN KEYS

Firestore is a NoSQL document store with no native foreign keys or joins. SpeakUp! implements relationships using these patterns:

| Relationship | Pattern Used | Fields Involved | Enforcement |
|-------------|-------------|-----------------|-------------|
| User → Child (linked) | Array containment | `children.linkedUsers[]` contains User UID | Firestore query: `arrayContains(uid)`; atomically updated by InviteService transaction |
| User → Child (creator) | String reference | `children.createdBy` = User UID | Written once on creation; never updated |
| Child → VocabItem | Subcollection path | Path `vocab/{childId}/items` embeds childId | Path-based; no separate field needed |
| Child → Session | Subcollection path | Path `sessions/{childId}/sessions` embeds childId; also `session.childId` field (denormalised) | Denormalised for admin cross-child queries |
| Child → Recording | Subcollection path | Path `recordings/{childId}/recordings`; also `recording.childId` field (denormalised) | Same as above |
| Child → Reward | Document ID match | `rewards/{childId}` — document ID equals child's document ID | Direct `get()` without query needed |
| InviteCode → Child | String reference | `inviteCodes.childId` = Child document ID | Read at redemption to find the correct child document |

---

## SECTION 7 — FIELD VALIDATION RULES

These are the validation constraints applied at the application layer (before writing to Firestore).

### Registration Form Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| Full Name | Non-empty string | "Full name is required." |
| IC Number | Exactly 12 digits after stripping dashes; matches `^\d{12}$` | "Enter a valid IC number (e.g. 900101-01-1234)." |
| Email Address | Matches `^[\w.+-]+@[\w-]+\.[a-z]{2,}$` | "Enter a valid email address." |
| Phone Number | Matches `^(\+?60\|0)[1-9][0-9]{7,9}$` | "Enter a valid Malaysian phone number (e.g. 0123456789)." |
| Home Address | Non-empty string | "Home address is required." |
| School / Centre Name | Non-empty (Teacher only) | "School or centre name is required." |
| Highest Qualification | Non-empty (Teacher only) | "Highest qualification is required." |
| Specialisation | Non-empty (Teacher only) | "Specialisation is required." |
| Years of Experience | Parseable integer; 0 ≤ value ≤ 60 (Teacher only) | "Enter valid years of experience." |
| Password | Length ≥ 8; contains `[A-Z]`; contains `[0-9]` | "Password must be at least 8 characters." / "…one uppercase letter." / "…one number." |
| Confirm Password | Must equal Password field | "Passwords do not match." |

### Add Child Form Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| Child Name | Non-empty string | "Please enter the child's name." |
| Difficulty | One of "beginner" \| "intermediate" \| "advanced" | UI enforces via radio buttons; no free text |
| Q&A Mode | One of 2 \| 4 | UI enforces via selection chips |

### Vocab Manager Form Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| Word | Non-empty | "Word, emoji, and category are required." |
| Emoji | Non-empty | "Word, emoji, and category are required." |
| Category | Non-empty | "Word, emoji, and category are required." |

### Invite Code Redemption Validation

| Condition | Check | Error Message |
|-----------|-------|---------------|
| Code length | Exactly 6 characters | Button disabled until 6 digits entered |
| Code exists | Firestore document found | "Invalid code. Please check and try again." |
| Code not used | `used == false` | "This invite code has already been used." |
| Code not expired | `expiresAt > now` | "This invite code has expired (valid for 48 hours)." |

---

## SECTION 8 — DATA ACCESS PATTERNS

These are the Firestore read patterns used throughout the app.

### Real-Time Streams (Firestore .snapshots())

| Provider | Collection Path | Filter / Order | Usage |
|----------|----------------|----------------|-------|
| linkedChildrenProvider | `children` | where linkedUsers arrayContains uid | Profile Picker, Admin Dashboard — live list of child profiles |
| categoriesProvider | `vocab/{childId}/items` | none — extracts distinct category field values | AAC Board category sidebar |
| vocabItemsProvider | `vocab/{childId}/items` | where category == selectedCategory | AAC Board symbol grid |
| allVocabItemsProvider | `vocab/{childId}/items` | none | Speech Practice, Vocab Learning |
| adminAllVocabProvider | `vocab/{childId}/items` | none | Vocab Manager Screen |
| recentSessionsProvider | `sessions/{childId}/sessions` | orderBy timestamp DESC, limit 10 | Child Home recent activity |
| childSessionsProvider | `sessions/{childId}/sessions` | orderBy timestamp DESC, limit 50 | Progress Dashboard |
| rewardProvider | `rewards/{childId}` | single document watch | Profile Picker stars, Child Home badge progress, Reward Screen |
| RecordingReviewScreen | `recordings/{childId}/recordings` | orderBy timestamp DESC | Recording Review list |

### One-Time Reads (Firestore .get())

| Operation | Collection Path | When |
|-----------|----------------|------|
| getUserRole | `users/{uid}` | On login, to get role for dashboard display |
| redeemCode (transaction read) | `inviteCodes/{code}` | When admin enters a 6-digit invite code |
| adminSessionsProvider | `sessions/{childId}/sessions` (for each linked child) | Admin Dashboard stat cards |

### Writes (Firestore .set / .add / .update)

| Operation | Path | When | Method |
|-----------|------|------|--------|
| Create user | `users/{uid}` | Registration | set(data) |
| Create child | `children/{newId}` | Add Child | add(data) |
| Update child settings | `children/{childId}` | Difficulty/qaMode change, setActiveChild, invite redemption | update(fields) |
| Create invite code | `inviteCodes/{code}` | Add Child (after child created) | set(data) with code as document ID |
| Redeem code (transaction) | `inviteCodes/{code}` + `children/{childId}` | Enter Invite Code | runTransaction: update used=true + arrayUnion(uid) |
| Add vocab item | `vocab/{childId}/items` | Vocab Manager add | add(data) |
| Update vocab item | `vocab/{childId}/items/{id}` | Vocab Manager edit | update(fields) |
| Delete vocab item | `vocab/{childId}/items/{id}` | Vocab Manager delete | delete() |
| Write session | `sessions/{childId}/sessions` | After each module completion | add(data) |
| Write recording metadata | `recordings/{childId}/recordings` | After audio upload completes | add(data) |
| Update recording review | `recordings/{childId}/recordings/{id}` | Admin saves score/comment | update({adminScore, adminComment}) |
| Award stars | `rewards/{childId}` | Reward Screen initState | update({totalStars: FieldValue.increment(5)}) or set if not exists |
| Unlock badges | `rewards/{childId}` | Reward Screen badge check | update({badges: FieldValue.arrayUnion([...])}) |

---

## SECTION 9 — FIREBASE STORAGE STRUCTURE

| Path Pattern | File Type | Who Writes | Who Reads | Purpose |
|-------------|-----------|------------|-----------|---------|
| `recordings/{childId}/{word}_{timestamp_ms}.aac` | AAC audio | SpeechPracticeScreen (background task) | AudioPlayer in Speech Practice and Recording Review | Child's recorded voice for a specific vocabulary word |
| `vocab_images/{childId}/{childId}_{timestamp_ms}.{ext}` | JPEG or PNG | VocabManagerScreen (image picker upload) | CachedNetworkImage in Vocab Learning | Admin-uploaded illustration for a vocabulary item |

**Storage file lifecycle:**
1. Recording is captured to a local temp file: `{app_temp_dir}/speech_{timestamp_ms}.aac`
2. After recording stops, the file is uploaded to Firebase Storage (background, silent on failure)
3. On upload completion, the storage URL is written to Firestore
4. The local temp file remains in the device cache directory until Android clears it automatically

---

## SECTION 10 — IN-MEMORY STATE STRUCTURES (RIVERPOD)

These data structures exist only in device RAM during an active app session. They are not persisted anywhere.

### Active Child Session

| Provider | Type | Initial Value | Set By | Cleared By |
|----------|------|--------------|--------|------------|
| activeChildProvider | StateProvider\<ChildModel?\> | null | ConfirmProfileScreen on "Yes, that's me!" tap | switch-profile link in ChildHomeScreen; GoRouter redirect to / |
| selectedCategoryProvider | StateProvider\<String?\> | null | AACBoardScreen (auto-selects first category) | Never explicitly cleared; stale value handled by per-screen local state |

### Local Screen State (not in Riverpod; held in StatefulWidget state)

| Screen | Local State Field | Type | Purpose |
|--------|-----------------|------|---------|
| VocabLearningScreen | _localCategory | String? | Category selected in this Vocab session; isolated from global selectedCategoryProvider |
| VocabLearningScreen | _items | List\<VocabItem\>? | Items for current category; null = not yet initialised |
| VocabLearningScreen | _correctCount | int | Correct answers so far this session |
| VocabLearningScreen | _totalAttempts | int | Total answer taps this session |
| SpeechPracticeScreen | _phase | enum _Phase | picking \| recording — controls which view is shown |
| SpeechPracticeScreen | _selectedItem | VocabItem? | The word the child chose to practise |
| SpeechPracticeScreen | _recordState | enum _RecordState | idle \| recording \| recorded \| playing |
| SpeechPracticeScreen | _recordingPath | String? | Local temp file path of the last recording |
| AACBoardScreen | _sentence | List\<String\> | Words accumulated in the sentence bar |
| RecordingReviewScreen._RecordingListState | _playingId | String? | ID of recording currently playing; null = none |
| _RecordingCardState | _score | int? | Local edited star score before Save |
| _RecordingCardState | _commentCtrl | TextEditingController | Live comment text before Save |

---

## SECTION 11 — DATA LIFECYCLE SUMMARY

### Create

| Entity | Trigger | Service/Screen |
|--------|---------|----------------|
| User | Teacher or Parent completes registration Step 4 | AuthService.register() |
| Child | Admin taps "Create Profile & Generate Code" | ChildService.createChild() |
| InviteCode | Auto-generated immediately after Child creation | InviteService.generateCode() |
| VocabItem | Admin taps "Add Word" in Vocab Manager | VocabService.addVocabItem() |
| Session | Child completes a learning module | SessionService.createSession() |
| Recording | Child finishes recording a word in Speech Practice | SpeechPracticeScreen._uploadRecording() |
| Reward | First session completion for a child | RewardScreen.initState() (creates if not exists) |

### Read

All reads are via Riverpod StreamProviders (real-time) or one-time FutureProviders. No screen reads Firestore directly except RecordingReviewScreen (StreamBuilder) and AdminDashboard (adminSessionsProvider FutureProvider).

### Update

| Entity | What Changes | Who Changes It |
|--------|-------------|----------------|
| User | emailVerified (via Firebase Auth, not Firestore) | Firebase Auth system after link click |
| Child | difficulty, qaMode, isActiveOnDevice | Admin via VocabManager or Dashboard |
| Child | linkedUsers (arrayUnion) | InviteService.redeemCode() |
| InviteCode | used = true | InviteService.redeemCode() (atomic with Child update) |
| VocabItem | Any field | VocabService.updateVocabItem() |
| Recording | adminScore, adminComment | RecordingReviewScreen._save() |
| Reward | totalStars (increment), badges (arrayUnion) | RewardScreen.initState() |

### Delete

| Entity | Trigger | Service |
|--------|---------|---------|
| VocabItem | Admin taps delete icon and confirms in Vocab Manager | VocabService.deleteVocabItem() |

No other entities are deleted by the application. Users, children, sessions, recordings, rewards, and invite codes are retained permanently (no data purging in Phase 1–7 scope).

---

## SECTION 12 — DRAWING GUIDE FOR ENTITY RELATIONSHIP DIAGRAM

Use this guide to draw the ERD in Canva.

### Entity Box Layout

Draw each entity as a rectangle with:
- **Header row**: Entity name (bold, coloured background)
- **Key row**: Primary key field marked with (PK) or (FK)
- **Attribute rows**: Field name | Data type | Null?

### Suggested Canva Layout (left to right)

```
[User] ──────────────────< [Child] >──────────── [Reward]
                               │
              ┌────────────────┼──────────────────┐
              ▼                ▼                   ▼
          [VocabItem]      [Session]          [Recording]

[InviteCode] ──────────────── [Child]
```

### Relationship Line Labels

| Line | Notation | Label |
|------|----------|-------|
| User to Child (linkedUsers) | crow's-foot many on Child side | "links to (M:N via array)" |
| User to Child (createdBy) | one on User, many on Child | "creates (1:N)" |
| Child to VocabItem | one on Child, many on VocabItem | "has vocab items (1:N)" |
| Child to Session | one on Child, many on Session | "has sessions (1:N)" |
| Child to Recording | one on Child, many on Recording | "has recordings (1:N)" |
| Child to Reward | one on each side | "has reward (1:1)" |
| Child to InviteCode | one on Child, many on InviteCode | "generates codes (1:N)" |
| InviteCode to User | many on InviteCode, one on User | "redeemed by (N:1)" |

### Colour Coding

| Colour | Entity Group |
|--------|-------------|
| Green (#2D9B6F tint) | Child, VocabItem, Session, Recording, Reward |
| Blue (#3D8FBF tint) | User |
| Amber (#F0A500 tint) | InviteCode |
