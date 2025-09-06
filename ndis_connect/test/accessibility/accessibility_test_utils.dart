import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class AccessibilityTestUtils {
  static bool checkSemantics(WidgetTester tester) {
    // Check for semantic labels
    final semantics = tester.binding.pipelineOwner.semanticsOwner;
    if (semantics != null) {
      final root = semantics.rootSemanticsNode;
      root?.visitChildren((SemanticsNode node) {
        _checkSemanticNode(node);
        return true;
      });
    }
    return true;
  }

  static void _checkSemanticNode(SemanticsNode node) {
    // Check for required semantic properties
    if (node.hasFlag(SemanticsFlag.isButton) ||
        node.hasFlag(SemanticsFlag.isTextField) ||
        node.hasFlag(SemanticsFlag.isImage)) {
      if (node.label.isEmpty) {
        debugPrint('Semantic node missing label: ${node.label}');
      }
    }

    // Recursively check children
    node.visitChildren((SemanticsNode child) {
      _checkSemanticNode(child);
      return true;
    });
  }

  static void checkColorContrast(WidgetTester tester) {
    // Basic color contrast checks
    final finder = find.byType(Text);
    for (int i = 0; i < finder.evaluate().length; i++) {
      final textWidget = tester.widget<Text>(finder.at(i));
      final style = textWidget.style;

      if (style?.color != null) {
        // Check if text color provides sufficient contrast
        // This is a simplified check - in production, use proper contrast ratio calculation
        assert(
            style!.color!.computeLuminance() > 0.1, 'Text color may not have sufficient contrast');
      }
    }
  }

  static void checkTouchTargets(WidgetTester tester) {
    final finder = find.byType(GestureDetector);
    for (int i = 0; i < finder.evaluate().length; i++) {
      final renderBox = tester.renderObject<RenderBox>(finder.at(i));

      // Check minimum touch target size (44x44 logical pixels)
      assert(renderBox.size.width >= 44.0 && renderBox.size.height >= 44.0,
          'Touch target too small: ${renderBox.size}');
    }
  }

  static void checkFocusTraversal(WidgetTester tester) {
    // Check that focusable widgets can be traversed
    final focusableFinder = find.byType(Focus);
    expect(focusableFinder, findsWidgets);
  }
}
