import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/firestore_service.dart';
import 'services/home_widget_service.dart';
import 'theme/app_colors.dart';

// window_manager/flutter_acrylic는 Windows 창 관리 전용 플러그인이라 Android에서는
// 지원되지 않는다. 바탕화면 위젯 모드 기능(§ANDROID_PORT_PLAN.md 1.1, 1.3)도 Windows 전용.
bool get _isDesktopWidgetHost => !kIsWeb && Platform.isWindows;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isDesktopWidgetHost) {
    await windowManager.ensureInitialized();
    // setSkipTaskbar 등 일부 기능은 내부적으로 taskbar COM 객체를 쓰는데,
    // 이 호출 없이는 그 객체가 초기화되지 않아 위젯 모드 진입 시 네이티브 크래시가 났다.
    await windowManager.waitUntilReadyToShow();
    await acrylic.Window.initialize();
  }

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

  await HomeWidgetService.registerBackgroundCallback();

  runApp(TodoApp(firebaseAvailable: firebaseAvailable));
}

class TodoApp extends StatelessWidget {
  final bool firebaseAvailable;
  const TodoApp({super.key, this.firebaseAvailable = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일 관리',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Malgun Gothic',
        scaffoldBackgroundColor: AppColors.dark.background,
      ),
      home: AuthGate(firebaseAvailable: firebaseAvailable),
    );
  }
}

// Firebase 연결 여부와 로그인 상태에 따라 로그인 화면/홈 화면을 전환한다.
class AuthGate extends StatelessWidget {
  final bool firebaseAvailable;

  const AuthGate({super.key, required this.firebaseAvailable});

  @override
  Widget build(BuildContext context) {
    if (!firebaseAvailable) {
      // Firebase 자체를 못 쓰는 상황(설정 미완료/오프라인) → 로컬 더미 데이터 모드
      return const HomeScreen(useFirebase: false);
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
          onLogout: () => FirebaseAuth.instance.signOut(),
        );
      },
    );
  }
}
