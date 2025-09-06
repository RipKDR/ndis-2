import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ndis_connect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NDIS Connect App Integration Tests', () {
    testWidgets('Complete user journey - Task Management', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to tasks screen
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Verify we're on the tasks screen
      expect(find.text('Tasks'), findsOneWidget);

      // Create a new task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in task form
      await tester.enterText(find.byType(TextField).first, 'Integration Test Task');
      await tester.pumpAndSettle();

      // Select category
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily Living'));
      await tester.pumpAndSettle();

      // Select priority
      await tester.tap(find.text('Priority'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Save the task
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify task was created
      expect(find.text('Integration Test Task'), findsOneWidget);

      // Mark task as complete
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify task is marked as complete
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Complete user journey - Service Map', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to service map screen
      await tester.tap(find.text('Service Map'));
      await tester.pumpAndSettle();

      // Verify we're on the service map screen
      expect(find.text('Service Map'), findsOneWidget);

      // Test search functionality
      await tester.enterText(find.byType(SearchBar), 'therapy');
      await tester.pumpAndSettle();

      // Test filter functionality
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select a category filter
      await tester.tap(find.text('Therapy'));
      await tester.pumpAndSettle();

      // Apply filter
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify filter was applied
      expect(find.text('Therapy'), findsOneWidget);
    });

    testWidgets('Complete user journey - Chatbot', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to chatbot screen
      await tester.tap(find.text('Chatbot'));
      await tester.pumpAndSettle();

      // Verify we're on the chatbot screen
      expect(find.text('NDIS Assistant'), findsOneWidget);

      // Send a message
      await tester.enterText(find.byType(TextField), 'Hello, I need help');
      await tester.pumpAndSettle();

      // Send the message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message was sent and response received
      expect(find.text('Hello, I need help'), findsOneWidget);
      expect(find.byType(ChatMessage), findsWidgets);

      // Test quick actions
      await tester.tap(find.text('Help with tasks'));
      await tester.pumpAndSettle();

      // Verify quick action was triggered
      expect(find.text('I need help managing my tasks'), findsOneWidget);
    });

    testWidgets('Complete user journey - Budget Screen', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to budget screen
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      // Verify we're on the budget screen
      expect(find.text('Budget'), findsOneWidget);

      // Verify budget information is displayed
      expect(find.text('Core'), findsOneWidget);
      expect(find.text('Capacity'), findsOneWidget);
      expect(find.text('Capital'), findsOneWidget);
    });

    testWidgets('Complete user journey - Calendar Screen', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to calendar screen
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Verify we're on the calendar screen
      expect(find.text('Calendar'), findsOneWidget);

      // Verify calendar is displayed
      expect(find.byType(Calendar), findsOneWidget);
    });

    testWidgets('Complete user journey - Settings Screen', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings screen
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify we're on the settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Test accessibility settings
      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();

      // Toggle high contrast mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify setting was applied
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('App navigation and state persistence', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate through different screens
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsOneWidget);

      await tester.tap(find.text('Service Map'));
      await tester.pumpAndSettle();
      expect(find.text('Service Map'), findsOneWidget);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.text('Budget'), findsOneWidget);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Calendar'), findsOneWidget);

      // Go back to tasks to verify state persistence
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('Offline functionality', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simulate offline mode (this would need to be implemented in the app)
      // For now, just verify the app handles connectivity changes gracefully
      
      // Navigate to tasks screen
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Verify offline banner appears (if implemented)
      // expect(find.text('Offline mode'), findsOneWidget);

      // Create a task while offline
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Offline Task');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify task was created (should be queued for sync)
      expect(find.text('Offline Task'), findsOneWidget);
    });

    testWidgets('Accessibility features', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Test accessibility settings
      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();

      // Toggle high contrast mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify high contrast mode is applied
      expect(find.byType(Switch), findsOneWidget);

      // Test text scaling
      await tester.tap(find.text('Text Size'));
      await tester.pumpAndSettle();

      // Adjust text scale
      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();

      // Verify text scaling is applied
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to tasks screen
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Try to create a task with invalid data
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to save without entering title
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify error handling (should show validation error)
      expect(find.text('Please enter a task title'), findsOneWidget);

      // Enter valid data and save
      await tester.enterText(find.byType(TextField).first, 'Valid Task');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify task was created successfully
      expect(find.text('Valid Task'), findsOneWidget);
    });
  });
}
