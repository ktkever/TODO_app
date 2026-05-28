import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';

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

  runApp(TodoApp(useFirebase: firebaseReady));
}

class TodoApp extends StatelessWidget {
  final bool useFirebase;
  const TodoApp({super.key, this.useFirebase = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일 관리',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0078D4)),
        fontFamily: 'Malgun Gothic',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomeScreen(useFirebase: useFirebase),
    );
  }
}
