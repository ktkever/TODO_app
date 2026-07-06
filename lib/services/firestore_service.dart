import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/task.dart';

// 로그인한 계정별 Firestore CRUD 서비스.
// users/{uid}/ 경로에 저장하며, uid는 로그인 성공 후 bindUser로 지정한다.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  String? _uid;

  // 로그인 성공 시 호출 — 이후 모든 CRUD가 이 uid 아래 경로를 사용한다.
  void bindUser(String uid) {
    _uid = uid;
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

  Future<void> addCategory(Category category) async {
    await _categories.doc(category.id).set(category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    await _categories.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
  }
}
