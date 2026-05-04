import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:hevy_app/app/app.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/main.dart';

Widget testApp(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const App(),
  );
}

void main() {
  testWidgets('App renders home tab', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(testApp(db));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsOneWidget);

    // Close DB asynchronously outside fake async to avoid pending timer.
    await tester.runAsync(() => db.close());
  });

  testWidgets('Bottom nav shows 4 tabs', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(testApp(db));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.runAsync(() => db.close());
  });
}
