# SpeakUp! Test Cases

Use these entries in your Excel template. Replace the sample dates/version with your real test date and report version. For `Actual Results` and `Pass / Fail / Not`, use the suggested text if your result matches exactly.

---

## TC_001 - User Registration

- Test Case ID: `TC_001`
- Version: `1.0`
- Test Case Title: `User Registration`
- Functional Requirement Covered: `FR01`
- Screenshot Needed: `Registration form + success message`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | App is installed and connected to Firebase |
| 2 | Internet connection is available |
| 3 | Test email account is available and not yet registered |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Role = Teacher or Parent |
| 2 | Email = `testuser01@example.com` |
| 3 | Password = `Test1234` |
| 4 | PIN = `1234` |

**Test Scenario**

Verify that a parent or teacher can create a new account using valid details.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open Admin Login and click `Create an Account` | Registration flow opens | As expected | Pass |
| 2 | Select a role and continue | Next registration step appears | As expected | Pass |
| 3 | Enter valid personal details | Form accepts valid input | As expected | Pass |
| 4 | Enter professional details if Teacher | Professional details step is accepted | As expected | Pass |
| 5 | Enter valid password and PIN, then submit | Success screen appears and verification notice is shown | As expected | Pass |

---

## TC_002 - User Login and Logout

- Test Case ID: `TC_002`
- Version: `1.0`
- Test Case Title: `User Login and Logout`
- Functional Requirement Covered: `FR02, FR20`
- Screenshot Needed: `Login success/dashboard + logout result`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Registered and email-verified admin account exists |
| 2 | App is connected to Firebase |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Email = `testuser01@example.com` |
| 2 | Password = `Test1234` |

**Test Scenario**

Verify that the parent or teacher can log in successfully and log out safely.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open Admin Login screen | Login form is displayed | As expected | Pass |
| 2 | Enter valid email and password | Credentials are accepted | As expected | Pass |
| 3 | Click `Sign In` | Admin dashboard opens | As expected | Pass |
| 4 | Click `Sign Out` from sidebar | User is logged out and returned to entry/profile screen | As expected | Pass |

---

## TC_003 - Child Profile Management

- Test Case ID: `TC_003`
- Version: `1.0`
- Test Case Title: `Child Profile Management`
- Functional Requirement Covered: `FR03`
- Screenshot Needed: `Child profile form + saved profile`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin is logged in |
| 2 | Admin dashboard is accessible |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Child Name = `Adam` |
| 2 | Avatar = any preset avatar |
| 3 | Difficulty = `Beginner` |
| 4 | Q&A Mode = `2 choices` |

**Test Scenario**

Verify that the admin can create a child profile with valid settings.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Add Child` from dashboard | Add Child form opens | As expected | Pass |
| 2 | Enter child name and choose avatar | Form accepts child details | As expected | Pass |
| 3 | Select difficulty and Q&A mode | Selected settings are shown | As expected | Pass |
| 4 | Click `Create Profile & Generate Code` | Child profile is saved and invite code is generated | As expected | Pass |

---

## TC_004 - AAC Board Category Display

- Test Case ID: `TC_004`
- Version: `1.0`
- Test Case Title: `AAC Board Category Display`
- Functional Requirement Covered: `FR04`
- Screenshot Needed: `AAC board with categories`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin has created a child profile |
| 2 | Child has linked vocabulary items in at least 2 categories |
| 3 | Child session is launched |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Category examples = `Food`, `Animals` |

**Test Scenario**

Verify that AAC board categories and symbols are displayed correctly.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `AAC Board` from child home | AAC board opens | As expected | Pass |
| 2 | Observe category sidebar | Categories are listed clearly | As expected | Pass |
| 3 | Tap different categories | Related symbols appear for the selected category | As expected | Pass |

---

## TC_005 - AAC Sentence Builder and TTS

- Test Case ID: `TC_005`
- Version: `1.0`
- Test Case Title: `AAC Sentence Builder and TTS`
- Functional Requirement Covered: `FR05, FR06, FR07, FR08`
- Screenshot Needed: `Sentence bar with selected words + Speak button`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child session is active |
| 2 | AAC board contains available symbols |
| 3 | Device audio is enabled |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Example words = `I`, `want`, `apple` |

**Test Scenario**

Verify that the child can select symbols, build a sentence, play TTS audio, and clear words.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Tap several symbols in AAC board | Selected words appear in sentence bar | As expected | Pass |
| 2 | Tap `Speak` | Sentence is spoken aloud | As expected | Pass |
| 3 | Remove one selected word | Selected word is deleted from the sentence bar | As expected | Pass |
| 4 | Tap `Clear` | All words are removed from the sentence bar | As expected | Pass |

---

## TC_006 - Vocabulary Learning Activity

- Test Case ID: `TC_006`
- Version: `1.0`
- Test Case Title: `Vocabulary Learning Activity`
- Functional Requirement Covered: `FR09`
- Screenshot Needed: `Vocabulary learning screen`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child session is active |
| 2 | Vocabulary items already exist |
| 3 | Device audio is enabled |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Example word = `Apple` |

**Test Scenario**

Verify that the vocabulary learning module loads picture/emoji, word, and audio correctly.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Vocab Learning` | Vocabulary learning screen opens | As expected | Pass |
| 2 | Observe the vocab card | Picture/emoji and target word are displayed | As expected | Pass |
| 3 | Tap the speaker button | Audio for the word plays | As expected | Pass |

---

## TC_007 - Guided Question Activity

- Test Case ID: `TC_007`
- Version: `1.0`
- Test Case Title: `Guided Question Activity`
- Functional Requirement Covered: `FR10`
- Screenshot Needed: `Question screen + correct/wrong feedback`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child profile Q&A mode is set to `4 choices` |
| 2 | Vocabulary items are available |
| 3 | Child session is active |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Q&A Mode = `4 choices` |

**Test Scenario**

Verify that the child can answer a guided question and receive correct or wrong feedback.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Vocab Learning` with 4-choice mode | Four answer choices are displayed | As expected | Pass |
| 2 | Select the correct answer | Correct feedback is shown and progress increases | As expected | Pass |
| 3 | Select an incorrect answer on another question | Wrong feedback is shown and retry is allowed | As expected | Pass |

---

## TC_008 - Fill-in-the-Blank Activity

- Test Case ID: `TC_008`
- Version: `1.0`
- Test Case Title: `Fill-in-the-Blank Activity`
- Functional Requirement Covered: `FR11`
- Screenshot Needed: `Fill-in-the-blank screen + result`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child profile Q&A mode is set to `2 choices` |
| 2 | Vocabulary items are available |
| 3 | Child session is active |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Q&A Mode = `2 choices` |

**Test Scenario**

Verify that the child can complete the simplified 2-choice vocabulary activity and receive feedback.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Vocab Learning` with 2-choice mode | Two answer choices are displayed | As expected | Pass |
| 2 | Select an answer | Activity checks the answer and shows feedback | As expected | Pass |
| 3 | Continue to next item | Next activity item loads correctly | As expected | Pass |

---

## TC_009 - Speech Practice Module

- Test Case ID: `TC_009`
- Version: `1.0`
- Test Case Title: `Speech Practice Module`
- Functional Requirement Covered: `FR12`
- Screenshot Needed: `Recording screen + playback/record status`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child session is active |
| 2 | Vocabulary items are available |
| 3 | Microphone permission is granted |
| 4 | Device audio is enabled |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Example word = `Cat` |

**Test Scenario**

Verify that the child can listen to a target word, record speech, and play back the recording.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Speech Practice` and choose a word | Recording screen opens for the selected word | As expected | Pass |
| 2 | Tap `Listen` | Target word audio plays | As expected | Pass |
| 3 | Tap `Record`, then stop recording | Recording is saved successfully | As expected | Pass |
| 4 | Tap `Play Back` | Saved recording plays correctly | As expected | Pass |

---

## TC_010 - Progress Tracking

- Test Case ID: `TC_010`
- Version: `1.0`
- Test Case Title: `Progress Tracking`
- Functional Requirement Covered: `FR13`
- Screenshot Needed: `Completed activity + Firebase/session record`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child profile exists |
| 2 | Admin and child modules are working |
| 3 | Firebase Console is accessible |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Complete one activity from AAC, Vocab, or Speech |

**Test Scenario**

Verify that a completed activity saves session data successfully.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Complete one child activity | Activity finishes successfully | As expected | Pass |
| 2 | Open Firebase Firestore `sessions/{childId}/sessions` | New session document is present | As expected | Pass |
| 3 | Check saved fields such as module, accuracy, wordsAttempted, and timestamp | Session data is stored correctly | As expected | Pass |

---

## TC_011 - Progress Dashboard

- Test Case ID: `TC_011`
- Version: `1.0`
- Test Case Title: `Progress Dashboard`
- Functional Requirement Covered: `FR14`
- Screenshot Needed: `Progress dashboard screen`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin is logged in |
| 2 | At least one child profile exists |
| 3 | At least one session record exists |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Child with existing activity sessions |

**Test Scenario**

Verify that the admin can view child progress, session history, and performance summary.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Progress` for a child from dashboard | Progress screen opens | As expected | Pass |
| 2 | Observe trend chart and module breakdown | Progress charts and module summary are displayed | As expected | Pass |
| 3 | Observe session history list | Session records are listed correctly | As expected | Pass |

---

## TC_012 - Vocabulary Customisation

- Test Case ID: `TC_012`
- Version: `1.0`
- Test Case Title: `Vocabulary Customisation`
- Functional Requirement Covered: `FR15`
- Screenshot Needed: `Vocabulary manager + updated item`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin is logged in |
| 2 | Child profile exists |
| 3 | Vocab Manager is accessible |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | New word = `Banana` |
| 2 | Category = `Food` |
| 3 | Emoji = `🍌` |

**Test Scenario**

Verify that the admin can add or edit vocabulary items successfully.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Vocab Manager` for a child | Vocabulary manager opens | As expected | Pass |
| 2 | Click `Add Item` and enter valid vocab details | Form accepts vocab details | As expected | Pass |
| 3 | Save the new item | New vocabulary item appears in the list | As expected | Pass |
| 4 | Edit an existing item and save changes | Updated item is shown in the list | As expected | Pass |

---

## TC_013 - Difficulty Adjustment

- Test Case ID: `TC_013`
- Version: `1.0`
- Test Case Title: `Difficulty Adjustment`
- Functional Requirement Covered: `FR16`
- Screenshot Needed: `Difficulty setting + changed activity screen`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin is logged in |
| 2 | Child profile exists |
| 3 | Vocab Manager is accessible |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Initial mode = `2 choices` |
| 2 | Changed mode = `4 choices` |

**Test Scenario**

Verify that the admin can change activity difficulty and the child activity reflects the new setting.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Vocab Manager` for a child | Vocab manager opens | As expected | Pass |
| 2 | Change Q&A mode from `2 choices` to `4 choices` | New mode is saved | As expected | Pass |
| 3 | Launch the child’s vocab activity again | Activity now shows 4 answer choices instead of 2 | As expected | Pass |

---

## TC_014 - Speech Recording Review

- Test Case ID: `TC_014`
- Version: `1.0`
- Test Case Title: `Speech Recording Review`
- Functional Requirement Covered: `FR17`
- Screenshot Needed: `Recording review screen`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Admin is logged in |
| 2 | Child has completed at least one speech recording |
| 3 | Firebase upload completed successfully |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Score = `4 stars` |
| 2 | Comment = `Good effort` |

**Test Scenario**

Verify that the admin can review a child’s saved recording and add feedback.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open `Recording Review` for a child | Recording review screen opens | As expected | Pass |
| 2 | Play a saved recording | Recording audio plays successfully | As expected | Pass |
| 3 | Select star score and enter comment | Feedback input is accepted | As expected | Pass |
| 4 | Click `Save` | Feedback is saved and remains visible | As expected | Pass |

---

## TC_015 - Reward System

- Test Case ID: `TC_015`
- Version: `1.0`
- Test Case Title: `Reward System`
- Functional Requirement Covered: `FR18`
- Screenshot Needed: `Reward screen`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Child session is active |
| 2 | Child can complete vocab or speech activity |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Complete one full vocab or speech session |

**Test Scenario**

Verify that stars or badges are awarded after the child completes an activity.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Complete a full child activity session | Reward screen opens | As expected | Pass |
| 2 | Observe stars and total reward count | Star reward is added successfully | As expected | Pass |
| 3 | Check whether a badge appears when milestone is reached | Badge is displayed if threshold is met | As expected | Pass |

---

## TC_016 - Firebase Data Storage

- Test Case ID: `TC_016`
- Version: `1.0`
- Test Case Title: `Firebase Data Storage`
- Functional Requirement Covered: `FR19`
- Screenshot Needed: `Firestore/Firebase Storage screenshot`

**Prerequisites**

| S # | Prerequisites |
|---|---|
| 1 | Multiple test cases above have been executed |
| 2 | Firebase Console access is available |

**Test Data**

| S # | Test Data |
|---|---|
| 1 | Firestore collections = `users`, `children`, `sessions`, `recordings`, `rewards` |
| 2 | Storage folder = `recordings/{childId}` |

**Test Scenario**

Verify that application data is stored correctly in Firebase Firestore and Storage.

| Step # | Step Details | Expected | Actual Results | Pass / Fail / Not |
|---|---|---|---|---|
| 1 | Open Firestore and check user, child, vocab, session, recording, and reward data | Relevant documents are stored in the correct collections | As expected | Pass |
| 2 | Open Firebase Storage and check uploaded speech recording file | Recording file exists in the correct storage path | As expected | Pass |

---

## Suggested Screenshot Order

1. Registration success
2. Dashboard after login
3. Add Child form / generated code
4. AAC board
5. AAC sentence bar
6. Vocab learning screen
7. 4-choice guided question
8. 2-choice simplified activity
9. Speech recording screen
10. Completed activity + Firestore session
11. Progress dashboard
12. Vocab Manager updated item
13. Q&A mode change + changed activity layout
14. Recording Review with score/comment
15. Reward screen
16. Firestore / Storage evidence
