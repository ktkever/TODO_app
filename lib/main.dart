import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';
import 'theme/app_colors.dart';

const _darkModePrefKey = 'darkMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirestoreService.instance.init();
    firebaseReady = FirestoreService.instance.isAvailable;
  } catch (e) {
    // Firebase 미설정 또는 네트워크 오류 → 로컬 더미 데이터로 실행
    debugPrint('Firebase 초기화 실패, 로컬 모드로 실행: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final initialDarkMode = prefs.getBool(_darkModePrefKey) ?? false;

  runApp(TodoApp(useFirebase: firebaseReady, initialDarkMode: initialDarkMode));
}

class TodoApp extends StatefulWidget {
  final bool useFirebase;
  final bool initialDarkMode;
  const TodoApp({
    super.key,
    this.useFirebase = false,
    this.initialDarkMode = false,
  });

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _toggleDarkMode() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModePrefKey, _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일 관리',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
        fontFamily: 'Malgun Gothic',
        scaffoldBackgroundColor: AppColors.light.background,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Malgun Gothic',
        scaffoldBackgroundColor: AppColors.dark.background,
      ),
      home: HomeScreen(
        useFirebase: widget.useFirebase,
        isDarkMode: _isDarkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}
