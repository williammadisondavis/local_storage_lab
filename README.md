
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


## Reflection Questions

### 1. The Disappearing-Data Mystery

Before restarting, I predicted both River records would stay saved because SQLite stores the information on the device. River A was ID 1, age 21, and River B was ID 2, age 35. The guest count was 2. I stopped the Flutter session, checked App info where Force stop was disabled, and reopened the app. I used T4_before.png and T4_after.png to compare the records. When the app starts, init() opens the database, then initState() calls _refreshGuests(), which uses queryAllRows() and queryRowCount() to display the records. If the IDs or ages changed or disappeared, that would mean the data wasn't restored correctly.

### 2. Two Rivers, One Wrong Edit

Both guests were named River, so using their names to edit records could change the wrong person. River A had ID 1 and was 21, while River B had ID 2 and was originally 34. I canceled an edit changing River B to 99, then saved the age as 35. The update was supposed to affect only one row, leaving River A unchanged. In main.dart, _saveGuest() calls helper.update(), which uses the ID to find the correct record. If I selected guests by their position in the list and then sorted the list differently, I might accidentally edit River A instead of River B.

### 3. My Usability Walkthrough

During testing, I noticed that pressing Edit filled in the guest's information automatically, and Cancel Edit returned to the regular form. The delete confirmation was useful because I could cancel before actually removing River A. When testing invalid inputs in T6, the form displayed validation errors for blank names and ages like abc, 1.5, -1, and 131. The expected count stayed at 1 during these attempts, and after adding Acorn age 0 and Oak age 130, the final count was 3. One improvement I would make is adding a search bar so it's easier to find guests. The downside is that it would add more code and take up more screen space.


## Code Check

I used flutter analyze to check the project.

Analyzer output is saved in evidence/analysis_output.txt.

Analyzer output:

"Analyzing local_storage_lab...                                  
No issues found! (ran in 1.9s)"

## Conclusion

This lab helped me understand how SQLite saves information compared to just using a regular Dart list. I also learned how to use IDs to update specific records and reload information from the database.
