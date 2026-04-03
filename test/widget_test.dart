import 'package:adscloneia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: Text('adscloneia')),
        ),
      ),
    );
    expect(find.text('adscloneia'), findsOneWidget);
  });
}
