# SpeakUp! — Interface Description

A screen-by-screen breakdown of every page in the app: what it does, what's on it, and how you move between them.

---

## Screen 0 — Profile Picker

> The very first thing anyone sees when they open the app. Designed for a child to tap their own picture and get going — or for an adult to quietly slip into the admin side without drawing attention.

| Aspect | Detail |
|---|---|
| **Purpose** | Lets a child pick their profile and enter the app. Also the entry point for admins via a small, de-emphasised link. |
| **Background** | Warm three-stop gradient from green-light → off-white → amber-light. Full-bleed, no scaffold chrome — feels more like a welcome mat than a screen. |
| **Header** | "Who's here today? 👋" heading with "Tap your picture to start" subtitle on the left. A tiny 🔒 Admin link sits top-right, intentionally low-contrast so a child won't notice it. |
| **Entry animation** | The whole screen fades in and rises slightly on first render. |

**Profile card grid (normal state)**

| Aspect | Detail |
|---|---|
| **Layout** | Centred `Wrap` of 144 px wide profile cards, spacing 12 px, cards wrap to new rows as needed. Cards stagger in with a per-index delay (80 ms each). |
| **Profile card** | Rounded card with: a 60 × 60 circular gradient avatar (two colours unique to each child) containing their emoji, the child's name in title text, and a ⭐ star count below. |
| **Active card** | The last child to use the device is marked `isActiveOnDevice`. Their card gets a green border, a pulsing green glow ring (animated, repeating), and a green countdown bar at the bottom. The bar fills over 3 seconds and, when it completes, auto-navigates to the Confirm Profile screen — no tap needed. Inactive cards sit at 65% opacity. |
| **Spring tap** | All cards use a spring-press animation on tap for a tactile feel. |

**Empty / error states**

| State | What shows |
|---|---|
| Auth still loading | Centred green spinner — shown only for the first cold-start frame. |
| No admin has ever logged in | 🔐 card: "Set up this device" + explanation + "Admin Login" primary button. |
| Admin logged in but no children added | 😊 card: "No profiles yet" + "Admin Dashboard" secondary button. |
| Firestore read error | 😕 card: "Something went wrong — check your connection and restart the app." |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap a profile card (or countdown completes) | → Confirm Profile screen (`/confirm/:childId`) |
| Tap 🔒 Admin (top-right link) | → Screen 1 (Admin Login) |
| Tap "Admin Login" button (setup state) | → Screen 1 (Admin Login) |
| Tap "Admin Dashboard" button (no-children state) | → Screen 7a (Admin Dashboard) |

---

### Screen 0b — Confirm Profile

> A single-question interstitial between picking a profile and entering the app. Just big enough to make sure the right child selected themselves — and small enough not to slow anyone down.

| Aspect | Detail |
|---|---|
| **Purpose** | Identity confirmation step. Prevents one child accidentally launching another child's session. |
| **Background** | Two-stop gradient, green-light → off-white. Calm and simple. |
| **Back link** | "← go back" in tiny low-contrast text, top-left. Adults can find it; children will ignore it. Uses `context.pop()` if a back stack exists, otherwise falls back to `/`. |
| **Avatar** | The selected child's 120 × 120 circular gradient avatar with large shadow — the centrepiece of the screen. |
| **Name** | Child's name in display (largest) text, centred below the avatar. |
| **Subtitle** | "Is this you?" in soft ink — conversational, friendly. |
| **CTA button** | "Yes, that's me! 🎉" — 280 px wide green primary button. Sets the `activeChildProvider` then navigates to Child Home on the next frame. |
| **Entry animation** | Avatar + text + button fade in and rise together. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap "Yes, that's me! 🎉" | → Screen 2 (Child Home) |
| Tap "← go back" | → Screen 0 (Profile Picker) |

---

## Screen 1 — Admin Login

> The front door for parents and teachers. Clean, focused, and to the point — just enough to get you in without any fuss.

| Aspect | Detail |
|---|---|
| **Purpose** | Authenticates an existing parent or teacher account via Firebase. |
| **Background** | Solid off-white (`AppColors.bg`) — deliberately calm so nothing competes with the form. |
| **Top icon** | Large 🔐 emoji centred above the heading, sets the tone at a glance. |
| **Heading** | "Admin Login" in the app's heading style, with a soft subtitle: *"Sign in to manage children's profiles."* |
| **Form card** | Rounded card with a soft shadow containing two fields. |
| **Email field** | Labelled text input, email keyboard, `textInputAction: next` so the keyboard jumps straight to password. |
| **Password field** | Obscured by default; has a show/hide eye toggle on the right. Submits the form on keyboard "done". |
| **Focus ring** | Each field grows a green glow ring when focused — a nice bit of polish that tells you exactly where you are. |
| **Error banner** | A rose-coloured banner with an icon slides in below the fields when credentials are wrong or the form is incomplete. Maps common Firebase error codes to plain-language messages (e.g. "Email or password is incorrect."). |
| **Sign In button** | Full-width green pill. Swaps to a spinner while the request is in flight so you know something's happening. |
| **"New here?" divider** | Soft divider with inline label between the sign-in button and the register button. |
| **Create an Account button** | Secondary (outlined) full-width button. |
| **Back link** | Low-contrast "← Back to child screen" text link at the bottom — adults only need to find this, children won't. |
| **Entry animation** | The whole form fades in and slides up slightly on load. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Successful sign-in | Router auto-redirects → `/admin/dashboard` |
| Tap "Create an Account" | → Screen 1b (Admin Register) |
| Tap "← Back to child screen" | → `/` (Profile Picker) |

---

## Screen 1b — Admin Register (Multi-Step)

> A guided wizard that walks a new parent or teacher through account creation without overwhelming them. Parents get three steps; teachers get four.

---

### Step 0 — Role Selection

| Aspect | Detail |
|---|---|
| **Purpose** | Lets the user declare whether they're a Teacher or a Parent before any other information is collected. |
| **Background** | Soft gradient from green-light to sky-light — warmer and more welcoming than the login screen. |
| **Greeting** | 👋 emoji + "How will you use SpeakUp?" heading and "Choose your role to get started" subtitle. |
| **Teacher card** | Emoji 👩‍🏫, title "Teacher", description "School or therapy centre staff managing multiple children." Outlined card with a spring-tap press animation. |
| **Parent card** | Emoji 👨‍👩‍👧, title "Parent", description "Family member supporting their child at home." Matching card with sky-blue accent. |
| **Selection feedback** | Selected card gets a coloured border + background fill. A small hint message animates in below: teachers see "4 quick steps — includes your professional details"; parents see "3 quick steps — you can add your child's profile after signing in." |
| **Continue button** | Fades to full opacity once a role is chosen; stays slightly transparent until then. |
| **Back link** | "← Back to Login" text link at the bottom. |

**Navigation from Step 0**

| Trigger | Destination |
|---|---|
| Tap a role card + Continue | → Step 1 (Personal Info) |
| Tap "← Back to Login" | → Screen 1 (Admin Login) |

---

### Left Sidebar (Steps 1–3/4)

| Aspect | Detail |
|---|---|
| **Purpose** | Persistent progress indicator visible on every form step. Grounds the user — they always know where they are and how much is left. |
| **Contents** | SpeakUp! logo + step list (numbered circles). Completed steps show a green check. The active step is highlighted. Upcoming steps are dimmed. |
| **Role badge** | Small coloured chip at the bottom showing either "👩‍🏫 Teacher" or "👨‍👩‍👧 Parent" as a quiet reminder. |
| **Teacher steps** | Personal Info → Professional Info → Set Password |
| **Parent steps** | Personal Info → Set Password |

---

### Step 1 — Personal Information

| Aspect | Detail |
|---|---|
| **Purpose** | Collects identity and contact details. Required for all roles. |
| **Fields** | Full Name, IC / ID Number (auto-formats to `000000-00-0000`), Email Address, Phone Number (Malaysian format), Home Address (multi-line). All five are required. |
| **Inline validation** | Each field validates on "Continue" tap. Error messages appear directly beneath the offending field in rose text. Fields go green-bordered when filled correctly. |
| **Back / Continue row** | "← Back" secondary button (left) + "Continue →" primary button (right). |

**Navigation from Step 1**

| Trigger | Destination |
|---|---|
| Continue (Teacher) | → Step 2 (Professional Info) |
| Continue (Parent) | → Step 3 (Set Password) |
| Back | → Step 0 (Role Selection) |

---

### Step 2 — Professional Details (Teachers only)

| Aspect | Detail |
|---|---|
| **Purpose** | Gathers the teacher's school and professional background. Parents skip this step entirely. |
| **Fields** | School / Centre Name, Highest Qualification, Specialisation, Years of Experience — all inside a green-tinted card labelled "🏫 School / Centre Details." |
| **Privacy note** | A small lock-icon row at the bottom: "Your professional info is not shared publicly." |
| **Validation** | All fields required. Years of Experience must be a sensible number. |

**Navigation from Step 2**

| Trigger | Destination |
|---|---|
| Continue | → Step 3 (Set Password) |
| Back | → Step 1 (Personal Info) |

---

### Step 3 — Set Password

| Aspect | Detail |
|---|---|
| **Purpose** | Final credential step before account creation. |
| **Fields** | Password (obscured, with show/hide toggle) + Confirm Password. |
| **Strength bar** | A four-segment animated bar appears as soon as you start typing. Segments fill from rose → amber → green as the password gets stronger. Labels: Weak / Fair / Good / Strong. |
| **Requirements** | Minimum 8 characters, at least one uppercase letter, at least one number. |
| **Parent info card** | For parents only: a sky-blue info card reads "After signing in, you can add your child's profile from your dashboard using an invite code." Gentle nudge about the next logical step. |
| **Error banner** | Catches duplicate-email and network errors gracefully. |
| **Create Account button** | Swaps to a spinner while Firebase creates the account. |

**Navigation from Step 3**

| Trigger | Destination |
|---|---|
| Successful account creation | → Step 4 (Success) |
| Back (Teacher) | → Step 2 (Professional Info) |
| Back (Parent) | → Step 1 (Personal Info) |

---

### Step 4 — Success

| Aspect | Detail |
|---|---|
| **Purpose** | Celebrates account creation and tells the user what to do next. |
| **Visuals** | Green-to-white gradient background. Animated green check circle that scales in with a spring. "You're all set!" heading. |
| **Info cards** | Two cards animate in staggered: 📧 "Check your email — We sent a verification link. Click it before signing in." and 👶 "Next: add a child profile — From your dashboard, add a child and share the invite code." |
| **CTA** | "Go to Login →" primary button. |

**Navigation from Step 4**

| Trigger | Destination |
|---|---|
| Tap "Go to Login →" | → Screen 1 (Admin Login) |

---

## Screen 2 — Child Home / Main Menu

> The child's personal launchpad. Greets them by name, shows how many stars they've collected, and gives them three big doors to choose from.

| Aspect | Detail |
|---|---|
| **Purpose** | Central hub for the child after their profile is selected. Gives a sense of ownership and progress before any activity starts. |
| **Background** | Soft off-white, consistent with the rest of the app — no jarring colour changes when entering child mode. |
| **Header** | Time-based greeting ("Good morning / afternoon / evening, [Name]! 👋") on the left. ⭐ star count chip on the right, amber-coloured so it pops. |
| **Left panel — Progress card** | Shows the child's current star count, a green progress bar toward the next badge milestone, and a badge count. Gives kids something concrete to look forward to. |
| **Left panel — Recent activity card** | A small list of the last five sessions (emoji, module name, date, accuracy %). If there are no sessions yet, an encouraging 🌱 empty state appears. |
| **Right panel — Module cards** | Three large tappable cards, each with a coloured emoji circle, title, subtitle, and right arrow. They slide in from the right with a staggered delay. |
| **AAC Board card** | 🗣️ blue — "Build sentences and speak." |
| **Vocab Learning card** | 📚 amber — "Learn new words with pictures." |
| **Speech Practice card** | 🎤 rose — "Record and listen to yourself." |
| **"← profiles" link** | Subtle low-contrast link at the bottom-left. Designed to be invisible to children but findable by an adult who wants to switch child profiles. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap AAC Board card | → Screen 3 (AAC Communication Board) |
| Tap Vocab Learning card | → Screen 4 (Vocabulary Learning) |
| Tap Speech Practice card | → Screen 5 (Speech Practice) |
| Tap "← profiles" | → `/` (Profile Picker), clears active child |

---

## Screen 3 — AAC Communication Board

> A symbol-based communication tool. The child taps pictures to build a sentence, then hits Speak to hear it read aloud.

| Aspect | Detail |
|---|---|
| **Purpose** | Augmentative and Alternative Communication board — lets non-verbal or minimally verbal children construct and speak sentences using vocabulary symbols. |
| **Layout** | Two-column layout: narrow left sidebar + main content area. |
| **Left sidebar** | Fixed 120 px wide. White card background with a right border. Contains a Home button at the top (green house icon + label) and a scrollable list of vocabulary categories below it. |
| **Category items** | Tappable. Selected category gets a green-light background fill. Unselected items are plain text. |
| **Sentence bar** | Horizontal strip at the top of the main area, 72 px tall. When empty it shows a placeholder: "Tap symbols to build a sentence…". When words are added they appear as scrollable WordPill chips (each with an × to remove). |
| **Clear button** | Only appears when the sentence has words. Labelled "Clear", outlined style. |
| **Speak button** | Green pill button. Active (green + shadow) when there are words and the TTS is idle. Disabled grey when empty. Changes label to "Speaking…" and disables during TTS playback so the child can't double-fire it. |
| **Symbol grid** | Main area below the sentence bar. Responsive grid (max 130 px per cell, square aspect ratio). Each SymbolCard shows an emoji + word label. |
| **Empty category state** | If a category has no words yet: 📭 illustration + "No symbols in '[category]' yet" + "An admin can add vocab items from the dashboard." |
| **Session logging** | Each time Speak is tapped, a session record is written to Firestore (module: aac, accuracy: 1.0, words attempted: sentence length). |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap Home (sidebar top button) | → Screen 2 (Child Home) |

---

## Screen 4 — Vocabulary Learning (Guided Question Activity)

> A picture-matching quiz. A word card on the left, answer buttons on the right. Get five right in a row and you earn your stars.

| Aspect | Detail |
|---|---|
| **Purpose** | Builds word–image association through a gentle, repeating quiz loop. Children match a word card to the correct answer from a set of choices. |
| **Layout** | Horizontal bar at the top (Home button + category chips) and a two-column game area below. |
| **Category bar** | Home button (green, left-bordered) + horizontally scrollable amber chip row. Switching categories re-shuffles and restarts the quiz. |
| **Left panel — Vocab card (flex 3)** | Large card showing the target word's image (from Firebase Storage if available, otherwise a large emoji placeholder on an amber background) + word label in display text at the bottom + a 🔊 sky-blue speak button. |
| **Right panel — Answer panel (flex 2)** | "What is this?" heading, then 2 or 4 choice buttons depending on the child's Q&A mode setting (configurable per child by admin). Star progress row at the bottom. |
| **2-choice mode** | Two side-by-side full-height buttons. |
| **4-choice mode** | 2 × 2 button grid. |
| **Answer feedback** | Correct answer: button turns green + border. Wrong answer: rose + red border; other buttons dim to 45% opacity. A FeedbackToast animates in ("Correct! 🎉" or "Try again!"). The game auto-advances after 1.2 seconds. |
| **Star progress** | Row of ☆ stars below the choices, filling as ⭐ for each correct answer. Target is 5 correct answers. |
| **Session end** | On the 5th correct answer, the session is logged to Firestore and the screen navigates to the Reward screen. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap Home (category bar, left) | → Screen 2 (Child Home) |
| 5th correct answer | → Reward screen (`/child/reward`) |

---

## Screen 5 — Speech Practice

> A two-phase flow: first the child picks a word, then they listen to it, record themselves saying it, and play back their own voice.

---

### Phase A — Word Picker

| Aspect | Detail |
|---|---|
| **Purpose** | Lets the child choose which word they want to practise before the recording starts. |
| **Background** | Rose-light — the whole screen uses a warm pink palette to distinguish Speech Practice from the other modules. |
| **Header** | "Speech Practice 🎤" heading + a Home button (rose-coloured) on the right. |
| **Subtitle** | "Which word do you want to practise today?" — conversational, child-facing copy. |
| **Category chips** | Horizontal scrollable row including an "All" chip plus one chip per category. Rose colour accent for selected state. |
| **Word grid** | Responsive grid of SymbolCards (emoji + word label), same layout as the AAC board. Tapping any card moves to Phase B. |
| **Empty state** | If no vocab has been added: 📭 + "No words yet" + "An admin can add vocab items from the dashboard." |

---

### Phase B — Recorder

| Aspect | Detail |
|---|---|
| **Purpose** | Guides the child through listening to the correct pronunciation, recording their own attempt, and playing it back. |
| **Header** | "← Choose another word" rose back-link. |
| **Left panel — Word card (flex 3)** | Full-height white card centred on the emoji (100 px) + word in display text. A "✓ Recording saved" green row fades in once a recording exists. |
| **Right panel — Controls (flex 2)** | Four stacked action buttons. |
| **🔊 Listen button** | Sky-blue. Plays the TTS pronunciation of the word. |
| **🎙️ Record button** | Rose. Press once to start recording, press again (now labelled "⏹ Stop Recording") to stop. When a recording exists the button turns green and labels "✓ Recorded" — tapping it again is disabled (no double-recording). |
| **Waveform animation** | Seven animated bars pulse while recording is active. |
| **▶ Play Back button** | Amber. Only enabled after a recording exists. Plays the saved .aac file from the device. Switches label/colour to "⏹ Stop" during playback. |
| **Finish button** | Green. Can be tapped any time. Logs the session, uploads the recording to Firebase Storage + Firestore (for admin review), and navigates to the Reward screen. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap Home (picker header) | → Screen 2 (Child Home) |
| Tap "← Choose another word" | → Phase A (Picker), within same screen |
| Tap Finish | → Reward screen (`/child/reward`) |

---

## Screen 6 — Progress Dashboard (Parent / Therapist)

> A detailed view of one child's performance over time — charts, module breakdown, and a full session history. Parents and teachers come here to see how a child is really getting on.

| Aspect | Detail |
|---|---|
| **Purpose** | Gives parents and therapists a data-driven picture of a child's activity across all three learning modules. |
| **Layout** | Admin sidebar (left) + content area (right). Warm parchment background (`#F0EDE8`). |
| **Header bar** | "Progress" heading + "← Dashboard" back link (top-right). |
| **Child selector** | Appears only when more than one child is linked to the account. Horizontally scrollable row of avatar + name chips; the selected child is highlighted green. Switching updates all charts and history in place. |
| **Left column (flex 3)** | Accuracy Trend card + Module Breakdown card. |
| **Accuracy Trend card** | Line chart (fl_chart) showing average accuracy % for each of the last 7 days. Days with no sessions are simply skipped. Labelled with weekday names. Smooth curve with dot markers and a faint green fill below the line. |
| **Module Breakdown card** | Three rows — AAC Board (🗣️ blue), Vocab Learning (📚 green), Speech Practice (🎤 rose). Each row shows total session count, a coloured progress bar, and the accuracy percentage. |
| **Right column (flex 2) — Session History card** | Scrollable list of up to 30 recent sessions. Each row shows: date/time, module emoji + name, duration, accuracy chip. |
| **Empty state** | When there are no sessions at all: 📊 + "No sessions yet" + "Sessions will appear here once the child starts using the app." |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap "← Dashboard" | → Screen 7 (Admin Dashboard) |
| Admin sidebar links | → Any admin screen |

---

## Screen 7 — Parent / Teacher Control Panel

This screen is split into two distinct views that share the same admin sidebar. They're accessed from different points in the app but always feel like part of the same workspace.

---

### Screen 7a — Admin Dashboard

> The command centre. A bird's-eye view of all linked children, a quick performance chart, and the launch buttons to jump into a child's session.

| Aspect | Detail |
|---|---|
| **Purpose** | Central admin hub — shows an overview of all children and their recent performance, and lets an admin launch a child session or navigate to child-specific tools. |
| **Layout** | Admin sidebar (left, persistent) + scrollable content area (right). Warm parchment background. |
| **Top bar** | Admin's display name + role ("Parent" / "Teacher") on the left. "+ Add Child" secondary button on the right. |
| **Stat cards row** | Three equal-width cards: 👨‍👩‍👧‍👦 Children linked, 📊 Avg accuracy (across all sessions), 📝 Words today. Values update live from Firestore. |
| **Weekly accuracy bar chart** | Seven side-by-side green bars (one per day). Grey for days with no data. No interaction — just a quick visual pulse-check. |
| **Children list** | One card per linked child, staggered fade-in. Each card shows: coloured gradient avatar circle with emoji, child's name + star count, three mini progress bars (AAC / Vocab / Speech), and three shortcut buttons. |
| **▶ Launch button** | Green primary button. Sets the child as active in the provider, then navigates to the child home screen — effectively handing the tablet to the child. Swaps to a spinner during the async set-active call. |
| **Shortcut buttons** | Three small outlined chips per child: Progress (→ Screen 6), Vocab (→ Screen 7b Vocab Manager), Recordings (→ Recording Review). |
| **Empty state** | If no children are linked yet: 😊 + "No children yet" + "Tap 'Add Child' to create the first profile." |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap "+ Add Child" | → Add Child screen (`/admin/add-child`) |
| Tap "▶ Launch" on a child | → Screen 2 (Child Home), with that child set as active |
| Tap "Progress" shortcut | → Screen 6 (Progress Dashboard) for that child |
| Tap "Vocab" shortcut | → Screen 7b (Vocab Manager) for that child |
| Tap "Recordings" shortcut | → Recording Review screen for that child |
| Admin sidebar links | → Any admin screen |

---

### Screen 7b — Vocab Manager

> Where parents and teachers build the word bank. Add words, upload pictures, set the emoji, choose a category, and control how hard the quiz will be for each child.

| Aspect | Detail |
|---|---|
| **Purpose** | Full CRUD management of vocabulary items for a specific child, plus the Q&A difficulty toggle. |
| **Layout** | Admin sidebar + main area split into a left items panel and a right form panel (360 px fixed). Warm parchment background. |
| **Header bar** | "Vocab Manager" heading + "← Dashboard" back link. |
| **Q&A mode bar** | Sits below the header. Two chips: "2 choices (easier)" and "4 choices (harder)". The active one is green. Tapping a chip immediately writes the change to Firestore for that child — it affects how the Vocab Learning screen presents questions for this specific child. |
| **Category tabs** | Horizontally scrollable row of filter chips (All + one per category). Selecting a category filters the item list. "Add Item" green pill button on the far right always visible. |
| **Item list** | Scrollable list. Each tile shows: a 48 × 48 thumbnail (photo or emoji fallback), word + category label, an optional 🎧 audio indicator, and a delete 🗑️ icon. Tap the tile to open it in the form panel for editing. |
| **Delete confirmation** | AlertDialog: "Delete '[word]'? This will remove the word from all vocab activities." Cancel / Delete options. |
| **Right form panel — idle state** | When nothing is selected: "Select an item to edit / or tap 'Add Item' above" with a note icon. |
| **Right form panel — active** | Header row "New item" or "Edit item" + close button. Fields: Word, Emoji, Category (with existing-category quick-tap chips below the field), Image (optional, 80 × 80 upload area). "🔊 Preview word" secondary button for TTS test before saving. Save / Add Word primary button. Error banner for validation failures. Image upload shows a spinner while uploading to Firebase Storage. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap "← Dashboard" | → Screen 7a (Admin Dashboard) |
| Admin sidebar links | → Any admin screen |

---

## Reward Screen

> The celebration that follows every completed activity. It's unapologetically joyful — confetti, a bouncing trophy, stars popping in one by one. This is the moment the child feels seen for the work they just did.

| Aspect | Detail |
|---|---|
| **Purpose** | Awards 5 stars for the completed session, unlocks any newly earned badges, and sends the child back to the home screen feeling good. All Firestore writes happen once on load — the build method is purely display. |
| **Background** | Full-screen diagonal gradient, amber-light → green-light. Warm and celebratory without being loud. |
| **Confetti** | Explosive burst of multi-coloured confetti particles fires from the top-centre of the screen 350 ms after the screen loads. Runs for 5 seconds. Colours cycle through the app palette — amber, green, sky, rose. |
| **🏆 Trophy** | 88 px trophy emoji that scales in from zero with an elastic spring on entry, then gently floats up and down on a continuous 1.6-second loop (±10 px vertical travel). |
| **"Great job! 🎉" heading** | Display-size text, fades in and slides up 200 ms after load. |
| **Subtitle** | "You're a star learner today" in body text, fades in at 350 ms. |
| **Five ⭐ stars** | A row of five stars that each scale in individually with an elastic spring, staggered 110 ms apart starting at 500 ms. They pop in left to right. |
| **Total star counter** | An amber pill chip ("⭐ [N] total stars") fades in and slides up at 1050 ms — after the stars have all arrived, so it feels like a tally. Shows the live total from Firestore (including the just-awarded stars). |
| **Badges section** | Only shown when the child has earned at least one badge. "Badges earned" title + a centred Wrap of badge chips. Each chip shows the badge emoji and name. Chips scale in with elastic springs, staggered 80 ms apart starting at 1200 ms. |

**Badge milestones**

| Stars needed | Badge ID | Emoji | Name |
|---|---|---|---|
| 10 | badge_10 | 🌟 | Star Collector |
| 25 | badge_25 | 🏅 | Champion |
| 50 | badge_50 | 🦁 | Brave Explorer |
| 100 | badge_100 | 🎯 | Word Master |
| 200 | badge_200 | 🚀 | Super Learner |
| 500 | badge_500 | 👑 | Legend |

| Aspect | Detail |
|---|---|
| **Badge logic** | On load, the screen reads the child's current star total and badge list from the provider, then writes `+5` stars to Firestore via `FieldValue.increment`. It then checks which milestones the new total clears that weren't already in the badge list, and writes only the new badges via `FieldValue.arrayUnion`. No badge is awarded twice. |
| **"Keep it up! →" button** | 260 px wide green primary button. Fades in and slides up at 900 ms. Returns the child to their home screen. |

**Navigation from this screen**

| Trigger | Destination |
|---|---|
| Tap "Keep it up! →" | → Screen 2 (Child Home) |
| No active child (edge case) | → Screen 0 (Profile Picker) |
