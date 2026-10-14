import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'guest_roster.dart' as original;
import 'folders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();

    final diagnostics = await helper.getDatabaseDiagnostics();
    debugPrint('ACTIVITY 09 DATABASE CHECK: $diagnostics');

    runApp(Activity09App(helper: helper));
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Could not open local storage.')),
        ),
      ),
    );
  }
}

class Activity09App extends StatelessWidget {
  final DatabaseHelper helper;

  const Activity09App({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Storage Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: HomePage(helper: helper),
    );
  }
}

class HomePage extends StatefulWidget {
  final DatabaseHelper helper;

  const HomePage({super.key, required this.helper});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FoldersPage(helper: widget.helper),
          original.RosterPage(helper: widget.helper),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Folders',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Guests',
          ),
        ],
      ),
    );
  }
}
