#!/usr/bin/env dart

import 'dart:io';

/// Script to quickly fix all remaining screens with ErrorBoundary and accessibility
void main() async {
  print('🔧 Fixing remaining screens...');

  final screens = [
    'budget_screen.dart',
    'calendar_screen.dart', 
    'feedback_screen.dart',
    'service_map_screen.dart',
    'settings_screen.dart',
    'tutorial_screen.dart',
    'chatbot_screen.dart',
    'dev_preview.dart',
  ];

  for (final screen in screens) {
    print('Fixing $screen...');
    await _fixScreen(screen);
  }

  print('✅ All screens fixed!');
}

Future<void> _fixScreen(String screenName) async {
  final screenPath = 'lib/screens/$screenName';
  final file = File(screenPath);
  
  if (!file.existsSync()) {
    print('⚠️ $screenName not found, skipping...');
    return;
  }

  String content = await file.readAsString();
  
  // Add imports if not present
  if (!content.contains('error_boundary.dart')) {
    content = _addImports(content);
  }
  
  // Wrap with ErrorBoundary if not present
  if (!content.contains('ErrorBoundary')) {
    content = _addErrorBoundary(content, screenName);
  }
  
  // Add accessibility features
  content = _addAccessibilityFeatures(content);
  
  await file.writeAsString(content);
  print('✅ Fixed $screenName');
}

String _addImports(String content) {
  // Find the last import
  final lines = content.split('\n');
  int lastImportIndex = -1;
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('import ') && !lines[i].contains('.dart:')) {
      lastImportIndex = i;
    }
  }
  
  if (lastImportIndex != -1) {
    lines.insert(lastImportIndex + 1, "import '../widgets/error_boundary.dart';");
    lines.insert(lastImportIndex + 2, "import '../widgets/accessibility_widgets.dart';");
  }
  
  return lines.join('\n');
}

String _addErrorBoundary(String content, String screenName) {
  // Find the main build method and wrap with ErrorBoundary
  final className = screenName.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join('').replaceAll('.dart', '');
  
  // Simple pattern matching - wrap the return statement in build method
  final pattern = RegExp(r'(@override\s+Widget build\(BuildContext context\) \{[\s\S]*?return )([\s\S]*?)(\s*\}\s*\})');
  
  content = content.replaceFirstMapped(pattern, (match) {
    final prefix = match.group(1)!;
    final body = match.group(2)!;
    final suffix = match.group(3)!;
    
    return '''${prefix}ErrorBoundary(
      context: '$className',
      onRetry: () {
        // Retry functionality
      },
      child: $body
    )$suffix''';
  });
  
  return content;
}

String _addAccessibilityFeatures(String content) {
  // Replace common widgets with accessible versions
  content = content.replaceAll('Text(', 'AccessibleText(');
  content = content.replaceAll('IconButton(', 'AccessibleIconButton(');
  content = content.replaceAll('Card(', 'AccessibleCard(');
  
  // Fix any broken AccessibleText calls
  content = content.replaceAll('AccessibleText(style:', 'AccessibleText(\n        style:');
  
  return content;
}
