import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fomi/main.dart';

void main() {
  testWidgets('FOMI app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const FomiApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
