import 'package:flutter_test/flutter_test.dart';
import 'package:lp_app/main.dart';

void main() {
  testWidgets('App renders with bottom navigation', (tester) async {
    await tester.pumpWidget(const LpApp());

    expect(find.text('LP Calculator'), findsOneWidget);
    expect(find.text('LP Calc'), findsOneWidget);
    expect(find.text('Turns'), findsOneWidget);
    expect(find.text('Memo'), findsOneWidget);
  });
}
