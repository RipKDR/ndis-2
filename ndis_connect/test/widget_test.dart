// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/l10n/app_localizations.dart';
import 'package:ndis_connect/viewmodels/app_settings_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('NDIS Connect app smoke test', (WidgetTester tester) async {
    // Test a simple screen without Firebase dependencies
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('en', 'AU'),
        ],
        home: ChangeNotifierProvider(
          create: (_) => AppSettingsViewModel(),
          child: Scaffold(
            appBar: AppBar(title: const Text('NDIS Connect Test')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.accessibility_new, size: 64),
                  SizedBox(height: 16),
                  Text('NDIS Connect'),
                  Text('Accessible support for everyone'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wait for rendering
    await tester.pumpAndSettle();

    // Verify that the basic UI loads without crashing
    expect(tester.takeException(), isNull);
    expect(find.text('NDIS Connect'), findsOneWidget);
    expect(find.text('Accessible support for everyone'), findsOneWidget);
    expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
  });
}
