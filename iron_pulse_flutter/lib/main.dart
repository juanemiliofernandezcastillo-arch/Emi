import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'app_theme.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'store.dart';
import 'screens/dashboard_screen.dart';
import 'screens/active_log_screen.dart';
import 'screens/routines_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/rest_timer.dart';
import 'services/supabase_auth_service.dart';
import 'services/profile_service.dart';
import 'models.dart';
import 'screens/admin_dashboard_screen.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://vhptzwqlsblzwcjxynzd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZocHR6d3Fsc2Jsendjanh5bnpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2NTk5MDYsImV4cCI6MjA5NTIzNTkwNn0.8htIk7N9b6oTIbpcC5oVC4F_X88Xue-xUTmOsbzsRWU',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutStore(),
      child: const IronPulseApp(),
    ),
  );
}

class IronPulseApp extends StatelessWidget {
  const IronPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iron Pulse',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: CyberTheme.cyberTeal)));
        }
        
        final session = snapshot.data?.session;
        if (session != null) {
          return FutureBuilder<Profile?>(
            future: ProfileService().getCurrentProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: CyberTheme.cyberTeal)));
              }
              
              final role = profileSnapshot.data?.role ?? UserRole.client;
              if (role == UserRole.admin) {
                return const AdminDashboardScreen();
              } else {
                return const HomePage();
              }
            },
          );
        }
        return const LoginPage();
      },
    );
  }
}
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentTabIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();

    if (!store.initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: CyberTheme.cyberTeal),
        ),
      );
    }

    // Screens list
    final List<Widget> screens = [
      DashboardScreen(onTabChange: _onTabChange),
      const ActiveLogScreen(),
      RoutinesScreen(onTabChange: _onTabChange),
      const ExercisesScreen(),
      const HistoryScreen(),
    ];

    // Titles matching indices
    final List<String> titles = [
      "IRON PULSE",
      "ACTIVE LOG",
      "ROUTINES",
      "EXERCISES",
      "HISTORY"
    ];

    final hasActiveWorkout = store.activeWorkout != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentTabIndex],
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: CyberTheme.textSecondary),
            tooltip: "Settings",
            onPressed: () => _showSettingsDialog(context, store),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Current Active Tab
          IndexedStack(
            index: _currentTabIndex,
            children: screens,
          ),
          
          // Floating overlay Rest Timer
          const RestTimerWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabChange,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: CyberTheme.cyberTeal),
            label: 'Pulse',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.fitness_center_outlined),
                if (hasActiveWorkout)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: CyberTheme.neonRose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  )
              ],
            ),
            activeIcon: Icon(Icons.fitness_center, color: CyberTheme.cyberTeal),
            label: 'Log',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment, color: CyberTheme.cyberTeal),
            label: 'Routines',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books, color: CyberTheme.cyberTeal),
            label: 'Library',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: CyberTheme.cyberTeal),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WorkoutStore store) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: CyberTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: CyberTheme.borderTranslucent),
              ),
              title: const Text(
                "USER PREFERENCES",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unit settings selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Weight Unit", style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'kg', label: Text("KG")),
                          ButtonSegment(value: 'lbs', label: Text("LBS")),
                        ],
                        selected: {store.weightUnit},
                        onSelectionChanged: (val) {
                          store.updateSettings(unit: val.first);
                          setDialogState(() {});
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: CyberTheme.cyberTeal.withOpacity(0.15),
                          selectedForegroundColor: CyberTheme.cyberTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timer Sound alerts settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Rest Timer Audio", style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: store.soundEnabled,
                        activeColor: CyberTheme.cyberTeal,
                        onChanged: (val) {
                          store.updateSettings(sound: val);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Default Rest Period
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Default Rest Period", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${store.defaultRestTime}s",
                            style: const TextStyle(color: CyberTheme.cyberTeal, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: store.defaultRestTime.toDouble(),
                        min: 30,
                        max: 300,
                        divisions: 9,
                        activeColor: CyberTheme.cyberTeal,
                        inactiveColor: CyberTheme.borderTranslucent,
                        onChanged: (val) {
                          store.updateSettings(restTime: val.toInt());
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await SupabaseAuthService().signOut();
                    if (context.mounted) {
                      Navigator.pop(context);
                      // Navegación handled automatically by StreamBuilder in IronPulseApp
                    }
                  },
                  child: const Text("SIGN OUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE"),
                )
              ],
            );
          },
        );
      },
    );
  }
}

