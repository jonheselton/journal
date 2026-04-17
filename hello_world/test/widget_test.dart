import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_journal/main.dart';

void main() {
  testWidgets('App builds and shows auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NoteApp());
    // Auth screen should show the lock icon
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });
}
