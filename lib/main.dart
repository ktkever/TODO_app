import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/firestore_service.dart';
import 'theme/app_colors.dart';

const _darkModePrefKey = 'darkMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // setSkipTaskbar 등 일부 기능은 내부적으로 taskbar COM 객체를 쓰는데,
  // 이 호출 없이는 그 객체가 초기화되지 않아 위젯 모드 진입 시 네이티브 크래시가 났다.
  await windowManager.waitUntilReadyToShow();
  await acrylic.Window.initialize();

  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAvailable = true;
  } catch (e) {
    // Firebase 미설정 또는 네트워크 오류 → 로컬 더미 데이터로 실행
    debugPrint('Firebase 초기화 실패, 로컬 모드로 실행: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final initialDarkMode = prefs.getBool(_darkModePrefKey) ?? false;

  runApp(TodoApp(
    firebaseAvailable: firebaseAvailable,
    initialDarkMode: initialDarkMode,
  ));
}

class TodoApp extends StatefulWidget {
  final bool firebaseAvailable;
  final bool initialDarkMode;
  const TodoApp({
    super.key,
    this.firebaseAvailable = false,
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
      home: AuthGate(
        firebaseAvailable: widget.firebaseAvailable,
        isDarkMode: _isDarkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}

// Firebase 연결 여부와 로그인 상태에 따라 로그인 화면/홈 화면을 전환한다.
class AuthGate extends StatelessWidget {
  final bool firebaseAvailable;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const AuthGate({
    super.key,
    required this.firebaseAvailable,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseAvailable) {
      // Firebase 자체를 못 쓰는 상황(설정 미완료/오프라인) → 로컬 더미 데이터 모드
      return HomeScreen(
        useFirebase: false,
        isDarkMode: isDarkMode,
        onToggleDarkMode: onToggleDarkMode,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        FirestoreService.instance.bindUser(user.uid);
        return HomeScreen(
          key: ValueKey(user.uid),
          useFirebase: true,
          isDarkMode: isDarkMode,
          onToggleDarkMode: onToggleDarkMode,
          onLogout: () => FirebaseAuth.instance.signOut(),
        );
      },
    );
  }
}
