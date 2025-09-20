import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/accessibility_widgets.dart';
import 'error_handling_service.dart';

/// Comprehensive accessibility audit service for WCAG 2.2 AA compliance
class AccessibilityAuditService {
  static final AccessibilityAuditService _instance = AccessibilityAuditService._internal();
  factory AccessibilityAuditService() => _instance;
  AccessibilityAuditService._internal();

  ErrorHandlingService? _errorHandler;
  SharedPreferences? _prefs;
  final List<AccessibilityIssue> _issues = [];

  bool _isInitialized = false;

  /// Initialize the accessibility audit service
  Future<void> initialize({ErrorHandlingService? errorHandler}) async {
    if (_isInitialized) return;

    _errorHandler = errorHandler;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPreviousAuditResults();
      _isInitialized = true;

      dev.log('Accessibility audit service initialized', name: 'AccessibilityAuditService');
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        context: {
          'operation': 'initialize',
          'service': 'AccessibilityAuditService',
        },
      );
    }
  }

  /// Run a comprehensive accessibility audit
  Future<AccessibilityAuditResult> runComprehensiveAudit({
    required BuildContext context,
    String? screenName,
  }) async {
    try {
      _issues.clear();

      final auditResult = AccessibilityAuditResult(
        screenName: screenName ?? 'Unknown Screen',
        timestamp: DateTime.now(),
        issues: [],
        score: 0,
        compliance: AccessibilityCompliance.unknown,
      );

      // Run all audit checks
      await _auditSemanticLabels(context, auditResult);
      await _auditColorContrast(context, auditResult);
      await _auditTouchTargets(context, auditResult);
      await _auditFocusManagement(context, auditResult);
      await _auditTextScaling(context, auditResult);
      await _auditKeyboardNavigation(context, auditResult);
      await _auditScreenReaderSupport(context, auditResult);
      await _auditMotorImpairmentSupport(context, auditResult);
      await _auditCognitiveAccessibility(context, auditResult);

      // Calculate overall score and compliance level
      _calculateAuditScore(auditResult);

      // Save audit results
      await _saveAuditResults(auditResult);

      return auditResult;
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        context: {
          'operation': 'run_comprehensive_audit',
          'screen': screenName ?? 'unknown',
          'service': 'AccessibilityAuditService',
        },
      );

      return AccessibilityAuditResult(
        screenName: screenName ?? 'Unknown Screen',
        timestamp: DateTime.now(),
        issues: [
          AccessibilityIssue(
            type: AccessibilityIssueType.other,
            severity: AccessibilityIssueSeverity.high,
            title: 'Audit Failed',
            description: 'Unable to complete accessibility audit',
            wcagCriteria: [],
            suggestion: 'Check app configuration and try again',
          ),
        ],
        score: 0,
        compliance: AccessibilityCompliance.failed,
      );
    }
  }

  /// Audit semantic labels
  Future<void> _auditSemanticLabels(BuildContext context, AccessibilityAuditResult result) async {
    try {
      // This would need to traverse the widget tree to find unlabeled interactive elements
      // For now, we'll create a placeholder implementation

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.semanticLabels,
        severity: AccessibilityIssueSeverity.medium,
        title: 'Missing Semantic Labels',
        description: 'Some interactive elements may be missing semantic labels for screen readers',
        wcagCriteria: ['1.3.1', '2.4.6', '4.1.2'],
        suggestion: 'Add semantic labels to all buttons, links, and interactive elements',
        elementCount: 0, // Would be calculated from actual audit
      );

      result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'semantic_labels'},
      );
    }
  }

  /// Audit color contrast
  Future<void> _auditColorContrast(BuildContext context, AccessibilityAuditResult result) async {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      final contrastIssues = <String>[];

      // Check primary text contrast
      if (!ColorContrastUtils.meetsWCAGAA(colorScheme.onSurface, colorScheme.surface)) {
        contrastIssues.add('Primary text on surface background');
      }

      // Check button contrast
      if (!ColorContrastUtils.meetsWCAGAA(colorScheme.onPrimary, colorScheme.primary)) {
        contrastIssues.add('Button text on primary background');
      }

      // Check error text contrast
      if (!ColorContrastUtils.meetsWCAGAA(colorScheme.onError, colorScheme.error)) {
        contrastIssues.add('Error text on error background');
      }

      if (contrastIssues.isNotEmpty) {
        final issue = AccessibilityIssue(
          type: AccessibilityIssueType.colorContrast,
          severity: AccessibilityIssueSeverity.high,
          title: 'Color Contrast Issues',
          description: 'Some color combinations do not meet WCAG AA contrast requirements (4.5:1)',
          wcagCriteria: ['1.4.3', '1.4.6'],
          suggestion: 'Adjust colors to meet minimum contrast ratio of 4.5:1 for normal text',
          details: contrastIssues,
        );

        result.issues.add(issue);
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'color_contrast'},
      );
    }
  }

  /// Audit touch target sizes
  Future<void> _auditTouchTargets(BuildContext context, AccessibilityAuditResult result) async {
    try {
      // This would need to measure actual widget sizes
      // For now, we'll create a placeholder implementation

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.touchTargets,
        severity: AccessibilityIssueSeverity.medium,
        title: 'Touch Target Size',
        description: 'Ensure all touch targets are at least 44x44 logical pixels',
        wcagCriteria: ['2.5.5'],
        suggestion: 'Increase touch target sizes to minimum 44x44 pixels',
        elementCount: 0, // Would be calculated from actual measurements
      );

      result.issues.add(issue);
      // Only add if there are actual issues
      // result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'touch_targets'},
      );
    }
  }

  /// Audit focus management
  Future<void> _auditFocusManagement(BuildContext context, AccessibilityAuditResult result) async {
    try {
      // Check if focus management is properly implemented
      final focusScope = FocusScope.of(context);

      if (focusScope.focusedChild == null) {
        final issue = AccessibilityIssue(
          type: AccessibilityIssueType.focusManagement,
          severity: AccessibilityIssueSeverity.low,
          title: 'Focus Management',
          description: 'Focus management should be implemented for keyboard navigation',
          wcagCriteria: ['2.4.3', '2.4.7'],
          suggestion: 'Implement proper focus order and visual focus indicators',
        );

        result.issues.add(issue);
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'focus_management'},
      );
    }
  }

  /// Audit text scaling support
  Future<void> _auditTextScaling(BuildContext context, AccessibilityAuditResult result) async {
    try {
      final mediaQuery = MediaQuery.of(context);
      final textScaler = mediaQuery.textScaler;

      // Check if text scaling is supported
      if (textScaler.scale(1.0) == 1.0) {
        // Text scaling might not be properly implemented
        final issue = AccessibilityIssue(
          type: AccessibilityIssueType.textScaling,
          severity: AccessibilityIssueSeverity.medium,
          title: 'Text Scaling Support',
          description: 'Text should scale properly up to 200% without loss of functionality',
          wcagCriteria: ['1.4.4'],
          suggestion: 'Ensure all text respects system text scaling settings',
        );
        result.issues.add(issue);

        // Only add if there are actual scaling issues
        // result.issues.add(issue);
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'text_scaling'},
      );
    }
  }

  /// Audit keyboard navigation
  Future<void> _auditKeyboardNavigation(
      BuildContext context, AccessibilityAuditResult result) async {
    try {
      // Check keyboard navigation implementation
      // This would typically involve testing focus traversal

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.keyboardNavigation,
        severity: AccessibilityIssueSeverity.medium,
        title: 'Keyboard Navigation',
        description: 'All functionality should be accessible via keyboard',
        wcagCriteria: ['2.1.1', '2.1.2'],
        suggestion: 'Implement full keyboard navigation support',
      );

      result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'keyboard_navigation'},
      );
    }
  }

  /// Audit screen reader support
  Future<void> _auditScreenReaderSupport(
      BuildContext context, AccessibilityAuditResult result) async {
    try {
      // Check screen reader compatibility
      // This would involve checking semantic properties

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.screenReader,
        severity: AccessibilityIssueSeverity.high,
        title: 'Screen Reader Support',
        description: 'Screen reader support should be comprehensive and accurate',
        wcagCriteria: ['1.3.1', '2.4.6', '4.1.2'],
        suggestion: 'Add proper semantic labels and descriptions for all content',
      );

      result.issues.add(issue);
      // result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'screen_reader'},
      );
    }
  }

  /// Audit motor impairment support
  Future<void> _auditMotorImpairmentSupport(
      BuildContext context, AccessibilityAuditResult result) async {
    try {
      // Check support for users with motor impairments
      // This includes touch target sizes, timing, and input methods

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.motorImpairment,
        severity: AccessibilityIssueSeverity.medium,
        title: 'Motor Impairment Support',
        description: 'Interface should accommodate users with motor impairments',
        wcagCriteria: ['2.5.1', '2.5.2', '2.5.5'],
        suggestion: 'Ensure large touch targets, no time limits, and alternative input methods',
      );

      result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'motor_impairment'},
      );
    }
  }

  /// Audit cognitive accessibility
  Future<void> _auditCognitiveAccessibility(
      BuildContext context, AccessibilityAuditResult result) async {
    try {
      // Check cognitive accessibility features
      // This includes clear navigation, consistent UI, error handling

      final issue = AccessibilityIssue(
        type: AccessibilityIssueType.cognitive,
        severity: AccessibilityIssueSeverity.medium,
        title: 'Cognitive Accessibility',
        description: 'Interface should be clear and easy to understand',
        wcagCriteria: ['3.2.3', '3.2.4', '3.3.1', '3.3.2'],
        suggestion: 'Provide clear navigation, consistent UI patterns, and helpful error messages',
      );

      result.issues.add(issue);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'audit_type': 'cognitive_accessibility'},
      );
    }
  }

  /// Calculate audit score and compliance level
  void _calculateAuditScore(AccessibilityAuditResult result) {
    if (result.issues.isEmpty) {
      result.score = 100;
      result.compliance = AccessibilityCompliance.wcagAAA;
      return;
    }

    int totalDeductions = 0;
    int criticalIssues = 0;
    int highIssues = 0;
    int mediumIssues = 0;
    int lowIssues = 0;

    for (final issue in result.issues) {
      switch (issue.severity) {
        case AccessibilityIssueSeverity.critical:
          criticalIssues++;
          totalDeductions += 25;
          break;
        case AccessibilityIssueSeverity.high:
          highIssues++;
          totalDeductions += 15;
          break;
        case AccessibilityIssueSeverity.medium:
          mediumIssues++;
          totalDeductions += 10;
          break;
        case AccessibilityIssueSeverity.low:
          lowIssues++;
          totalDeductions += 5;
          break;
      }
    }

    result.score = (100 - totalDeductions).clamp(0, 100);

    // Determine compliance level
    if (criticalIssues > 0 || highIssues > 3) {
      result.compliance = AccessibilityCompliance.nonCompliant;
    } else if (highIssues > 0 || mediumIssues > 5) {
      result.compliance = AccessibilityCompliance.wcagA;
    } else if (mediumIssues > 0 || lowIssues > 10) {
      result.compliance = AccessibilityCompliance.wcagAA;
    } else {
      result.compliance = AccessibilityCompliance.wcagAAA;
    }
  }

  /// Get accessibility recommendations based on audit results
  List<AccessibilityRecommendation> getRecommendations(AccessibilityAuditResult result) {
    final recommendations = <AccessibilityRecommendation>[];

    // Group issues by type and create recommendations
    final issuesByType = <AccessibilityIssueType, List<AccessibilityIssue>>{};
    for (final issue in result.issues) {
      issuesByType.putIfAbsent(issue.type, () => []).add(issue);
    }

    for (final entry in issuesByType.entries) {
      final type = entry.key;
      final issues = entry.value;

      recommendations.add(AccessibilityRecommendation(
        title: _getRecommendationTitle(type),
        description: _getRecommendationDescription(type),
        priority: _getRecommendationPriority(issues),
        estimatedEffort: _getEstimatedEffort(issues),
        wcagCriteria: issues.expand((i) => i.wcagCriteria).toSet().toList(),
        actionItems: issues.map((i) => i.suggestion).toList(),
      ));
    }

    return recommendations;
  }

  String _getRecommendationTitle(AccessibilityIssueType type) {
    switch (type) {
      case AccessibilityIssueType.semanticLabels:
        return 'Improve Semantic Labels';
      case AccessibilityIssueType.colorContrast:
        return 'Fix Color Contrast Issues';
      case AccessibilityIssueType.touchTargets:
        return 'Optimize Touch Target Sizes';
      case AccessibilityIssueType.focusManagement:
        return 'Enhance Focus Management';
      case AccessibilityIssueType.textScaling:
        return 'Improve Text Scaling Support';
      case AccessibilityIssueType.keyboardNavigation:
        return 'Implement Keyboard Navigation';
      case AccessibilityIssueType.screenReader:
        return 'Enhance Screen Reader Support';
      case AccessibilityIssueType.motorImpairment:
        return 'Improve Motor Impairment Support';
      case AccessibilityIssueType.cognitive:
        return 'Enhance Cognitive Accessibility';
      case AccessibilityIssueType.other:
        return 'Address Other Accessibility Issues';
    }
  }

  String _getRecommendationDescription(AccessibilityIssueType type) {
    switch (type) {
      case AccessibilityIssueType.semanticLabels:
        return 'Add meaningful labels and descriptions to all interactive elements for screen reader users.';
      case AccessibilityIssueType.colorContrast:
        return 'Ensure all text and important visual elements meet WCAG AA contrast requirements (4.5:1).';
      case AccessibilityIssueType.touchTargets:
        return 'Make all touch targets at least 44x44 logical pixels for users with motor impairments.';
      case AccessibilityIssueType.focusManagement:
        return 'Implement proper focus order and visual focus indicators for keyboard users.';
      case AccessibilityIssueType.textScaling:
        return 'Ensure all text scales properly up to 200% without loss of functionality.';
      case AccessibilityIssueType.keyboardNavigation:
        return 'Make all functionality accessible via keyboard without requiring mouse or touch.';
      case AccessibilityIssueType.screenReader:
        return 'Optimize content structure and labeling for screen reader users.';
      case AccessibilityIssueType.motorImpairment:
        return 'Provide alternatives for complex gestures and ensure no time-sensitive interactions.';
      case AccessibilityIssueType.cognitive:
        return 'Simplify navigation, provide clear instructions, and implement consistent UI patterns.';
      case AccessibilityIssueType.other:
        return 'Address miscellaneous accessibility issues to improve overall usability.';
    }
  }

  AccessibilityPriority _getRecommendationPriority(List<AccessibilityIssue> issues) {
    final hasCritical = issues.any((i) => i.severity == AccessibilityIssueSeverity.critical);
    final hasHigh = issues.any((i) => i.severity == AccessibilityIssueSeverity.high);

    if (hasCritical) return AccessibilityPriority.critical;
    if (hasHigh) return AccessibilityPriority.high;
    return AccessibilityPriority.medium;
  }

  String _getEstimatedEffort(List<AccessibilityIssue> issues) {
    final totalIssues = issues.length;

    if (totalIssues <= 2) return 'Low (1-2 hours)';
    if (totalIssues <= 5) return 'Medium (3-6 hours)';
    return 'High (1-2 days)';
  }

  /// Save audit results
  Future<void> _saveAuditResults(AccessibilityAuditResult result) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return;

      final resultsJson = jsonEncode(result.toMap());
      await prefs.setString('accessibility_audit_${result.screenName}', resultsJson);
      await prefs.setString('last_accessibility_audit', resultsJson);
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'save_audit_results'},
      );
    }
  }

  /// Load previous audit results
  Future<void> _loadPreviousAuditResults() async {
    try {
      final prefs = _prefs;
      if (prefs == null) return;

      final lastAuditJson = prefs.getString('last_accessibility_audit');
      if (lastAuditJson != null) {
        final lastAudit =
            AccessibilityAuditResult.fromMap(jsonDecode(lastAuditJson) as Map<String, dynamic>);

        dev.log('Loaded previous audit: ${lastAudit.screenName} - Score: ${lastAudit.score}',
            name: 'AccessibilityAuditService');
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': 'load_previous_audit_results'},
      );
    }
  }

  /// Generate accessibility report
  String generateAccessibilityReport(AccessibilityAuditResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Accessibility Audit Report');
    buffer.writeln('**Screen**: ${result.screenName}');
    buffer.writeln('**Date**: ${result.timestamp.toLocal()}');
    buffer.writeln('**Score**: ${result.score}/100');
    buffer.writeln('**Compliance Level**: ${result.compliance.name.toUpperCase()}');
    buffer.writeln();

    if (result.issues.isEmpty) {
      buffer.writeln('✅ **No accessibility issues found!**');
      buffer.writeln('This screen meets WCAG 2.2 AAA standards.');
    } else {
      buffer.writeln('## Issues Found (${result.issues.length})');
      buffer.writeln();

      for (final issue in result.issues) {
        buffer.writeln('### ${issue.title}');
        buffer.writeln('**Severity**: ${issue.severity.name.toUpperCase()}');
        buffer.writeln('**WCAG Criteria**: ${issue.wcagCriteria.join(', ')}');
        buffer.writeln('**Description**: ${issue.description}');
        buffer.writeln('**Suggestion**: ${issue.suggestion}');
        if (issue.details != null && issue.details!.isNotEmpty) {
          buffer.writeln('**Details**: ${issue.details!.join(', ')}');
        }
        buffer.writeln();
      }

      final recommendations = getRecommendations(result);
      if (recommendations.isNotEmpty) {
        buffer.writeln('## Recommendations');
        buffer.writeln();

        for (final rec in recommendations) {
          buffer.writeln('### ${rec.title}');
          buffer.writeln('**Priority**: ${rec.priority.name.toUpperCase()}');
          buffer.writeln('**Estimated Effort**: ${rec.estimatedEffort}');
          buffer.writeln('**Description**: ${rec.description}');
          buffer.writeln('**Action Items**:');
          for (final action in rec.actionItems) {
            buffer.writeln('- $action');
          }
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }
}

/// Accessibility audit result
class AccessibilityAuditResult {
  final String screenName;
  final DateTime timestamp;
  final List<AccessibilityIssue> issues;
  int score;
  AccessibilityCompliance compliance;

  AccessibilityAuditResult({
    required this.screenName,
    required this.timestamp,
    required this.issues,
    required this.score,
    required this.compliance,
  });

  Map<String, dynamic> toMap() {
    return {
      'screenName': screenName,
      'timestamp': timestamp.toIso8601String(),
      'issues': issues.map((i) => i.toMap()).toList(),
      'score': score,
      'compliance': compliance.name,
    };
  }

  factory AccessibilityAuditResult.fromMap(Map<String, dynamic> map) {
    return AccessibilityAuditResult(
      screenName: map['screenName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      issues: (map['issues'] as List<dynamic>)
          .map((i) => AccessibilityIssue.fromMap(i as Map<String, dynamic>))
          .toList(),
      score: map['score'] as int,
      compliance: AccessibilityCompliance.values.firstWhere((c) => c.name == map['compliance']),
    );
  }
}

/// Accessibility issue representation
class AccessibilityIssue {
  final AccessibilityIssueType type;
  final AccessibilityIssueSeverity severity;
  final String title;
  final String description;
  final List<String> wcagCriteria;
  final String suggestion;
  final int? elementCount;
  final List<String>? details;

  AccessibilityIssue({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.wcagCriteria,
    required this.suggestion,
    this.elementCount,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'wcagCriteria': wcagCriteria,
      'suggestion': suggestion,
      'elementCount': elementCount,
      'details': details,
    };
  }

  factory AccessibilityIssue.fromMap(Map<String, dynamic> map) {
    return AccessibilityIssue(
      type: AccessibilityIssueType.values.firstWhere((t) => t.name == map['type']),
      severity: AccessibilityIssueSeverity.values.firstWhere((s) => s.name == map['severity']),
      title: map['title'] as String,
      description: map['description'] as String,
      wcagCriteria: List<String>.from(map['wcagCriteria'] as List),
      suggestion: map['suggestion'] as String,
      elementCount: map['elementCount'] as int?,
      details: map['details'] != null ? List<String>.from(map['details'] as List) : null,
    );
  }
}

/// Accessibility recommendation
class AccessibilityRecommendation {
  final String title;
  final String description;
  final AccessibilityPriority priority;
  final String estimatedEffort;
  final List<String> wcagCriteria;
  final List<String> actionItems;

  AccessibilityRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedEffort,
    required this.wcagCriteria,
    required this.actionItems,
  });
}

/// Enums for accessibility audit
enum AccessibilityIssueType {
  semanticLabels,
  colorContrast,
  touchTargets,
  focusManagement,
  textScaling,
  keyboardNavigation,
  screenReader,
  motorImpairment,
  cognitive,
  other,
}

enum AccessibilityIssueSeverity {
  critical,
  high,
  medium,
  low,
}

enum AccessibilityCompliance {
  wcagAAA,
  wcagAA,
  wcagA,
  nonCompliant,
  unknown,
  failed,
}

enum AccessibilityPriority {
  critical,
  high,
  medium,
  low,
}
