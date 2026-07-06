import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/task.dart';

// 단일 사용자 데스크톱 앱을 위한 Firestore CRUD 서비스.
// 익명 인증으로 설치별 UID를 발급받아 users/{uid}/ 경로에 데이터를 저장.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  bool _available = false;
  String? _uid;

  bool get isAvailable => _available;

  // Firebase 초기화 성공 시 호출
  Future<void> init() async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      _available = _uid != null;
    } catch (e) {
      debugPrint('FirestoreService.init 실패: $e');
      _available = false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _tasks =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _categories =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('categories');

  // ── 할 일 스트림 ──────────────────────────────────────────────

  Stream<List<Task>> watchTasks() {
    return _tasks.orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map((d) => Task.fromMap(d.data())).toList(),
        );
  }

  // ── 카테고리 스트림 ───────────────────────────────────────────

  Stream<List<Category>> watchCategories() {
    return _categories.orderBy('order').snapshots().map(
          (snap) => snap.docs.map((d) => Category.fromMap(d.data())).toList(),
        );
  }

  // ── 할 일 CRUD ────────────────────────────────────────────────

  Future<void> addTask(Task task) async {
    final data = task.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();
    await _tasks.doc(task.id).set(data);
  }

  Future<void> updateTask(Task task) async {
    await _tasks.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }

  // ── 카테고리 CRUD ─────────────────────────────────────────────

  Future<void> addCategory(Category category, {int order = 999}) async {
    final data = category.toMap()..['order'] = order;
    await _categories.doc(category.id).set(data);
  }

  Future<void> updateCategory(Category category) async {
    await _categories.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
  }

  // ── 첫 실행 시 더미 데이터 시드 ───────────────────────────────

  Future<void> seedIfEmpty(
    List<Task> tasks,
    List<Category> categories,
  ) async {
    final existing = await _tasks.limit(1).get();
    if (existing.docs.isNotEmpty) return; // 이미 데이터 있음

    // 카테고리 시드
    for (int i = 0; i < categories.length; i++) {
      await addCategory(categories[i], order: i);
    }
    // 할 일 시드
    for (final task in tasks) {
      await addTask(task);
    }
  }
}
