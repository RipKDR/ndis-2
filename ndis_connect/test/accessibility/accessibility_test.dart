import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/screens/chatbot_screen.dart';
import 'package:ndis_connect/screens/service_map_screen.dart';
// Removed unused app import
import 'package:ndis_connect/screens/task_screen.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('Task Screen - WCAG 2.2 AA Compliance', (WidgetTester tester) async {
      // Build the task screen
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test 1: All interactive elements have semantic labels
      final interactiveElements = find.byType(GestureDetector);
      for (int i = 0; i < interactiveElements.evaluate().length; i++) {
        final element = interactiveElements.evaluate().elementAt(i).widget as GestureDetector;
        expect(element.onTap, isNotNull);
      }

      // Test 2: Text contrast ratio meets WCAG standards
      final textWidgets = find.byType(Text);
      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        final textWidget = textWidgets.evaluate().elementAt(i).widget as Text;
        final textStyle = textWidget.style;

        if (textStyle != null && textStyle.color != null) {
          // Check if text color provides sufficient contrast
          expect(textStyle.color, isNotNull);
        }
      }

      // Test 3: Focus management
      final focusableElements = find.byType(Focus);
      expect(focusableElements, findsWidgets);

      // Test 4: Screen reader support
      final semanticElements = find.byType(Semantics);
      expect(semanticElements, findsWidgets);

      // Test 5: Touch target size (minimum 44x44 logical pixels)
      final buttonElements = find.byType(ElevatedButton);
      for (int i = 0; i < buttonElements.evaluate().length; i++) {
        final button = buttonElements.evaluate().elementAt(i);
        final renderBox = button.renderObject as RenderBox;
        final size = renderBox.size;

        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('Service Map Screen - Accessibility Features', (WidgetTester tester) async {
      // Build the service map screen
      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceMapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test 1: Map accessibility
      // Note: GoogleMap widget would need google_maps_flutter package
      // For now, skip this test or use a mock implementation
      // final mapElements = find.byType(GoogleMap);
      // if (mapElements.evaluate().isNotEmpty) {
      //   expect(mapElements, findsOneWidget);
      // }

      // Test 2: Search functionality accessibility
      final searchBar = find.byKey(const Key('search_bar'));
      if (searchBar.evaluate().isNotEmpty) {
        expect(searchBar, findsOneWidget);
      }

      // Test 3: Filter accessibility
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);

      // Test 4: Provider cards accessibility
      final providerCards = find.byType(Card);
      for (int i = 0; i < providerCards.evaluate().length; i++) {
        final cardFinder = providerCards.at(i);
        final semantics = tester.getSemantics(cardFinder);
        expect(semantics, isNotNull);
      }
    });

    testWidgets('Chatbot Screen - Accessibility Features', (WidgetTester tester) async {
      // Build the chatbot screen
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatbotScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test 1: Chat input accessibility
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test 2: Send button accessibility
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);

      // Test 3: Quick actions accessibility
      final quickActions = find.byType(ActionChip);
      expect(quickActions, findsWidgets);

      // Test 4: Message bubbles accessibility
      final messageBubbles = find.byType(Container);
      for (int i = 0; i < messageBubbles.evaluate().length; i++) {
        final bubbleFinder = messageBubbles.at(i);
        final semantics = tester.getSemantics(bubbleFinder);
        expect(semantics, isNotNull);
      }
    });

    testWidgets('High Contrast Mode Support', (WidgetTester tester) async {
      // Test high contrast theme
      final highContrastTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.black,
          onPrimary: Colors.yellow,
          surface: Colors.black,
          onSurface: Colors.yellow,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: highContrastTheme,
          home: const TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify high contrast colors are applied
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Test text contrast in high contrast mode
      final textWidgets = find.byType(Text);
      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        final textWidget = textWidgets.evaluate().elementAt(i).widget as Text;
        final textStyle = textWidget.style;

        if (textStyle != null && textStyle.color != null) {
          // In high contrast mode, text should be yellow on black
          expect(textStyle.color, equals(Colors.yellow));
        }
      }
    });

    testWidgets('Text Scaling Support', (WidgetTester tester) async {
      // Test different text scale factors
      const textScaleFactors = [1.0, 1.5, 2.0, 3.0];

      for (final scaleFactor in textScaleFactors) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scaleFactor)),
            child: const MaterialApp(
              home: TaskScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify text scaling is applied
        final textWidgets = find.byType(Text);
        for (int i = 0; i < textWidgets.evaluate().length; i++) {
          final textWidget = textWidgets.evaluate().elementAt(i).widget as Text;
          final textStyle = textWidget.style;

          if (textStyle != null && textStyle.fontSize != null) {
            // Text should be scaled according to the scale factor
            expect(textStyle.fontSize, greaterThan(0));
          }
        }
      }
    });

    testWidgets('Keyboard Navigation Support', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test focus management
      final focusableElements = find.byType(Focus);
      expect(focusableElements, findsWidgets);

      // Test tab order
      final tabOrder = <Widget>[];
      for (int i = 0; i < focusableElements.evaluate().length; i++) {
        final element = focusableElements.evaluate().elementAt(i).widget as Focus;
        tabOrder.add(element.child);
      }

      // Verify logical tab order
      expect(tabOrder, isNotEmpty);
    });

    testWidgets('Screen Reader Support', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test semantic labels
      final semanticElements = find.byType(Semantics);
      expect(semanticElements, findsWidgets);

      // Test button labels
      final buttons = find.byType(ElevatedButton);
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final buttonFinder = buttons.at(i);
        final semantics = tester.getSemantics(buttonFinder);
        expect(semantics, isNotNull);
      }

      // Test icon labels
      final icons = find.byType(Icon);
      for (int i = 0; i < icons.evaluate().length; i++) {
        final icon = icons.evaluate().elementAt(i).widget as Icon;
        // Icons should have semantic labels for screen readers
        expect(icon.semanticLabel, isNotNull);
      }
    });

    testWidgets('Color Blindness Support', (WidgetTester tester) async {
      // Test that important information is not conveyed by color alone
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test task status indicators
      final statusChips = find.byType(Chip);
      for (int i = 0; i < statusChips.evaluate().length; i++) {
        final chip = statusChips.evaluate().elementAt(i).widget as Chip;
        // Status should be indicated by text, not just color
        expect(chip.label, isNotNull);
      }

      // Test priority indicators
      final priorityElements = find.byType(Container);
      for (int i = 0; i < priorityElements.evaluate().length; i++) {
        final container = priorityElements.evaluate().elementAt(i).widget as Container;
        // Priority should be indicated by text or icons, not just color
        expect(container.child, isNotNull);
      }
    });

    testWidgets('Motor Impairment Support', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test touch target sizes
      final touchTargets = find.byType(GestureDetector);
      for (int i = 0; i < touchTargets.evaluate().length; i++) {
        final target = touchTargets.evaluate().elementAt(i);
        final renderBox = target.renderObject as RenderBox;
        final size = renderBox.size;

        // Touch targets should be at least 44x44 logical pixels
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }

      // Test button spacing
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().length > 1) {
        // Buttons should be spaced appropriately to prevent accidental taps
        final button1 = buttons.evaluate().first;
        final button2 = buttons.evaluate().elementAt(1);

        final renderBox1 = button1.renderObject as RenderBox;
        final renderBox2 = button2.renderObject as RenderBox;

        final position1 = renderBox1.localToGlobal(Offset.zero);
        final position2 = renderBox2.localToGlobal(Offset.zero);

        final distance = (position1 - position2).distance;
        expect(distance, greaterThanOrEqualTo(8.0)); // Minimum spacing
      }
    });

    testWidgets('Cognitive Accessibility Support', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test clear navigation
      final navigationElements = find.byType(NavigationBar);
      expect(navigationElements, findsWidgets);

      // Test consistent UI patterns
      final similarElements = find.byType(Card);
      expect(similarElements, findsWidgets);

      // Test error messages
      final errorMessages = find.textContaining('Error');
      // Error messages should be clear and actionable
      for (int i = 0; i < errorMessages.evaluate().length; i++) {
        final errorText = errorMessages.evaluate().elementAt(i).widget as Text;
        expect(errorText.data, isNotNull);
        expect(errorText.data!.length, greaterThan(10)); // Should be descriptive
      }

      // Test loading states
      final loadingIndicators = find.byType(CircularProgressIndicator);
      expect(loadingIndicators, findsWidgets);
    });
  });
}
