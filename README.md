# Local Storage Lab — Activity 09 (Part II)

Will Davis | CSC 4360 | Undergraduate pathway

Repository: https://github.com/williammadisondavis/local_storage_lab
Working branch: `activity09-local-storage-part2`

## Project overview

This Flutter Android project extends In-Class Activity 08's Fall Festival Roster into a card catalogue using `sqflite`. The original guest roster is still available from the Guests tab. The new Folders tab lets users add or delete folders, see each folder's card count, and open a folder to add, edit, or delete its cards. The Add/Edit form validates a title, suit, and folder. Cards use an optional `image_ref` and show a suit symbol when no image can be displayed.

## Database and migration

- Existing database file: `MyDatabase.db` (same path/name as Activity 08).
- Original table: `my_table` with `_id`, `name`, and `age`.
- Schema upgraded from 1 to 2 using `onUpgrade` without dropping `my_table`.
- `onCreate` creates both the guest and catalogue schema for new installations.
- `folders(id, name UNIQUE, created_at)` is the parent table.
- `cards(id, title, suit, notes, image_ref, folder_id)` is the child table.
- `cards.folder_id` references `folders.id` with `ON DELETE CASCADE`.
- `idx_cards_folder_id` speeds up card lookups by folder.
- `PRAGMA foreign_keys = ON` is set during `onConfigure`.
- Typed classes: `lib/models/folder.dart`, `lib/models/card_record.dart`.
- Database operations are in `lib/database_helper.dart`; UI stays in the page widgets.
- ID-based update and delete methods use SQL parameter bindings (`whereArgs`).

The alternative to CASCADE would be `RESTRICT` or archiving/reassignment when child records must be retained, such as medical or billing records.

## Setup and run

Requirements: Flutter and an Android emulator/device. Flutter package dependencies are declared in `pubspec.yaml` and resolved in `pubspec.lock`.

```bash
flutter pub get
flutter analyze
flutter run -d <android-device-id>
flutter build apk --release
```

The release output is normally `build/app/outputs/flutter-apk/app-release.apk`.

## Activity 09 test results — observed

| Test | Action | Expected | Observed | Result |
| --- | --- | --- | --- | --- |
| T1a | Upgrade existing Android install from database v1 to v2 | Keep original guest rows, create new tables/index, enable foreign keys | `user_version=2`; `foreign_keys=1`; `my_table`, `folders`, and `cards` exist; index `idx_cards_folder_id`; FK delete rule `CASCADE`; original guests River (2,35), Acorn (3,0), Oak (4,130) unchanged | PASS |
| T1b | Fresh installation on separate Google Pixel phone | New installation initializes database and opens catalogue | Fresh installation and catalogue functionality worked on the Pixel, as tested on the device | PASS |
| T2 | Create Atlas and Harbor; add two Compass cards to Atlas and Signal to Harbor | Distinct IDs, correct folder membership and counts | Atlas folder ID 1 had cards Compass/Hearts ID 1 and Compass/Spades ID 2; Harbor folder ID 2 had Signal/Clubs ID 3; counts 2 and 1 | PASS |
| T3 | Edit Compass/Hearts by ID, cancel editing Compass/Spades | Only selected card changes; cancel writes nothing | ID 1 became `Compass revised` with notes `Updated during T3 testing`; ID 2 remained `Compass`; counts stayed 2 and 1 | PASS |
| T4 | Force-stop and reopen the same Android installation without clearing storage | Same IDs, values, counts; no duplicate entries | Atlas 1 (2 cards), Harbor 2 (1 card), card IDs 1/2/3 unchanged; original guests remained | PASS |
| T5 | Cancel then confirm card deletion; cancel then confirm Atlas folder deletion | Cancel leaves data intact; deleting card removes 1; folder cascade removes remaining Atlas card but not Harbor | Compass/Spades ID 2 removed individually; Atlas ID 1 and Compass revised ID 1 removed by cascade; Harbor ID 2 and Signal ID 3 remained | PASS |
| T6 | Display Signal without image; reject whitespace-only title, blank folder name and duplicate Harbor name | Suit placeholder displays; invalid inputs create no records | Signal showed Clubs symbol, invalid entries were rejected, Harbor and its one card remained | PASS |

The emulator's migration diagnostic log was captured from `getDatabaseDiagnostics()` in `lib/database_helper.dart`. T1b used a separate physical Google Pixel Android phone. T4 was a genuine stop/relaunch, not a hot reload.

## Evidence

- `evidence/T1_before.png`: Activity 08 original guest records before the migration.
- `evidence/T2_cards.png`: folder/card state after parent-child creation.
- `evidence/T2_atlas.png`: supplementary view of duplicate-title cards.
- `evidence/T4_after.png`: saved state after cold restart.
- `evidence/analysis_output.txt`: complete output from `flutter analyze` (generated locally).

These screenshots support the test log recorded above.

## Image handling and limitations

`image_ref` is nullable. The app accepts a bundled `assets/...` path or an HTTP(S) URL and displays a suit-symbol fallback if the reference is empty or cannot load. No image bytes are stored in SQLite. Remote images depend on network availability; bundled assets must be registered in `pubspec.yaml`. The project does not include gallery picking, cloud backup, or authentication because these are outside the core lab scope.

## Project files

- `lib/main.dart`: application startup and Folders/Guests navigation.
- `lib/guest_roster.dart`: preserved Activity 08 guest CRUD screen.
- `lib/database_helper.dart`: versioned schema, migration, diagnostics and database methods.
- `lib/models/folder.dart`, `lib/models/card_record.dart`: typed models.
- `lib/folders_page.dart`, `lib/cards_page.dart`: catalogue screens, validation and confirmations.

---

## Previous work — Activity 08 (Part I)

### Original project

Before Activity 09, I made a Fall Festival guest roster using Flutter and SQLite. Users could add, edit, and delete guests. Guest IDs, names, and ages were saved locally so they remained available after the app closed. The original roster screen is still accessible through the Guests tab in Activity 09.

### Activity 08 tests

| Test | What I tested | Observed result | Result |
| --- | --- | --- | --- |
| T1 | Opened the empty roster and pressed Refresh | Count 0 and an empty-roster message | PASS |
| T2 | Added River (21) and River (34) | IDs 1 and 2; count 2 | PASS |
| T3 | Canceled an edit to 99, then saved the second River as 35 | First River stayed 21; second River changed to 35; 1 row updated | PASS |
| T4 | Stopped and reopened the app | Both River records remained; count 2 | PASS |
| T5 | Canceled deletion, then deleted the first River | Only River ID 2 remained; count 1; 1 row deleted | PASS |
| T6 | Tested invalid inputs and age boundaries | Invalid entries rejected; Acorn (0) and Oak (130) accepted; final count 3 | PASS |

For T6, I tried a blank name and ages `abc`, `1.5`, `-1`, and `131`. None were accepted. I then added Acorn (ID 3, age 0) and Oak (ID 4, age 130), which brought the count to 3. These three remaining guests were the records used for Activity 09's migration-preservation test.

### Activity 08 screenshots

- `screenshots/T4_before.png` — guest records before the original restart.
- `screenshots/T4_after.png` — guest records after the original restart.
- `screenshots/T6_invalid.png` — invalid age/name input test.

### Activity 08 reflections

**1. The Disappearing-Data Mystery:** Before restarting, I expected both River records to stay saved because SQLite stores them on the device. Their IDs were 1 and 2, with ages 21 and 35. I reopened the app and checked the same records. `init()` opens the database, and `initState()` calls `_refreshGuests()`, which uses `queryAllRows()` and `queryRowCount()` to update the screen. If the IDs or ages had changed or disappeared, the stored data was not being read back correctly.

**2. Two Rivers, One Wrong Edit:** Both guests were named River, so using names alone could update the wrong record. I canceled an edit to age 99, then changed only River ID 2 from 34 to 35. One row updated, and River ID 1 remained age 21. The database helper uses the unique ID in its update query. Using a list position instead could cause problems if the list order changed.

**3. My Usability Walkthrough:** The Edit button filled the form with the selected guest's information, and Cancel Edit returned to the regular form. The deletion confirmation helped prevent accidental removal. Invalid names and ages displayed feedback, while ages 0 and 130 worked. One improvement I would make is a search bar for longer guest lists, although that would take extra code and screen space.

Activity 08 helped me understand how SQLite persists records and why I should use IDs instead of names or list positions. Activity 09 builds on that by adding related tables and a safe database upgrade.
