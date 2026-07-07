# Use Case Diagram Reference — SpeakUp! AAC Learning App

This document is a complete reference for every actor, use case, and relationship in the SpeakUp! app. Use it as the source of truth to manually draw the use case diagram in Canva.

---

## SECTION 1 — ACTORS

| Actor | Type | Description |
|-------|------|-------------|
| Child | Primary — Human | A child with communication needs who uses the learning modules. Selected from the profile picker; does not log in with credentials. Interacts with the AAC board, vocabulary activities, speech practice, and reward screens. |
| Teacher | Primary — Human | An educator who registers with professional credentials (school, qualification, experience). Creates child profiles, manages vocabulary, monitors progress, and reviews recordings. |
| Parent | Primary — Human | A guardian who registers without professional credentials. Links to child profiles via invite code. Monitors progress and reviews speech recordings. |
| Admin | Abstract — Human | Generalisation of Teacher and Parent. Represents any authenticated user with management capability. Teacher and Parent inherit all Admin use cases. |
| Firebase Auth | Secondary — System | External authentication service. Handles sign-in, account creation, and email verification. |
| Firestore | Secondary — System | Cloud NoSQL database. Stores all app data: users, children, sessions, vocabulary, recordings, rewards, invite codes. |
| Firebase Storage | Secondary — System | Cloud file storage. Stores speech practice audio files (.aac) uploaded by the child. |
| Flutter TTS | Secondary — System | Text-to-speech engine running on device. Speaks words and full sentences aloud on demand. |
| Audio Recorder | Secondary — System | Device microphone and recording engine used during speech practice to capture the child's voice. |

---

## SECTION 2 — USE CASE INVENTORY

### 2.1 Authentication and Registration

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-01 | Login | Admin | Enter email and password to authenticate and access the admin dashboard. |
| UC-02 | Register as Teacher | Teacher | Complete a 4-step registration form including professional information. |
| UC-03 | Register as Parent | Parent | Complete a 3-step registration form without professional information. |
| UC-04 | Verify Email | Admin | Click the verification link sent by Firebase Auth to activate the account before the first login. |
| UC-05 | Logout | Admin | Sign out of the current authenticated session and return to the profile picker. |

### 2.2 Child Profile Management

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-06 | Create Child Profile | Admin | Enter the child's name, avatar, difficulty, and Q&A mode to create a profile. |
| UC-07 | Generate Invite Code | System | Produce a 6-digit, 48-hour time-limited code automatically on child profile creation. |
| UC-08 | Link to Child via Invite Code | Admin | Enter a 6-digit code to add an existing child profile to the admin's account. |
| UC-09 | Select Child Profile | Child | Choose a child card from the profile picker to begin a session. |
| UC-10 | Confirm Child Profile | Child | Confirm identity on the confirmation screen before entering the child home screen. |
| UC-11 | Adjust Difficulty Level | Admin | Change a child's difficulty setting between Beginner, Intermediate, and Advanced. |
| UC-12 | Adjust Q&A Mode | Admin | Switch a child's question format between 2-choice and 4-choice modes. |

### 2.3 AAC Communication Board

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-13 | Browse AAC Categories | Child | Tap categories in the left sidebar to filter the symbol grid. |
| UC-14 | Select Symbol | Child | Tap a vocabulary symbol card to add its word to the sentence bar. |
| UC-15 | Build Sentence | Child | Accumulate multiple word pills in the sentence bar by selecting symbols. |
| UC-16 | Play Sentence via TTS | Child | Tap the Speak button to have TTS read the full sentence aloud. |
| UC-17 | Delete Last Word | Child | Remove the most recently added word pill from the sentence bar. |
| UC-18 | Clear All Words | Child | Empty the entire sentence bar at once. |
| UC-19 | Log AAC Session | System | Automatically save the session record to Firestore after the Speak button is tapped. |

### 2.4 Vocabulary Learning Cards

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-20 | Select Vocabulary Category | Child | Tap a category chip to filter the active vocabulary pool. |
| UC-21 | View Vocabulary Card | Child | See the current item displayed with emoji or image and word label. |
| UC-22 | Listen to Word Pronunciation | Child | Tap the speak icon on a card to hear TTS say the word aloud. |
| UC-23 | Select Correct Answer | Child | Tap the button that matches the displayed item; advance to the next item. |
| UC-24 | Select Wrong Answer | Child | Tap an incorrect button; receive corrective feedback and retry the same item. |
| UC-25 | Complete Vocabulary Session | Child | Reach 5 correct answers to finish the session and proceed to the reward screen. |

### 2.5 Guided Question Activity

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-26 | Answer Guided Question — Correct | Child | Select the matching word from 4 multiple-choice options; receive positive feedback. |
| UC-27 | Answer Guided Question — Wrong | Child | Select an incorrect option from 4 choices; receive corrective feedback and retry. |
| UC-28 | Save Guided Question Session | System | Record session accuracy, words attempted, and duration to Firestore on completion. |
| UC-29 | Receive Reward after Guided Question | Child | Navigate to the reward screen and earn 5 stars after 5 correct answers. |

### 2.6 Fill-in-the-Blank Exercise

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-30 | Answer Fill-in-the-Blank — Correct | Child | Select the correct word from 2 simplified options; advance to the next prompt. |
| UC-31 | Answer Fill-in-the-Blank — Wrong | Child | Select the incorrect option; receive corrective feedback and retry the same prompt. |
| UC-32 | Save Fill-in-the-Blank Session | System | Record session data to Firestore on completion. |
| UC-33 | Receive Reward after Fill-in-the-Blank | Child | Navigate to the reward screen and earn 5 stars after 5 correct answers. |

### 2.7 Speech Practice

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-34 | Listen to Target Word | Child | Tap the Listen button to hear TTS speak the target word before recording. |
| UC-35 | Request Microphone Permission | System | Prompt the device OS for microphone access the first time recording is attempted. |
| UC-36 | Record Voice | Child | Tap Record to begin audio capture; tap Stop to end the recording. |
| UC-37 | Upload Recording to Storage | System | Background upload of the .aac audio file to Firebase Storage after recording stops. |
| UC-38 | Save Recording Metadata | System | Write the recording document to Firestore with word, timestamp, and storage URL. |
| UC-39 | Play Back Saved Recording | Child | Tap the Play Back button to listen to the just-recorded audio within the session. |
| UC-40 | Advance to Next Word | Child | Tap Next Word to move to the next vocabulary item in the speech practice list. |
| UC-41 | Log Speech Practice Session | System | Write the session record to Firestore when all words are completed or the child exits. |

### 2.8 Reward System

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-42 | Earn Stars | Child | Automatically receive 5 stars added to the total at the end of a completed session. |
| UC-43 | Check Badge Threshold | System | Compare the new star total against all badge milestones after awarding stars. |
| UC-44 | Unlock Badge | Child | Receive a new badge when the total star count crosses a milestone (10, 25, 50, 100, 200, 500). |
| UC-45 | View Badge Gallery | Child | See all earned badges displayed on the reward screen and child home screen. |

### 2.9 Progress Dashboard

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-46 | View Progress Dashboard | Admin | Load and display the accuracy trend chart, session history list, and summary statistics. |
| UC-47 | Filter Sessions by Date | Admin | Apply a date range filter to narrow the sessions shown in the list and chart. |
| UC-48 | Expand Session Detail | Admin | Tap a session row to reveal full detail: module, accuracy, words attempted, duration, timestamp. |

### 2.10 Vocabulary Control Panel

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-49 | Add New Vocabulary Item | Admin | Enter word, emoji, category, and optional image or audio URL to create a new item. |
| UC-50 | Edit Existing Vocabulary | Admin | Modify any field of an existing vocabulary item and save changes. |
| UC-51 | Delete Vocabulary Item | Admin | Remove a vocabulary item permanently from a child's word list. |
| UC-52 | Enable Vocabulary Category | Admin | Toggle a vocabulary category back on so it appears in the child's activities. |
| UC-53 | Disable Vocabulary Category | Admin | Toggle a vocabulary category off so it is hidden from the child's activities. |

### 2.11 Recording Review

| ID | Use Case | Primary Actor | Brief Description |
|----|----------|---------------|-------------------|
| UC-54 | View Recordings List | Admin | Browse all speech practice recordings submitted by a specific child. |
| UC-55 | Play Recording | Admin | Stream and play back a child's speech recording from Firebase Storage. |
| UC-56 | Score Recording | Admin | Assign a 1–5 star rating to a child's recording as feedback. |
| UC-57 | Comment on Recording | Admin | Write a text comment providing detailed feedback on a child's pronunciation. |

---

## SECTION 3 — ACTOR–USE CASE ASSOCIATION TABLE

### Child Associations

| Child | Use Case |
|-------|----------|
| Child | UC-09 Select Child Profile |
| Child | UC-10 Confirm Child Profile |
| Child | UC-13 Browse AAC Categories |
| Child | UC-14 Select Symbol |
| Child | UC-15 Build Sentence |
| Child | UC-16 Play Sentence via TTS |
| Child | UC-17 Delete Last Word |
| Child | UC-18 Clear All Words |
| Child | UC-20 Select Vocabulary Category |
| Child | UC-21 View Vocabulary Card |
| Child | UC-22 Listen to Word Pronunciation |
| Child | UC-23 Select Correct Answer |
| Child | UC-24 Select Wrong Answer |
| Child | UC-25 Complete Vocabulary Session |
| Child | UC-26 Answer Guided Question — Correct |
| Child | UC-27 Answer Guided Question — Wrong |
| Child | UC-29 Receive Reward after Guided Question |
| Child | UC-30 Answer Fill-in-the-Blank — Correct |
| Child | UC-31 Answer Fill-in-the-Blank — Wrong |
| Child | UC-33 Receive Reward after Fill-in-the-Blank |
| Child | UC-34 Listen to Target Word |
| Child | UC-36 Record Voice |
| Child | UC-39 Play Back Saved Recording |
| Child | UC-40 Advance to Next Word |
| Child | UC-42 Earn Stars |
| Child | UC-44 Unlock Badge |
| Child | UC-45 View Badge Gallery |

### Teacher Associations

| Teacher | Use Case |
|---------|----------|
| Teacher | UC-01 Login |
| Teacher | UC-02 Register as Teacher |
| Teacher | UC-04 Verify Email |
| Teacher | UC-06 Create Child Profile |
| Teacher | UC-08 Link to Child via Invite Code |
| Teacher | UC-11 Adjust Difficulty Level |
| Teacher | UC-12 Adjust Q&A Mode |
| Teacher | UC-46 View Progress Dashboard |
| Teacher | UC-47 Filter Sessions by Date |
| Teacher | UC-48 Expand Session Detail |
| Teacher | UC-49 Add New Vocabulary Item |
| Teacher | UC-50 Edit Existing Vocabulary |
| Teacher | UC-51 Delete Vocabulary Item |
| Teacher | UC-52 Enable Vocabulary Category |
| Teacher | UC-53 Disable Vocabulary Category |
| Teacher | UC-54 View Recordings List |
| Teacher | UC-55 Play Recording |
| Teacher | UC-56 Score Recording |
| Teacher | UC-57 Comment on Recording |

### Parent Associations

| Parent | Use Case |
|--------|----------|
| Parent | UC-01 Login |
| Parent | UC-03 Register as Parent |
| Parent | UC-04 Verify Email |
| Parent | UC-08 Link to Child via Invite Code |
| Parent | UC-11 Adjust Difficulty Level |
| Parent | UC-12 Adjust Q&A Mode |
| Parent | UC-46 View Progress Dashboard |
| Parent | UC-47 Filter Sessions by Date |
| Parent | UC-48 Expand Session Detail |
| Parent | UC-54 View Recordings List |
| Parent | UC-55 Play Recording |
| Parent | UC-56 Score Recording |
| Parent | UC-57 Comment on Recording |

### System Actor Associations

| System Actor | Use Case |
|-------------|----------|
| Firebase Auth | UC-01 Login |
| Firebase Auth | UC-02 Register as Teacher |
| Firebase Auth | UC-03 Register as Parent |
| Firebase Auth | UC-04 Verify Email |
| Firebase Auth | UC-05 Logout |
| Firestore | UC-06 Create Child Profile |
| Firestore | UC-07 Generate Invite Code |
| Firestore | UC-08 Link to Child via Invite Code |
| Firestore | UC-19 Log AAC Session |
| Firestore | UC-28 Save Guided Question Session |
| Firestore | UC-32 Save Fill-in-the-Blank Session |
| Firestore | UC-38 Save Recording Metadata |
| Firestore | UC-41 Log Speech Practice Session |
| Firestore | UC-42 Earn Stars |
| Firestore | UC-43 Check Badge Threshold |
| Firestore | UC-44 Unlock Badge |
| Firestore | UC-46 View Progress Dashboard |
| Firestore | UC-49 Add New Vocabulary Item |
| Firestore | UC-50 Edit Existing Vocabulary |
| Firestore | UC-51 Delete Vocabulary Item |
| Firebase Storage | UC-37 Upload Recording to Storage |
| Firebase Storage | UC-39 Play Back Saved Recording |
| Firebase Storage | UC-55 Play Recording |
| Flutter TTS | UC-16 Play Sentence via TTS |
| Flutter TTS | UC-22 Listen to Word Pronunciation |
| Flutter TTS | UC-34 Listen to Target Word |
| Audio Recorder | UC-35 Request Microphone Permission |
| Audio Recorder | UC-36 Record Voice |

---

## SECTION 4 — INCLUDE, EXTEND, AND GENERALIZATION RELATIONSHIPS

### 4.1 <<include>> Relationships

An <<include>> relationship means the base use case always triggers the included use case as a mandatory part of its flow.

| Base Use Case | Direction | Included Use Case | Reason |
|---------------|-----------|-------------------|--------|
| UC-16 Play Sentence via TTS | includes → | UC-19 Log AAC Session | Every TTS trigger automatically saves a session record |
| UC-02 Register as Teacher | includes → | UC-04 Verify Email | Email verification is a mandatory post-registration step |
| UC-03 Register as Parent | includes → | UC-04 Verify Email | Email verification is a mandatory post-registration step |
| UC-06 Create Child Profile | includes → | UC-07 Generate Invite Code | An invite code is always generated immediately on child creation |
| UC-25 Complete Vocabulary Session | includes → | UC-28 Save Guided Question Session | Session data is always saved on completion |
| UC-25 Complete Vocabulary Session | includes → | UC-42 Earn Stars | Completing a session always awards 5 stars |
| UC-29 Receive Reward | includes → | UC-43 Check Badge Threshold | Badge milestone check runs every time stars are awarded |
| UC-33 Receive Reward (FIB) | includes → | UC-43 Check Badge Threshold | Badge milestone check runs every time stars are awarded |
| UC-36 Record Voice | includes → | UC-35 Request Microphone Permission | Microphone permission must be obtained before recording can start |
| UC-37 Upload Recording to Storage | includes → | UC-38 Save Recording Metadata | Metadata is always written to Firestore after a successful upload |
| UC-41 Log Speech Practice Session | includes → | UC-42 Earn Stars | Session completion awards stars for the child |

### 4.2 <<extend>> Relationships

An <<extend>> relationship means the extending use case adds optional or conditional behaviour to the base use case.

| Extending Use Case | Direction | Base Use Case | Condition |
|-------------------|-----------|---------------|-----------|
| UC-24 Select Wrong Answer | extends → | UC-23 Select Correct Answer | Only triggered when the selected answer is incorrect |
| UC-27 Answer Guided Question — Wrong | extends → | UC-26 Answer Guided Question — Correct | Only triggered when the selected option is incorrect |
| UC-31 Answer Fill-in-the-Blank — Wrong | extends → | UC-30 Answer Fill-in-the-Blank — Correct | Only triggered when the selected option is incorrect |
| UC-44 Unlock Badge | extends → | UC-43 Check Badge Threshold | Only when the new star total crosses an unearned milestone |
| UC-08 Link to Child via Invite Code | extends → | UC-07 Generate Invite Code | The code is generated by the creator; linking is performed conditionally by a different user only when the code is valid, unused, and within the 48-hour window |
| UC-53 Disable Vocabulary Category | extends → | UC-52 Enable Vocabulary Category | Disable is a conditional alternate action when a category is currently active |

### 4.3 Generalization Relationships

A generalization (inheritance) arrow from child to parent means the child actor IS-A specialization of the parent actor and inherits all its associations.

| Specific Actor (Child) | Generalization Arrow → | General Actor (Parent) | Notes |
|-----------------------|----------------------|------------------------|-------|
| Teacher | → | Admin | Teacher inherits all Admin use cases and additionally has the full 4-step registration including professional info (school, qualification, specialisation, years of experience). |
| Parent | → | Admin | Parent inherits all Admin use cases and uses the shorter 3-step registration with no professional info fields. |

---

## SECTION 5 — SUBSYSTEM BOUNDARY GROUPS

Use these groupings to draw rectangular subsystem boundary boxes around sets of use cases in Canva.

| Subsystem Name | Use Cases Inside the Boundary |
|----------------|-------------------------------|
| Authentication System | UC-01, UC-02, UC-03, UC-04, UC-05 |
| Child Profile System | UC-06, UC-07, UC-08, UC-09, UC-10, UC-11, UC-12 |
| AAC Communication Board | UC-13, UC-14, UC-15, UC-16, UC-17, UC-18, UC-19 |
| Vocabulary Learning Cards | UC-20, UC-21, UC-22, UC-23, UC-24, UC-25 |
| Guided Question Activity | UC-26, UC-27, UC-28, UC-29 |
| Fill-in-the-Blank Exercise | UC-30, UC-31, UC-32, UC-33 |
| Speech Practice Module | UC-34, UC-35, UC-36, UC-37, UC-38, UC-39, UC-40, UC-41 |
| Reward System | UC-42, UC-43, UC-44, UC-45 |
| Progress Dashboard | UC-46, UC-47, UC-48 |
| Vocabulary Control Panel | UC-49, UC-50, UC-51, UC-52, UC-53 |
| Recording Review | UC-54, UC-55, UC-56, UC-57 |

---

## SECTION 6 — QUICK REFERENCE: USE CASE COUNTS

| Actor | Number of Use Cases |
|-------|---------------------|
| Child | 27 |
| Teacher | 19 |
| Parent | 13 |
| Firebase Auth | 5 |
| Firestore | 15 |
| Firebase Storage | 3 |
| Flutter TTS | 3 |
| Audio Recorder | 2 |
| **Total Unique Use Cases** | **57** |
can you 