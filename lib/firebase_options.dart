// ⚠️ 이 파일은 자리표시자입니다.
// Firebase 연동 전 아래 단계를 완료하세요:
//   1. Firebase Console(console.firebase.google.com)에서 프로젝트 생성
//   2. 터미널에서 `dart pub global activate flutterfire_cli` 실행
//   3. `flutterfire configure` 실행 → 이 파일이 실제 값으로 교체됩니다
//
// 그 전까지 앱은 로컬 더미 데이터로 동작합니다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _placeholder;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return _placeholder;
      default:
        return _placeholder;
    }
  }

  // flutterfire configure 실행 후 실제 값으로 교체됩니다
  static const FirebaseOptions _placeholder = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: 'PLACEHOLDER_APP_ID',
    messagingSenderId: 'PLACEHOLDER_SENDER_ID',
    projectId: 'PLACEHOLDER_PROJECT_ID',
  );
}
