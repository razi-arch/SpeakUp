# Sequence Diagram Reference — SpeakUp! AAC Learning App

Each diagram lists the participating actors and objects at the top, followed by a numbered message flow using the format **From → To: Message**. Alternative flows follow directly after the main flow. Use this document as the source of truth to draw each sequence diagram in Canva.

---

## SD-01 — User Login (Parent / Teacher)

### Participants

| Label | Type |
|-------|------|
| User | Actor (Teacher or Parent) |
| Login Screen | Flutter Screen |
| Firebase Auth | External Service |
| Firestore | Database |
| GoRouter | Navigation |

### Main Flow

1. User → Login Screen: Opens app; taps "Admin Login" link
2. Login Screen → User: Displays email field, password field, Sign In button
3. User → Login Screen: Enters email address
4. User → Login Screen: Enters password
5. User → Login Screen: Taps "Sign In" button
6. Login Screen → Firebase Auth: signInWithEmailAndPassword(email, password)
7. Firebase Auth → Login Screen: Returns UserCredential with uid
8. Login Screen → Firestore: Reads document users/{uid}
9. Firestore → Login Screen: Returns user document with role and emailVerified fields
10. Login Screen: Checks emailVerified == true
11. Login Screen → GoRouter: Navigate to /admin/dashboard
12. GoRouter → Dashboard Screen: Loads admin dashboard
13. Dashboard Screen → User: Displays child cards, sidebar navigation, and statistics

### Alternative Flow A — Wrong Password

6a. Firebase Auth → Login Screen: Throws wrong-password error
7a. Login Screen → User: Shows inline error "Incorrect email or password"
8a. User → Login Screen: Corrects password; retries from step 5

### Alternative Flow B — Email Not Yet Verified

10b. Login Screen: Detects emailVerified == false
11b. Login Screen → User: Shows error "Please verify your email address before logging in"
12b. User → Email Client: Opens inbox; clicks the verification link
13b. Email Client → Firebase Auth: Marks email as verified
14b. User → Login Screen: Retries login from step 3

### Alternative Flow C — Account Not Found

6c. Firebase Auth → Login Screen: Throws user-not-found error
7c. Login Screen → User: Shows error "No account found with this email"

---

## SD-02 — User Self-Registration — Teacher Flow (4 Steps)

### Participants

| Label | Type |
|-------|------|
| Teacher | Actor |
| Register Screen | Flutter Screen |
| Firebase Auth | External Service |
| Firestore | Database |
| Email Client | External (device mail app) |

### Main Flow

**Step 1 — Role Selection**

1. Teacher → Register Screen: Taps "Register" link on the login screen
2. Register Screen → Teacher: Displays two role cards: "Teacher" and "Parent"
3. Teacher → Register Screen: Taps the "Teacher" card
4. Register Screen: Records selected role = "teacher"; advances to Step 2

**Step 2 — Personal Information**

5. Register Screen → Teacher: Displays form fields: Full Name, IC/ID Number, Email, Phone Number, Address
6. Teacher → Register Screen: Enters full name (required; any non-empty string)
7. Teacher → Register Screen: Enters IC number (must be exactly 12 digits; screen auto-inserts dashes at positions 6 and 8, producing format 000000-00-0000)
8. Teacher → Register Screen: Enters email (validated against regex: letters, digits, dots, plus, hyphen followed by @ then domain and TLD of at least 2 chars)
9. Teacher → Register Screen: Enters phone number (Malaysian format: begins with +60 or 0, followed by a non-zero digit, then 7–9 more digits)
10. Teacher → Register Screen: Enters address (required; any non-empty string)
11. Teacher → Register Screen: Taps "Next"
12. Register Screen: Validates all five fields against their rules
13. Register Screen: All fields valid → advances to Step 3

**Step 3 — Professional Information (Teacher Only)**

14. Register Screen → Teacher: Displays form: School or Centre Name, Highest Qualification, Specialisation, Years of Experience
15. Teacher → Register Screen: Enters school or centre name (required)
16. Teacher → Register Screen: Enters highest qualification (required; e.g., "Bachelor of Education")
17. Teacher → Register Screen: Enters specialisation (required; e.g., "Special Education")
18. Teacher → Register Screen: Enters years of experience (required; numeric)
19. Teacher → Register Screen: Taps "Next"
20. Register Screen: Validates all four fields are non-empty
21. Register Screen: Valid → advances to Step 4

**Step 4 — Password Setup**

22. Register Screen → Teacher: Displays password field, confirm password field, and password strength indicator bar
23. Teacher → Register Screen: Types password character by character
24. Register Screen → Teacher: Updates strength bar in real time (Weak / Fair / Good / Strong based on length, uppercase, and digit presence)
25. Teacher → Register Screen: Finishes typing password (must have minimum 8 characters, at least 1 uppercase letter, at least 1 digit)
26. Teacher → Register Screen: Enters the same password in the confirm field
27. Teacher → Register Screen: Taps "Create Account"
28. Register Screen: Validates password meets all strength rules
29. Register Screen: Validates password == confirmPassword
30. Register Screen → Firebase Auth: createUserWithEmailAndPassword(email, password)
31. Firebase Auth → Register Screen: Returns UserCredential with new uid
32. Register Screen → Firestore: Creates document users/{uid} with fields: role="teacher", fullName, icNumber, phone, address, schoolName, qualification, specialisation, yearsExp, emailVerified=false, createdAt=serverTimestamp
33. Firestore → Register Screen: Confirms document written
34. Register Screen → Firebase Auth: Calls sendEmailVerification()
35. Firebase Auth → Teacher Email Inbox: Sends verification email with confirmation link
36. Register Screen → Firebase Auth: Calls signOut() (immediately signs user out)
37. Register Screen → Teacher: Displays success screen: "Registration successful! Check your email to verify your account before logging in."

### Alternative Flow A — Validation Error on Personal Info (Step 2)

12a. Register Screen: Detects IC number is not 12 digits or phone format is invalid
13a. Register Screen → Teacher: Highlights invalid field in red; displays specific error below the field (e.g., "Enter a valid Malaysian IC number (e.g. 990101-01-1234)")
14a. Teacher → Register Screen: Corrects the field; retries from step 11

### Alternative Flow B — Email Already Registered (Step 4)

30b. Firebase Auth → Register Screen: Throws email-already-in-use error
31b. Register Screen → Teacher: Shows error "An account with this email already exists. Try logging in instead."
32b. Teacher: Navigates back to Step 2 and enters a different email

### Alternative Flow C — Password Mismatch (Step 4)

29c. Register Screen: Detects password != confirmPassword
30c. Register Screen → Teacher: Shows inline error below confirm field: "Passwords do not match"
31c. Teacher → Register Screen: Re-enters matching confirm password; retries step 27

### Alternative Flow D — Password Too Weak (Step 4)

28d. Register Screen: Detects password does not contain 1 uppercase + 1 digit or is fewer than 8 characters
29d. Register Screen → Teacher: Shows error "Password must be at least 8 characters and include one uppercase letter and one number"
30d. Teacher → Register Screen: Adjusts password; retries from step 23

---

## SD-03 — User Self-Registration — Parent Flow (3 Steps)

### Participants

| Label | Type |
|-------|------|
| Parent | Actor |
| Register Screen | Flutter Screen |
| Firebase Auth | External Service |
| Firestore | Database |
| Email Client | External (device mail app) |

### Main Flow

**Step 1 — Role Selection**

1. Parent → Register Screen: Taps "Register" link on the login screen
2. Register Screen → Parent: Displays Teacher and Parent role cards
3. Parent → Register Screen: Taps the "Parent" card
4. Register Screen: Records role = "parent"; advances to Step 2

**Step 2 — Personal Information**

5. Register Screen → Parent: Displays form: Full Name, IC/ID Number, Email, Phone Number, Address (same fields as Teacher Step 2; no professional fields follow)
6. Parent → Register Screen: Enters full name (required)
7. Parent → Register Screen: Enters IC number (12 digits; auto-formatted as 000000-00-0000)
8. Parent → Register Screen: Enters email (validated by same regex)
9. Parent → Register Screen: Enters phone number (Malaysian format)
10. Parent → Register Screen: Enters address (required)
11. Parent → Register Screen: Taps "Next"
12. Register Screen: Validates all fields; all valid → advances to Step 3 (no Professional Info step for parent)

**Step 3 — Password Setup**

13. Register Screen → Parent: Displays password field, confirm field, strength indicator
14. Parent → Register Screen: Enters password (min 8 chars, 1 uppercase, 1 digit)
15. Register Screen → Parent: Updates strength indicator in real time
16. Parent → Register Screen: Enters matching confirm password
17. Parent → Register Screen: Taps "Create Account"
18. Register Screen: Validates strength rules and password match
19. Register Screen → Firebase Auth: createUserWithEmailAndPassword(email, password)
20. Firebase Auth → Register Screen: Returns UserCredential (uid)
21. Register Screen → Firestore: Creates document users/{uid} with role="parent", fullName, icNumber, phone, address, emailVerified=false, createdAt (no school or professional fields written)
22. Firestore → Register Screen: Confirms write
23. Register Screen → Firebase Auth: sendEmailVerification()
24. Firebase Auth → Parent Email Inbox: Sends verification email
25. Register Screen → Firebase Auth: signOut()
26. Register Screen → Parent: Displays success screen with email verification instructions

### Alternative Flows

Same as SD-02 Alternative Flows A, B, C, D (Professional Info step does not exist for parents so Alternative Flow A applies only to Step 2 personal fields).

---

## SD-04 — Child Selects Profile (Profile Picker)

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Profile Picker Screen | Flutter Screen |
| Riverpod Child Provider | State Layer |
| Riverpod Reward Provider | State Layer |
| Firestore | Database |
| GoRouter | Navigation |

### Main Flow

1. App launches → GoRouter: Checks authState — not authenticated → routes to /
2. GoRouter → Profile Picker Screen: Loads screen
3. Profile Picker Screen → Riverpod Child Provider: Subscribes to linkedChildrenProvider for device or current session
4. Riverpod Child Provider → Firestore: Queries children where linkedUsers array contains currentUid
5. Firestore → Riverpod Child Provider: Returns list of ChildModel objects
6. Riverpod Child Provider → Profile Picker Screen: Emits children list
7. Profile Picker Screen → Riverpod Reward Provider: Requests rewardProvider(childId) for each child
8. Riverpod Reward Provider → Firestore: Reads rewards/{childId} for each child
9. Firestore → Riverpod Reward Provider: Returns totalStars per child
10. Riverpod Reward Provider → Profile Picker Screen: Emits star count per child
11. Profile Picker Screen → Child: Displays child cards, each showing avatar emoji, name, gradient background, and star count
12. Child → Profile Picker Screen: Taps a child card (e.g., "Sarah")
13. Profile Picker Screen → GoRouter: Navigates to /confirm/{childId}

### Alternative Flow A — Device Has an Active Child (Auto-Countdown)

6a. Riverpod Child Provider: Identifies a child with isActiveOnDevice == true
7a. Profile Picker Screen: Starts 5-second countdown timer on that child's card
8a. Profile Picker Screen → Child: Displays "Starting in 5… 4… 3… 2… 1…" countdown on the card
9a. Countdown reaches 0 → Profile Picker Screen → GoRouter: Auto-navigates to /confirm/{activeChildId}

### Alternative Flow B — No Children Linked

5b. Firestore → Riverpod Child Provider: Returns empty list
6b. Profile Picker Screen → Child/Admin: Shows empty state message "No profiles yet — ask your teacher or parent to link a profile" with an "Admin Login" button

---

## SD-05 — Child Confirms Profile and Enters Home

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Confirm Profile Screen | Flutter Screen |
| Riverpod Child Provider | State Layer |
| Riverpod Active Child Provider | State Layer |
| Firestore | Database |
| GoRouter | Navigation |
| Child Home Screen | Flutter Screen |

### Main Flow

1. GoRouter → Confirm Profile Screen: Loads screen with childId parameter from route
2. Confirm Profile Screen → Riverpod Child Provider: Fetches ChildModel for childId
3. Riverpod Child Provider → Firestore: Reads children/{childId}
4. Firestore → Riverpod Child Provider: Returns ChildModel (name, avatarEmoji, difficulty, etc.)
5. Riverpod Child Provider → Confirm Profile Screen: Emits ChildModel
6. Confirm Profile Screen → Child: Displays avatar emoji, gradient background, child name, and "Yes, that's me!" button
7. Child → Confirm Profile Screen: Taps "Yes, that's me!"
8. Confirm Profile Screen → Riverpod Active Child Provider: Sets activeChildProvider state = selected ChildModel (in-memory; no Firestore write)
9. Confirm Profile Screen → GoRouter: Navigates to /child/home
10. GoRouter: Checks guard — activeChildProvider is non-null → allows navigation
11. GoRouter → Child Home Screen: Loads screen
12. Child Home Screen → Child: Displays module buttons (AAC Board, Vocabulary Learning, Speech Practice), avatar, name, and star count

### Alternative Flow A — Wrong Child

7a. Child → Confirm Profile Screen: Taps back arrow or "Not me" option
8a. GoRouter → Profile Picker Screen: Returns to / with all child cards

---

## SD-06 — Child Uses AAC Board — Browse Categories and Select Symbols

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Child Home Screen | Flutter Screen |
| AAC Board Screen | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Firestore | Database |
| GoRouter | Navigation |

### Main Flow

1. Child → Child Home Screen: Taps "AAC Board" module button
2. Child Home Screen → GoRouter: Navigates to /child/aac
3. GoRouter → AAC Board Screen: Loads screen
4. AAC Board Screen → Riverpod Vocab Provider: Subscribes to categoriesProvider(activeChildId)
5. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items; extracts distinct category values
6. Firestore → Riverpod Vocab Provider: Returns list of category strings (e.g., Animals, Food, Actions, Feelings)
7. Riverpod Vocab Provider → AAC Board Screen: Emits category list
8. AAC Board Screen: Auto-selects the first category (e.g., "Animals")
9. AAC Board Screen → Riverpod Vocab Provider: Subscribes to vocabItemsProvider(childId, category="Animals")
10. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items where category == "Animals"
11. Firestore → Riverpod Vocab Provider: Returns list of VocabItem for Animals
12. Riverpod Vocab Provider → AAC Board Screen: Emits VocabItem list
13. AAC Board Screen → Child: Displays category sidebar on the left, symbol grid in the centre (130 px cards with emoji and word label), and an empty sentence bar at the top

**Switching Category:**

14. Child → AAC Board Screen: Taps "Food" in the category sidebar
15. AAC Board Screen → Riverpod Vocab Provider: Updates selectedCategoryProvider to "Food"
16. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items where category == "Food"
17. Firestore → Riverpod Vocab Provider: Returns Food items
18. Riverpod Vocab Provider → AAC Board Screen: Emits updated items
19. AAC Board Screen → Child: Refreshes symbol grid with Food items; sentence bar unchanged

---

## SD-07 — Child Uses AAC Board — Build Sentence, Speak, Delete, Clear

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| AAC Board Screen | Flutter Screen |
| Flutter TTS | Text-to-Speech Engine |
| Session Service | Service Layer |
| Firestore | Database |

### Main Flow

**Building the Sentence:**

1. Child → AAC Board Screen: Taps symbol card "Cat" (Animals category)
2. AAC Board Screen: Appends "Cat" to internal sentence list
3. AAC Board Screen → Child: Updates sentence bar to show pill [Cat ×]
4. Child → AAC Board Screen: Taps symbol card "Eat" (Actions category)
5. AAC Board Screen: Appends "Eat" to sentence list
6. AAC Board Screen → Child: Sentence bar shows [Cat ×] [Eat ×]
7. Child → AAC Board Screen: Taps symbol card "Fish" (Food category)
8. AAC Board Screen: Appends "Fish"
9. AAC Board Screen → Child: Sentence bar shows [Cat ×] [Eat ×] [Fish ×]

**Playing via TTS:**

10. Child → AAC Board Screen: Taps the "Speak" button
11. AAC Board Screen: Joins sentence list into string "Cat Eat Fish"
12. AAC Board Screen → Flutter TTS: speak("Cat Eat Fish")
13. Flutter TTS → Device Speaker: Outputs audio "Cat Eat Fish"
14. Flutter TTS → AAC Board Screen: Notifies completion
15. AAC Board Screen → Session Service: logSession(childId, module="aac", accuracy=1.0, wordsAttempted=3, durationSeconds=elapsed)
16. Session Service → Firestore: Writes sessions/{childId}/sessions/{newId} with all session fields
17. Firestore → Session Service: Confirms write

**Deleting Last Word:**

18. Child → AAC Board Screen: Taps the backspace button (or taps the × on the last pill)
19. AAC Board Screen: Removes last element "Fish" from sentence list
20. AAC Board Screen → Child: Sentence bar now shows [Cat ×] [Eat ×]

**Clearing All Words:**

21. Child → AAC Board Screen: Taps "Clear All" button
22. AAC Board Screen: Empties the sentence list
23. AAC Board Screen → Child: Sentence bar is empty; ready for new input

### Alternative Flow A — Speak with Empty Sentence Bar

10a. Child → AAC Board Screen: Taps "Speak" with no words in the sentence bar
11a. AAC Board Screen: Detects empty list; Speak button either disabled or shows brief hint
12a. AAC Board Screen → Child: No TTS triggered; no session logged

---

## SD-08 — Child Completes Vocabulary Learning Cards Activity

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Child Home Screen | Flutter Screen |
| Vocab Learning Screen | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Session Service | Service Layer |
| Firestore | Database |
| Flutter TTS | Text-to-Speech Engine |
| GoRouter | Navigation |
| Reward Screen | Flutter Screen |

### Main Flow

1. Child → Child Home Screen: Taps "Vocabulary Learning" module button
2. Child Home Screen → GoRouter: Navigates to /child/vocab
3. GoRouter → Vocab Learning Screen: Loads screen; records startTime
4. Vocab Learning Screen → Riverpod Vocab Provider: Subscribes to categoriesProvider(activeChildId)
5. Riverpod Vocab Provider → Firestore: Queries distinct categories for child
6. Firestore → Riverpod Vocab Provider: Returns category list
7. Vocab Learning Screen: Auto-selects first category
8. Vocab Learning Screen → Riverpod Vocab Provider: Subscribes to vocabItemsProvider(childId, firstCategory)
9. Riverpod Vocab Provider → Firestore: Queries items for selected category
10. Firestore → Riverpod Vocab Provider: Returns VocabItem list
11. Vocab Learning Screen: Shuffles items; sets currentItem; builds choice buttons (2 or 4 based on child.qaMode); initialises correctCount=0, totalAttempts=0
12. Vocab Learning Screen → Child: Displays category chips bar at top, vocab card (emoji/image + word label) in centre, and answer-choice buttons below

**Per-Card Loop (repeats until correctCount == 5):**

13. Child → Vocab Learning Screen: Taps speak icon on the card (optional step)
14. Vocab Learning Screen → Flutter TTS: speak(currentWord)
15. Flutter TTS → Device Speaker: Outputs word pronunciation

**Correct Answer:**

16. Child → Vocab Learning Screen: Taps the correct answer button
17. Vocab Learning Screen: Detects answer is correct
18. Vocab Learning Screen → Child: Highlights button green; shows toast "Correct! 🎉"
19. Vocab Learning Screen: correctCount++; totalAttempts++
20. Vocab Learning Screen: Waits 1.2 seconds
21. Vocab Learning Screen: Checks correctCount — if less than 5, loads next item
22. Vocab Learning Screen → Child: Displays next vocab card with new choices

**After 5th Correct Answer:**

23. Vocab Learning Screen: correctCount == 5 → session complete
24. Vocab Learning Screen: Computes accuracy = 5.0 / totalAttempts; computes durationSeconds = now − startTime
25. Vocab Learning Screen → Session Service: logSession(childId, module="vocab", accuracy, wordsAttempted=5, durationSeconds)
26. Session Service → Firestore: Writes sessions/{childId}/sessions/{id}
27. Firestore → Session Service: Confirms write
28. Vocab Learning Screen → GoRouter: Navigates to /child/reward
29. GoRouter → Reward Screen: Loads reward screen (triggers SD-17 Earn Stars and SD-18 Badge Check)

### Alternative Flow A — Wrong Answer

16a. Child → Vocab Learning Screen: Taps an incorrect answer button
17a. Vocab Learning Screen: Detects answer is wrong
18a. Vocab Learning Screen → Child: Highlights button red; shows toast "Try again!"
19a. Vocab Learning Screen: totalAttempts++ (correctCount unchanged)
20a. Vocab Learning Screen: Waits 1.2 seconds; deselects all buttons; remains on the same item
21a. Returns to step 16 for the same card

### Alternative Flow B — Change Category Mid-Session

12b. Child → Vocab Learning Screen: Taps a different category chip
13b. Vocab Learning Screen → Riverpod Vocab Provider: Updates selectedCategoryProvider
14b. Riverpod Vocab Provider → Firestore: Re-queries items for new category
15b. Firestore → Riverpod Vocab Provider: Returns new items
16b. Vocab Learning Screen: Resets correctCount=0, totalAttempts=0, startTime=now; reloads with new items
17b. Returns to step 11

---

## SD-09 — Child Completes Guided Question Activity

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Child Home Screen | Flutter Screen |
| Vocab Learning Screen (qaMode = 4) | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Session Service | Service Layer |
| Firestore | Database |
| Flutter TTS | Text-to-Speech Engine |
| GoRouter | Navigation |
| Reward Screen | Flutter Screen |

### Main Flow

1. Child → Child Home Screen: Taps "Guided Questions" module button
2. Child Home Screen → GoRouter: Navigates to /child/vocab (child profile has qaMode=4)
3. GoRouter → Vocab Learning Screen: Loads with 4-choice mode; records startTime
4. Vocab Learning Screen → Riverpod Vocab Provider: Fetches vocab items for active child
5. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items
6. Firestore → Riverpod Vocab Provider: Returns full item list
7. Vocab Learning Screen: Selects current question item; picks 3 distractor words from remaining items; builds 4-button layout; initialises correctCount=0, totalAttempts=0
8. Vocab Learning Screen → Child: Displays vocab card showing the target image and word; below it shows 4 labelled answer buttons

**Correct Answer Flow:**

9. Child → Vocab Learning Screen: Taps the button that matches the target item
10. Vocab Learning Screen: Detects the selected answer is correct
11. Vocab Learning Screen → Child: Highlights button green; shows "Correct! 🎉" toast
12. Vocab Learning Screen: correctCount++; totalAttempts++
13. Vocab Learning Screen: Waits 1.2 seconds; checks if correctCount < 5
14. Vocab Learning Screen: Loads next question item with 4 new choices
15. Vocab Learning Screen → Child: Displays next guided question card

**After 5 Correct Answers:**

16. Vocab Learning Screen: correctCount == 5 → session complete
17. Vocab Learning Screen: Computes accuracy = 5.0 / totalAttempts; durationSeconds = now − startTime
18. Vocab Learning Screen → Session Service: logSession(module="vocab", accuracy, wordsAttempted=5, durationSeconds)
19. Session Service → Firestore: Writes session document
20. Firestore → Session Service: Confirms
21. Vocab Learning Screen → GoRouter: Navigates to /child/reward
22. GoRouter → Reward Screen: Loads reward screen

### Alternative Flow A — Wrong Answer

9a. Child → Vocab Learning Screen: Taps one of the three distractor buttons
10a. Vocab Learning Screen: Detects answer is wrong
11a. Vocab Learning Screen → Child: Highlights button red; shows "Try again!" toast
12a. Vocab Learning Screen: totalAttempts++ (correctCount unchanged)
13a. Vocab Learning Screen: Waits 1.2 seconds; resets button highlights; remains on same question
14a. Returns to step 9

---

## SD-10 — Child Completes Fill-in-the-Blank Exercise

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Child Home Screen | Flutter Screen |
| Vocab Learning Screen (qaMode = 2) | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Session Service | Service Layer |
| Firestore | Database |
| Flutter TTS | Text-to-Speech Engine |
| GoRouter | Navigation |
| Reward Screen | Flutter Screen |

### Main Flow

1. Child → Child Home Screen: Taps "Fill-in-the-Blank" activity button
2. Child Home Screen → GoRouter: Navigates to /child/vocab (child profile has qaMode=2)
3. GoRouter → Vocab Learning Screen: Loads with 2-choice mode; records startTime
4. Vocab Learning Screen → Riverpod Vocab Provider: Fetches vocab items for active child
5. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items
6. Firestore → Riverpod Vocab Provider: Returns item list
7. Vocab Learning Screen: Selects current item; picks 1 distractor; builds 2-button layout (correct + distractor); initialises correctCount=0, totalAttempts=0
8. Vocab Learning Screen → Child: Displays fill-in-the-blank prompt (e.g., sentence with a gap or image cue) and 2 answer buttons

**Correct Answer Flow:**

9. Child → Vocab Learning Screen: Taps the correct word button
10. Vocab Learning Screen: Detects correct answer
11. Vocab Learning Screen → Child: Highlights button green; shows "Correct! 🎉" toast
12. Vocab Learning Screen: correctCount++; totalAttempts++
13. Vocab Learning Screen: Waits 1.2 seconds; loads next item with 2 new choices
14. Vocab Learning Screen → Child: Displays next fill-in-the-blank prompt

**After 5 Correct Answers:**

15. Vocab Learning Screen: correctCount == 5 → complete
16. Vocab Learning Screen: Computes accuracy and duration
17. Vocab Learning Screen → Session Service: logSession(module="vocab", accuracy, wordsAttempted=5, durationSeconds)
18. Session Service → Firestore: Writes session document
19. Firestore → Session Service: Confirms
20. Vocab Learning Screen → GoRouter: Navigates to /child/reward
21. GoRouter → Reward Screen: Loads reward screen

### Alternative Flow A — Wrong Answer

9a. Child → Vocab Learning Screen: Taps the distractor button
10a. Vocab Learning Screen: Detects wrong answer
11a. Vocab Learning Screen → Child: Highlights button red; shows "Try again!" toast
12a. Vocab Learning Screen: totalAttempts++; correctCount unchanged
13a. Vocab Learning Screen: Waits 1.2 seconds; resets buttons; remains on same prompt
14a. Returns to step 9

---

## SD-11 — Child Listens to Word Pronunciation in Speech Practice

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Child Home Screen | Flutter Screen |
| Speech Practice Screen | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Firestore | Database |
| Flutter TTS | Text-to-Speech Engine |
| GoRouter | Navigation |

### Main Flow

1. Child → Child Home Screen: Taps "Speech Practice" module button
2. Child Home Screen → GoRouter: Navigates to /child/speech
3. GoRouter → Speech Practice Screen: Loads screen
4. Speech Practice Screen → Riverpod Vocab Provider: Subscribes to allVocabItemsProvider(activeChildId)
5. Riverpod Vocab Provider → Firestore: Queries all vocab/{childId}/items (no category filter)
6. Firestore → Riverpod Vocab Provider: Returns full VocabItem list
7. Riverpod Vocab Provider → Speech Practice Screen: Emits items list
8. Speech Practice Screen: Sets wordIndex=0; loads first item (e.g., "Cat")
9. Speech Practice Screen → Child: Displays word card with emoji/image, word label, and action buttons: Listen, Record, Play Back, Next Word

10. Child → Speech Practice Screen: Taps "Listen" button
11. Speech Practice Screen → Flutter TTS: speak("Cat")
12. Flutter TTS → Device Speaker: Outputs audio "Cat"
13. Flutter TTS → Speech Practice Screen: Notifies completion
14. Speech Practice Screen → Child: Listen button returns to ready state

### Alternative Flow A — Child Taps Listen Again

14a. Child → Speech Practice Screen: Taps "Listen" a second time while TTS is still playing
15a. Speech Practice Screen → Flutter TTS: Stops current playback; calls speak("Cat") again
16a. Flutter TTS → Device Speaker: Restarts pronunciation from beginning

---

## SD-12 — Child Records Voice in Speech Practice

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Speech Practice Screen | Flutter Screen |
| OS Permission Dialog | Device OS |
| Audio Recorder | Record Package |
| Firebase Storage | Cloud Storage |
| Firestore | Database |

### Main Flow

**Requesting Microphone Permission (first-time only):**

1. Child → Speech Practice Screen: Taps "Record" button
2. Speech Practice Screen → Audio Recorder: Calls hasPermission()
3. Audio Recorder → OS Permission Dialog: Triggers "Allow microphone access?" prompt
4. Child → OS Permission Dialog: Taps "Allow"
5. OS Permission Dialog → Audio Recorder: Returns permission = granted
6. Audio Recorder → Speech Practice Screen: Returns hasPermission = true

**Recording:**

7. Speech Practice Screen → Audio Recorder: Calls start(path='speech_{timestamp}.aac', encoder=aacLc)
8. Audio Recorder → Device Microphone: Begins audio capture
9. Speech Practice Screen → Child: Displays "Recording…" indicator; shows Stop button; hides Record button
10. Child → Speech Practice Screen: Taps "Stop" button
11. Speech Practice Screen → Audio Recorder: Calls stop()
12. Audio Recorder → Device Microphone: Ends capture
13. Audio Recorder → Speech Practice Screen: Returns localFilePath of saved temp file

**Background Upload:**

14. Speech Practice Screen → Firebase Storage: Calls uploadFile(localFilePath, destinationPath='recordings/{childId}/{word}_{timestamp}.aac')
15. Firebase Storage → Speech Practice Screen: Returns downloadUrl (gs://... storage URL)
16. Speech Practice Screen → Firestore: Creates document recordings/{childId}/recordings/{newId} with fields: childId, storageUrl=downloadUrl, word=currentWord, timestamp=now, adminScore=null, adminComment=null
17. Firestore → Speech Practice Screen: Confirms write

**Post-recording UI:**

18. Speech Practice Screen → Child: Enables "Play Back" button; shows recording saved indicator

### Alternative Flow A — Microphone Permission Denied

4a. Child → OS Permission Dialog: Taps "Deny"
5a. OS Permission Dialog → Audio Recorder: Returns permission = denied
6a. Audio Recorder → Speech Practice Screen: Returns hasPermission = false
7a. Speech Practice Screen → Child: Shows error message "Microphone permission is required to record your voice"
8a. Recording does not start; child remains on the current word

### Alternative Flow B — Upload Fails (Network Error)

14b. Firebase Storage → Speech Practice Screen: Returns upload error
15b. Speech Practice Screen: Catches error silently; does not write Firestore metadata
16b. Speech Practice Screen → Child: No visible error shown (child experience is uninterrupted); Play Back still uses local temp file

---

## SD-13 — Child Plays Back Saved Recording

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Speech Practice Screen | Flutter Screen |
| Audio Player | Device Audio Engine |
| Firebase Storage | Cloud Storage |

### Main Flow

1. Child → Speech Practice Screen: Taps "Play Back" button (enabled after a recording was saved)
2. Speech Practice Screen: Retrieves localFilePath of the most recent recording for this word
3. Speech Practice Screen → Audio Player: play(localFilePath)
4. Audio Player → Device Speaker: Streams and outputs the recorded audio
5. Audio Player → Speech Practice Screen: Notifies playback complete
6. Speech Practice Screen → Child: Play Back button returns to idle state; child may record again or advance

### Alternative Flow A — Local Temp File No Longer Available

2a. Speech Practice Screen: Checks localFilePath — file has been cleared from temp storage
3a. Speech Practice Screen: Falls back to storageUrl saved in memory
4a. Speech Practice Screen → Firebase Storage: Requests download stream from storageUrl
5a. Firebase Storage → Speech Practice Screen: Returns audio stream
6a. Continue from step 3 using the stream

---

## SD-14 — Child Advances Through Words and Finishes Speech Practice

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Speech Practice Screen | Flutter Screen |
| Session Service | Service Layer |
| Firestore | Database |
| GoRouter | Navigation |
| Reward Screen | Flutter Screen |

### Main Flow

1. Child → Speech Practice Screen: Taps "Next Word" button after recording (or skipping) a word
2. Speech Practice Screen: Increments wordIndex; checks if wordIndex < totalWords
3. Speech Practice Screen: Loads next VocabItem
4. Speech Practice Screen → Child: Displays new word card with Listen, Record, Play Back, Next Word buttons

**On the Last Word:**

5. Child → Speech Practice Screen: Taps "Next Word" on the final item
6. Speech Practice Screen: Detects wordIndex == totalWords − 1 (last item reached)
7. Speech Practice Screen: Computes session data: wordsAttempted = count of words where child tapped Record; accuracy = 1.0; durationSeconds = now − startTime
8. Speech Practice Screen → Session Service: logSession(childId, module="speech", accuracy=1.0, wordsAttempted, durationSeconds)
9. Session Service → Firestore: Writes sessions/{childId}/sessions/{id}
10. Firestore → Session Service: Confirms
11. Speech Practice Screen → GoRouter: Navigates to /child/reward
12. GoRouter → Reward Screen: Loads reward screen (triggers SD-17 Earn Stars)

### Alternative Flow A — Child Exits Early

1a. Child → Speech Practice Screen: Taps the back button or home icon
2a. Speech Practice Screen: Detects early exit; takes a partial session snapshot
3a. Speech Practice Screen → Session Service: logSession(module="speech", wordsAttempted=words recorded so far, accuracy=1.0, duration=elapsed)
4a. Session Service → Firestore: Writes partial session document
5a. Speech Practice Screen → GoRouter: Navigates to /child/home (reward screen is not shown for partial exit)

---

## SD-15 — Parent / Teacher Views Progress Dashboard

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Progress Screen | Flutter Screen |
| Riverpod Session Provider | State Layer |
| Firestore | Database |
| FL Chart Widget | UI Component |
| GoRouter | Navigation |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps a child card or "Progress" in the sidebar
2. Admin Dashboard Screen → GoRouter: Navigates to /admin/progress/{childId}
3. GoRouter → Progress Screen: Loads screen with childId parameter
4. Progress Screen → Riverpod Session Provider: Subscribes to childSessionsProvider(childId) with limit=50
5. Riverpod Session Provider → Firestore: Queries sessions/{childId}/sessions ordered by timestamp DESC, limit 50
6. Firestore → Riverpod Session Provider: Returns list of SessionModel
7. Riverpod Session Provider → Progress Screen: Emits sessions list
8. Progress Screen: Computes statistics: total sessions, average accuracy, average duration, total words attempted
9. Progress Screen → FL Chart Widget: Passes accuracy values and timestamps as data series
10. FL Chart Widget → Progress Screen: Renders accuracy trend line chart
11. Progress Screen → Teacher/Parent: Displays chart at top, statistics summary row, and scrollable session list below

**Filter by Date:**

12. Teacher/Parent → Progress Screen: Taps date filter control and selects start date and end date
13. Progress Screen: Filters the local sessions list — keeps only records where timestamp is within the selected range
14. Progress Screen → FL Chart Widget: Provides filtered data series
15. FL Chart Widget → Progress Screen: Re-renders chart with filtered data
16. Progress Screen → Teacher/Parent: Updates chart and session list to reflect the filter

**Expand Session Detail:**

17. Teacher/Parent → Progress Screen: Taps a session row in the list
18. Progress Screen → Teacher/Parent: Expands the row or opens a detail panel showing: module name, accuracy as a percentage, words attempted count, session duration in minutes and seconds, and full date-time timestamp

### Alternative Flow A — No Sessions Recorded Yet

6a. Firestore → Riverpod Session Provider: Returns empty list
7a. Riverpod Session Provider → Progress Screen: Emits empty list
8a. Progress Screen → Teacher/Parent: Shows empty state illustration with message "No sessions yet — have your child use the app to see progress here"

---

## SD-16 — Parent / Teacher Adds New Vocabulary via Control Panel

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Vocab Manager Screen | Flutter Screen |
| Riverpod Vocab Provider | State Layer |
| Firestore | Database |
| GoRouter | Navigation |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps "Vocab Manager" in the sidebar
2. Admin Dashboard Screen → GoRouter: Navigates to /admin/vocab/{childId}
3. GoRouter → Vocab Manager Screen: Loads screen
4. Vocab Manager Screen → Riverpod Vocab Provider: Subscribes to adminAllVocabProvider(childId)
5. Riverpod Vocab Provider → Firestore: Queries vocab/{childId}/items
6. Firestore → Riverpod Vocab Provider: Returns all VocabItem documents
7. Riverpod Vocab Provider → Vocab Manager Screen: Emits item list
8. Vocab Manager Screen → Teacher/Parent: Displays vocab list with category filter chips and an "Add Item" button

9. Teacher/Parent → Vocab Manager Screen: Taps "Add Item" (or "+" floating action button)
10. Vocab Manager Screen → Teacher/Parent: Opens an add form with fields: Word (required), Emoji (required), Category (required), Image URL (optional), Audio URL (optional)
11. Teacher/Parent → Vocab Manager Screen: Enters word (e.g., "Lion")
12. Teacher/Parent → Vocab Manager Screen: Enters emoji (e.g., "🦁")
13. Teacher/Parent → Vocab Manager Screen: Enters category (e.g., "Animals")
14. Teacher/Parent → Vocab Manager Screen: (Optional) Enters image URL
15. Teacher/Parent → Vocab Manager Screen: (Optional) Enters audio URL
16. Teacher/Parent → Vocab Manager Screen: Taps "Save"
17. Vocab Manager Screen: Validates that Word, Emoji, and Category are all non-empty
18. Vocab Manager Screen → Firestore: Adds document to vocab/{childId}/items with {word, emoji, category, imageUrl, audioUrl}
19. Firestore → Vocab Manager Screen: Confirms write; returns new document ID
20. Riverpod Vocab Provider: Firestore listener emits the updated list automatically
21. Vocab Manager Screen → Teacher/Parent: Closes form; new item appears in the list

### Alternative Flow A — Missing Required Fields

17a. Vocab Manager Screen: Detects Word or Emoji or Category is empty
18a. Vocab Manager Screen → Teacher/Parent: Shows validation error "Word, Emoji, and Category are required"
19a. Teacher/Parent → Vocab Manager Screen: Fills in missing fields; retries from step 16

---

## SD-17 — Parent / Teacher Edits Existing Vocabulary

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Vocab Manager Screen | Flutter Screen |
| Firestore | Database |

### Main Flow

1. Teacher/Parent → Vocab Manager Screen: Taps the edit icon on an existing item (e.g., "Cat 🐱")
2. Vocab Manager Screen → Teacher/Parent: Opens edit form pre-populated with current values: word="Cat", emoji="🐱", category="Animals", imageUrl, audioUrl
3. Teacher/Parent → Vocab Manager Screen: Modifies one or more fields (e.g., changes emoji from 🐱 to 🐈)
4. Teacher/Parent → Vocab Manager Screen: Taps "Save"
5. Vocab Manager Screen: Validates required fields are non-empty
6. Vocab Manager Screen → Firestore: Updates document vocab/{childId}/items/{itemId} with changed field values
7. Firestore → Vocab Manager Screen: Confirms update
8. Vocab Manager Screen → Teacher/Parent: Closes form; item shows updated emoji in the list

### Alternative Flow A — Cancel Without Changes

4a. Teacher/Parent → Vocab Manager Screen: Taps "Cancel"
5a. Vocab Manager Screen → Teacher/Parent: Closes form with no Firestore write; item unchanged

---

## SD-18 — Parent / Teacher Enables or Disables a Vocabulary Category

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Vocab Manager Screen | Flutter Screen |
| Firestore | Database |
| Riverpod Vocab Provider | State Layer |
| AAC Board Screen / Vocab Learning Screen | Flutter Screens |

### Main Flow (Disabling a Category)

1. Teacher/Parent → Vocab Manager Screen: Navigates to category management section
2. Vocab Manager Screen → Teacher/Parent: Displays list of all categories with toggle switches; all enabled by default
3. Teacher/Parent → Vocab Manager Screen: Toggles the switch for "Food" category from ON to OFF
4. Vocab Manager Screen → Firestore: Updates children/{childId} or a category-settings collection to mark "Food" as disabled
5. Firestore → Vocab Manager Screen: Confirms update
6. Vocab Manager Screen → Teacher/Parent: Shows "Food" toggle in OFF (grey) state

7. (Next time child opens AAC Board or Vocab Learning) Riverpod Vocab Provider: Reads enabled-categories list and excludes "Food"
8. Riverpod Vocab Provider → Firestore: Queries vocab items filtered to enabled categories only
9. Firestore → Riverpod Vocab Provider: Returns items with "Food" excluded
10. AAC Board Screen / Vocab Learning Screen → Child: "Food" category does not appear in the category list or sidebar

### Alternative Flow A — Re-enabling a Category

3a. Teacher/Parent → Vocab Manager Screen: Toggles "Food" switch from OFF back to ON
4a. Vocab Manager Screen → Firestore: Updates category status to enabled
5a. Firestore → Vocab Manager Screen: Confirms
6a. (Next child session) Riverpod Vocab Provider: Includes "Food" items in queries
7a. AAC Board / Vocab Learning → Child: "Food" category reappears

---

## SD-19 — Parent / Teacher Adjusts Difficulty Level per Child

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Firestore | Database |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps the settings icon on a child's card
2. Admin Dashboard Screen → Teacher/Parent: Opens child settings panel showing current difficulty (e.g., "Beginner") with three radio options: Beginner, Intermediate, Advanced
3. Teacher/Parent → Admin Dashboard Screen: Selects "Intermediate"
4. Admin Dashboard Screen → Firestore: Updates children/{childId} field difficulty = "intermediate"
5. Firestore → Admin Dashboard Screen: Confirms update
6. Admin Dashboard Screen → Teacher/Parent: Panel shows "Intermediate" as the selected option; success indicator appears
7. (Next child session) App reads updated difficulty from ChildModel; vocabulary content complexity adjusts accordingly

### Alternative Flow A — No Change Made

3a. Teacher/Parent → Admin Dashboard Screen: Taps away from the panel without selecting a new option
4a. Admin Dashboard Screen → Teacher/Parent: Panel closes with no Firestore write; difficulty unchanged

---

## SD-20 — Parent / Teacher Reviews and Comments on Speech Recording

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Recording Review Screen | Flutter Screen |
| Firestore | Database |
| Firebase Storage | Cloud Storage |
| Audio Player | Device Audio Engine |
| GoRouter | Navigation |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps "Recordings" in the sidebar for a selected child
2. Admin Dashboard Screen → GoRouter: Navigates to /admin/recordings/{childId}
3. GoRouter → Recording Review Screen: Loads screen
4. Recording Review Screen → Firestore: Queries recordings/{childId}/recordings ordered by timestamp DESC
5. Firestore → Recording Review Screen: Returns list of RecordingModel (each with id, word, timestamp, storageUrl, adminScore, adminComment)
6. Recording Review Screen → Teacher/Parent: Displays recording list — each row shows word label, date, play button, star rating, and comment field

**Playing a Recording:**

7. Teacher/Parent → Recording Review Screen: Taps the play button on a recording row (e.g., word "Cat")
8. Recording Review Screen → Firebase Storage: Streams audio from storageUrl
9. Firebase Storage → Recording Review Screen: Returns audio stream
10. Recording Review Screen → Audio Player: play(audioStream)
11. Audio Player → Device Speaker: Plays the child's recorded pronunciation
12. Audio Player → Recording Review Screen: Notifies playback complete

**Scoring the Recording:**

13. Teacher/Parent → Recording Review Screen: Taps a star rating (1 to 5 stars)
14. Recording Review Screen → Firestore: Updates recordings/{childId}/recordings/{recordingId} field adminScore = selectedStars
15. Firestore → Recording Review Screen: Confirms update
16. Recording Review Screen → Teacher/Parent: Selected star rating highlighted

**Adding a Comment:**

17. Teacher/Parent → Recording Review Screen: Types a comment in the text field (e.g., "Great effort! Focus on the 'c' sound.")
18. Teacher/Parent → Recording Review Screen: Taps "Save Comment"
19. Recording Review Screen → Firestore: Updates recordings/{childId}/recordings/{recordingId} field adminComment = commentText
20. Firestore → Recording Review Screen: Confirms update
21. Recording Review Screen → Teacher/Parent: Shows save success indicator; comment field displays saved text

### Alternative Flow A — No Recordings Yet

5a. Firestore → Recording Review Screen: Returns empty list
6a. Recording Review Screen → Teacher/Parent: Shows empty state "No recordings submitted yet"

### Alternative Flow B — Playback Fails (Network Issue)

8b. Firebase Storage → Recording Review Screen: Returns error
9b. Recording Review Screen → Teacher/Parent: Shows error toast "Could not load recording — check your connection"

---

## SD-21 — Child Earns Stars at End of Session

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Reward Screen | Flutter Screen |
| Riverpod Reward Provider | State Layer |
| Firestore | Database |
| Confetti Widget | UI Component |
| Flutter Animate | Animation Library |

### Main Flow

1. GoRouter → Reward Screen: Navigates to /child/reward after a session completes
2. Reward Screen → Riverpod Reward Provider: Subscribes to rewardProvider(activeChildId)
3. Riverpod Reward Provider → Firestore: Subscribes to rewards/{childId} document in real time
4. Firestore → Riverpod Reward Provider: Returns current RewardModel {totalStars, badges[]}
5. Reward Screen (initState) → Firestore: Sends atomic increment: rewards/{childId} totalStars += 5
6. Firestore: Applies increment; new totalStars = previousTotal + 5
7. Firestore → Riverpod Reward Provider: Emits updated RewardModel with new totalStars
8. Riverpod Reward Provider → Reward Screen: Delivers updated star count
9. Reward Screen → Flutter Animate: Triggers animation sequence — trophy bounces in; "Great job! 🎉" fades in; 5 star pills pop in one by one; total stars counter fades in; badge row fades in
10. Reward Screen → Confetti Widget: Starts confetti explosion (duration 5 seconds)
11. Reward Screen → Child: Displays trophy, "Great job!" heading, 5 earned star pills, updated total star count (e.g., "You have 17 ⭐ total"), and earned badges row
12. Child → Reward Screen: Taps "Keep it up!" button
13. Reward Screen → GoRouter: Navigates to /child/home

### Alternative Flow A — First Session Ever (No Prior Reward Document)

4a. Firestore → Riverpod Reward Provider: Returns null (document does not exist)
5a. Reward Screen → Firestore: Creates rewards/{childId} with {totalStars: 5, badges: []}
6a. Firestore: Confirms write
7a. Continue from step 7 with totalStars = 5

---

## SD-22 — Child Unlocks a Badge (Reward System Threshold Check)

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Reward Screen | Flutter Screen |
| Firestore | Database |
| Riverpod Reward Provider | State Layer |
| Flutter Animate | Animation Library |

### Badge Milestone Table

| Stars Threshold | Badge ID | Badge Label | Badge Emoji |
|-----------------|----------|-------------|-------------|
| 10 | badge_10 | Star Collector | 🌟 |
| 25 | badge_25 | Champion | 🏆 |
| 50 | badge_50 | Brave Explorer | 🧭 |
| 100 | badge_100 | Word Master | 📚 |
| 200 | badge_200 | Super Learner | 🚀 |
| 500 | badge_500 | Legend | 👑 |

### Main Flow (Runs Inside SD-21 Immediately After Star Increment)

1. Reward Screen → Firestore: Reads current rewards/{childId} including updated totalStars and existing badges[]
2. Firestore → Reward Screen: Returns {totalStars: newTotal, badges: ["badge_10"]} (example)
3. Reward Screen: Evaluates each milestone — checks if threshold <= newTotal AND badge_id is NOT already in badges[]
4. Reward Screen: Identifies badge_25 as newly earned (threshold 25 <= newTotal 27; badge_25 not in existing list)
5. Reward Screen → Firestore: Updates rewards/{childId} badges field using arrayUnion(["badge_25"])
6. Firestore: Applies arrayUnion; badges now = ["badge_10", "badge_25"]
7. Firestore → Riverpod Reward Provider: Emits updated RewardModel
8. Riverpod Reward Provider → Reward Screen: Delivers new badges list
9. Reward Screen → Flutter Animate: Fades in badge row with newly unlocked badge
10. Reward Screen → Child: Shows badge card with emoji 🏆 and label "Champion" in the badge row

### Alternative Flow A — No New Badge Earned

3a. Reward Screen: Evaluates all milestones — no unearned threshold is crossed by newTotal
4a. Reward Screen: Skips Firestore badge update
5a. Reward Screen → Child: Badge row shows only previously earned badges (or is empty if none earned yet)

### Alternative Flow B — Multiple Badges Unlocked in One Session

4b. Reward Screen: Identifies both badge_10 and badge_25 as newly earned (e.g., child went from 8 to 30 stars)
5b. Reward Screen → Firestore: Updates rewards/{childId} badges with arrayUnion(["badge_10", "badge_25"])
6b. Firestore → Riverpod Reward Provider: Emits updated badges list with both new IDs
7b. Reward Screen → Flutter Animate: Animates two badge cards into the row
8b. Reward Screen → Child: Displays both 🌟 Star Collector and 🏆 Champion badges

---

## SD-23 — Child Views Badge Gallery

### Participants

| Label | Type |
|-------|------|
| Child | Actor |
| Reward Screen | Flutter Screen |
| Riverpod Reward Provider | State Layer |
| Firestore | Database |

### Main Flow

1. GoRouter → Reward Screen: Loads /child/reward after a completed session
2. Reward Screen → Riverpod Reward Provider: Subscribes to rewardProvider(activeChildId)
3. Riverpod Reward Provider → Firestore: Reads rewards/{childId}
4. Firestore → Riverpod Reward Provider: Returns {totalStars, badges: ["badge_10", "badge_25", "badge_50"]}
5. Reward Screen: Filters the full badge milestone list to only entries whose IDs appear in the earned badges array; sorts by milestone order (ascending threshold)
6. Reward Screen → Child: Displays badge gallery row — for each earned badge shows an emoji icon and text label (e.g., 🌟 Star Collector, 🏆 Champion, 🧭 Brave Explorer)

### Alternative Flow A — No Badges Earned Yet

4a. Firestore → Riverpod Reward Provider: Returns {totalStars: 3, badges: []}
5a. Reward Screen: Earned badge list is empty
6a. Reward Screen → Child: Badge row is hidden or shows a prompt "Keep earning stars to unlock badges!"

---

## SD-24 — Parent / Teacher Creates Child Profile and Generates Invite Code

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Add Child Screen | Flutter Screen |
| Firestore | Database |
| Invite Service | Service Layer |
| GoRouter | Navigation |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps "Add Child" in the sidebar
2. Admin Dashboard Screen → GoRouter: Navigates to /admin/add-child
3. GoRouter → Add Child Screen: Loads screen
4. Add Child Screen → Teacher/Parent: Displays form — Child Name text field, Avatar Picker grid (12 emoji presets each with a gradient colour pair), Difficulty selector (Beginner / Intermediate / Advanced), Q&A Mode selector (2 choices / 4 choices), and "Create Profile & Generate Code" button

5. Teacher/Parent → Add Child Screen: Enters child's name (e.g., "Sarah")
6. Teacher/Parent → Add Child Screen: Taps an avatar emoji (e.g., 🦁); background gradient pair is set automatically
7. Teacher/Parent → Add Child Screen: Selects difficulty "Beginner"
8. Teacher/Parent → Add Child Screen: Selects Q&A mode "2 choices"
9. Teacher/Parent → Add Child Screen: Taps "Create Profile & Generate Code"
10. Add Child Screen: Validates that the name field is not empty
11. Add Child Screen → Firestore: Creates document children/{newChildId} with {name, avatarEmoji, avatarGradientStart, avatarGradientEnd, difficulty, qaMode, linkedUsers=[currentUid], createdBy=currentUid, isActiveOnDevice=false}
12. Firestore → Add Child Screen: Confirms write; returns newChildId
13. Add Child Screen → Invite Service: generateCode(childId=newChildId, createdBy=currentUid)
14. Invite Service: Generates a random 6-digit numeric code (e.g., "849372")
15. Invite Service → Firestore: Creates document inviteCodes/{849372} with {childId, createdBy, expiresAt=now+48hours, used=false}
16. Firestore → Invite Service: Confirms write
17. Invite Service → Add Child Screen: Returns code string "849372"
18. Add Child Screen → Teacher/Parent: Displays success panel: "Profile created! 🎉", large code text "849372", Copy Code button, "Expires in 48 hours" note, and "+ Add another child" link

19. Teacher/Parent → Add Child Screen: Taps "Copy Code"
20. Add Child Screen → Device Clipboard: Copies string "849372"
21. Add Child Screen → Teacher/Parent: Shows "✓ Copied" text on the button for 2 seconds; then resets

### Alternative Flow A — Empty Name

10a. Add Child Screen: Detects name field is empty
11a. Add Child Screen → Teacher/Parent: Shows inline error "Please enter the child's name"
12a. Teacher/Parent → Add Child Screen: Types the name and retries

### Alternative Flow B — Create Another Child

22b. Teacher/Parent → Add Child Screen: Taps "+ Add another child"
23b. Add Child Screen: Resets form to empty state
24b. Returns to step 5

---

## SD-25 — Parent / Teacher Links to Child via Invite Code

### Participants

| Label | Type |
|-------|------|
| Teacher / Parent | Actor |
| Admin Dashboard Screen | Flutter Screen |
| Enter Invite Code Screen | Flutter Screen |
| Invite Service | Service Layer |
| Firestore | Database |
| GoRouter | Navigation |
| Profile Picker Screen | Flutter Screen |

### Main Flow

1. Teacher/Parent → Admin Dashboard Screen: Taps "Enter Invite Code" option in the sidebar
2. Admin Dashboard Screen → GoRouter: Navigates to /admin/link-code
3. GoRouter → Enter Invite Code Screen: Loads screen
4. Enter Invite Code Screen → Teacher/Parent: Displays a 6-digit numeric input field and "Link to Child" button

5. Teacher/Parent → Enter Invite Code Screen: Enters the 6-digit code (e.g., "849372")
6. Teacher/Parent → Enter Invite Code Screen: Taps "Link to Child"
7. Enter Invite Code Screen → Invite Service: redeemCode(code="849372", uid=currentUid)
8. Invite Service → Firestore: Opens a transaction; reads document inviteCodes/{849372}
9. Firestore → Invite Service: Returns {childId, expiresAt, used=false}
10. Invite Service: Validates used == false AND expiresAt > now
11. Invite Service → Firestore (transaction): Updates inviteCodes/{849372} field used = true
12. Invite Service → Firestore (transaction): Updates children/{childId} field linkedUsers via arrayUnion(currentUid)
13. Firestore: Commits both writes atomically
14. Firestore → Invite Service: Confirms transaction success
15. Invite Service → Enter Invite Code Screen: Returns ChildModel of the newly linked child
16. Enter Invite Code Screen → GoRouter: Navigates to / (profile picker)
17. GoRouter → Profile Picker Screen: Loads screen
18. Profile Picker Screen → Teacher/Parent: Displays child card for the newly linked child (e.g., "Sarah" 🦁)

### Alternative Flow A — Code Already Used

9a. Firestore → Invite Service: Returns document with used = true
10a. Invite Service: Detects code is already used
11a. Invite Service → Enter Invite Code Screen: Throws "Code already used" error
12a. Enter Invite Code Screen → Teacher/Parent: Shows error "This invite code has already been used. Ask the teacher or parent for a new one."

### Alternative Flow B — Code Expired

9b. Firestore → Invite Service: Returns document with expiresAt = past timestamp
10b. Invite Service: Detects expiresAt <= now
11b. Invite Service → Enter Invite Code Screen: Throws "Code expired" error
12b. Enter Invite Code Screen → Teacher/Parent: Shows error "This invite code has expired (valid for 48 hours). Please request a new code."

### Alternative Flow C — Code Not Found

8c. Firestore → Invite Service: Returns no document for the entered code
9c. Invite Service → Enter Invite Code Screen: Throws "Invalid code" error
10c. Enter Invite Code Screen → Teacher/Parent: Shows error "Invalid code. Please check the code and try again."

---

## APPENDIX — PARTICIPANT LEGEND

| Label Used in Diagrams | Full Description |
|------------------------|------------------|
| Child | The child user interacting with learning modules on the device |
| Teacher / Parent | The authenticated admin user (Teacher or Parent role) |
| Login Screen | admin_login_screen.dart |
| Register Screen | admin_register_screen.dart |
| Profile Picker Screen | profile_picker_screen.dart |
| Confirm Profile Screen | confirm_profile_screen.dart |
| Child Home Screen | child_home_screen.dart |
| AAC Board Screen | aac_board_screen.dart |
| Vocab Learning Screen | vocab_learning_screen.dart |
| Speech Practice Screen | speech_practice_screen.dart |
| Reward Screen | reward_screen.dart |
| Admin Dashboard Screen | admin_dashboard_screen.dart |
| Add Child Screen | add_child_screen.dart |
| Vocab Manager Screen | vocab_manager_screen.dart |
| Progress Screen | progress_screen.dart |
| Recording Review Screen | recording_review_screen.dart |
| Enter Invite Code Screen | enter_invite_code_screen.dart |
| Riverpod Vocab Provider | vocab_provider.dart — vocabItemsProvider, categoriesProvider |
| Riverpod Child Provider | child_provider.dart — linkedChildrenProvider |
| Riverpod Active Child Provider | child_provider.dart — activeChildProvider (StateProvider) |
| Riverpod Session Provider | session_provider.dart — childSessionsProvider |
| Riverpod Reward Provider | reward_provider.dart — rewardProvider |
| Session Service | session_service.dart |
| Invite Service | invite_service.dart |
| Firebase Auth | FirebaseAuth.instance (firebase_auth package) |
| Firestore | FirebaseFirestore.instance (cloud_firestore package) |
| Firebase Storage | FirebaseStorage.instance (firebase_storage package) |
| Flutter TTS | FlutterTts() (flutter_tts package) |
| Audio Recorder | AudioRecorder() (record package) |
| Audio Player | AudioPlayer (just_audio or audioplayers package) |
| FL Chart Widget | LineChart / BarChart (fl_chart package) |
| Confetti Widget | ConfettiController (confetti package) |
| Flutter Animate | .animate() extension (flutter_animate package) |
| GoRouter | GoRouter instance from router.dart |
| OS Permission Dialog | Device operating system microphone permission prompt |
| Device Clipboard | Flutter Clipboard.setData() |
| Device Speaker | Physical audio output on the device |
| Device Microphone | Physical microphone input on the device |
| Email Client | Device native email or browser used to click the verification link |
