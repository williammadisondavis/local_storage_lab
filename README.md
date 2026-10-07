
# In-Class 08 - Local Storage Lab

## About the Project

For this lab, I made a Fall Festival guest roster using Flutter and SQLite. The app lets users add, edit, and delete guests. It also saves the guest information so it doesn't disappear when the app closes.

I used main.dart for the app interface and database_helper.dart for the database. The database stores each guest's ID, name, and age.

## Testing

| Test | What I Tested | Expected Result |
|---|---|---|
| T1 | Opened the empty roster and pressed Refresh | Count 0 |
| T2 | Added River (21) and River (34) | Two guests with separate IDs, count 2 |
| T3 | Canceled an edit to 99, then saved River B as 35 | River A stays 21, River B becomes 35 |
| T4 | Stopped the app and reopened it | Both River records still saved, count 2 |
| T5 | Canceled deletion, then deleted River A | Only River B remains, count 1 |
| T6 | Tested invalid inputs and boundary ages | Invalid entries rejected, final count 3 |

For T6, I tried a blank name and the ages abc, 1.5, -1, and 131. These should all be rejected. I also added Acorn with age 0 and Oak with age 130 to test the lowest and highest allowed ages.

## Screenshots

T4 before restart: screenshots/T4_before.png

T4 after restart: screenshots/T4_after.png

T6 invalid input: screenshots/T6_invalid.png

## Reflection Questions

### 1. The Disappearing-Data Mystery

Before restarting the app, I predicted both River records would stay saved because SQLite stores information on the device. River A was 21 and River B was 35, with a total of 2 guests. I stopped the Flutter session and checked the app settings, where Force stop was already disabled, then reopened the app. The before and after screenshots are my evidence for the restart test.

When the app starts, init() opens the database. Then initState() calls the loading function, which uses queryAllRows() and queryRowCount() to display the saved guests. If the records disappeared or had different IDs after restarting, that would go against my prediction.

### 2. Two Rivers, One Wrong Edit

Since both guests had the same name, the app uses their unique IDs instead of their names when editing. On a fresh database, River A would get ID 1 and River B would get ID 2. I tested changing River B's age to 99 and canceling the edit, then saving the age as 35. The expected result was one updated row, with River A still age 21. This shows why using IDs is better than using names to identify records.

### 3. My Usability Walkthrough

I tested adding guests, editing their ages, deleting records, and entering invalid information. The form checks for blank names and only accepts whole-number ages from 0 to 130. The delete confirmation is also useful because it prevents accidentally removing someone. One thing I would improve is adding a search bar so finding a guest would be easier if the roster got really long.

## Code Check

I used flutter analyze to check the project.

Analyzer output is saved in evidence/analysis_output.txt.

## Conclusion

This lab helped me understand how SQLite saves information compared to just using a regular Dart list. I also learned how to use IDs to update specific records and reload information from the database.
