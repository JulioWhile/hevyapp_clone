import 'package:flutter_test/flutter_test.dart';
import 'package:hevy_app/app/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Basic smoke test — app should render without crashing.
    expect(find.text('Home'), findsWidgets);
  });
}
