import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/main.dart';

void main() {
  testWidgets('앱 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    expect(find.text('오늘 할일'), findsOneWidget);
  });
}
