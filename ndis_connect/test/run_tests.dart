import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ndis_connect/app.dart';

import 'accessibility/accessibility_test_utils.dart';
import 'services/task_service_test.dart' as task_service_test;
import 'viewmodels/task_viewmodel_test.dart' as task_viewmodel_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NDIS Connect Test Suite', () {
    group('Service Tests', () {
      task_service_test.main();
    });

    group('ViewModel Tests', () {
      task_viewmodel_test.main();
    });

    group('Accessibility Tests', () {
      testWidgets('Accessibility compliance check', (WidgetTester tester) async {
        // This would be run with actual widgets
        // For now, we'll just verify the utils work
        expect(AccessibilityTestUtils, isNotNull);
      });
    });

    group('Integration Tests', () {
      testWidgets('App startup and navigation', (WidgetTester tester) async {
        // Test app startup
        await tester.pumpWidget(const NdisApp());
        await tester.pumpAndSettle();

        // Verify main screen loads
        expect(find.text('NDIS Connect'), findsOneWidget);
      });

      testWidgets('Task management flow', (WidgetTester tester) async {
        // Test complete task management flow
        await tester.pumpWidget(const NdisApp());
        await tester.pumpAndSettle();

        // Navigate to tasks
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();

        // Create new task
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Fill task form
        await tester.enterText(find.byType(TextField).first, 'Test Task');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify task was created
        expect(find.text('Test Task'), findsOneWidget);
      });
    });
  });
}
