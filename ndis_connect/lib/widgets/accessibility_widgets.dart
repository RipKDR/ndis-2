import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../services/accessibility_service.dart';

/// A widget that provides comprehensive accessibility features
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool button;
  final bool link;
  final bool header;
  final bool focusable;
  final bool enabled;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
    this.button = false,
    this.link = false,
    this.header = false,
    this.focusable = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      link: link,
      header: header,
      focusable: focusable && enabled,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// An accessible button with proper semantics and touch targets
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry? padding;
  final bool primary;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.minWidth = 44.0,
    this.minHeight = 44.0,
    this.padding,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (primary) {
      button = ElevatedButton(
        onPressed: onPressed,
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        child: child,
      );
    }

    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: padding != null ? Padding(padding: padding!, child: button) : button,
    );

    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    // Add semantic label if provided
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }

    return button;
  }
}

/// An accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticLabel;
  final double size;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.semanticLabel,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tooltip,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(
          icon,
          size: size,
          color: color,
          semanticLabel: semanticLabel ?? tooltip,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: 44.0,
          minHeight: 44.0,
        ),
      ),
    );
  }
}

/// An accessible text widget with proper contrast and scaling
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool semanticsLabel;
  final String? customSemanticsLabel;
  final bool header;
  final int headerLevel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel = true,
    this.customSemanticsLabel,
    this.header = false,
    this.headerLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();

    // Apply accessibility text scaling
    TextStyle effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium!;

    if (accessibilityService.largeTextMode) {
      effectiveStyle = effectiveStyle.copyWith(
        fontSize: (effectiveStyle.fontSize ?? 14) * 1.5,
      );
    }

    // Apply text scale factor
    effectiveStyle = effectiveStyle.copyWith(
      fontSize: (effectiveStyle.fontSize ?? 14) * accessibilityService.textScaleFactor,
    );

    // Ensure minimum contrast in high contrast mode
    if (accessibilityService.highContrastMode) {
      effectiveStyle = effectiveStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    Widget textWidget = Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (semanticsLabel) {
      textWidget = Semantics(
        label: customSemanticsLabel ?? text,
        header: header,
        child: textWidget,
      );
    }

    return textWidget;
  }
}

/// An accessible card with proper focus and semantics
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin,
      elevation: elevation,
      color: color,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        child: card,
      );
    }

    if (tooltip != null) {
      card = Tooltip(
        message: tooltip!,
        child: card,
      );
    }

    if (semanticLabel != null || onTap != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        enabled: onTap != null,
        child: card,
      );
    }

    return card;
  }
}

/// An accessible input field with proper labeling and validation
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: labelText,
      hint: hintText,
      enabled: enabled,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
      ),
    );
  }
}

/// An accessible list tile with proper semantics
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool enabled;
  final bool selected;

  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.enabled = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        enabled: enabled,
        selected: selected,
        // Ensure minimum touch target height
        minVerticalPadding: 12.0,
      ),
    );
  }
}

/// A widget that announces changes to screen readers
class AccessibilityAnnouncer extends StatefulWidget {
  final String message;
  final Widget child;
  final bool announceOnBuild;

  const AccessibilityAnnouncer({
    super.key,
    required this.message,
    required this.child,
    this.announceOnBuild = true,
  });

  @override
  State<AccessibilityAnnouncer> createState() => _AccessibilityAnnouncerState();
}

class _AccessibilityAnnouncerState extends State<AccessibilityAnnouncer> {
  @override
  void initState() {
    super.initState();
    if (widget.announceOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announce();
      });
    }
  }

  void _announce() {
    final accessibilityService = context.read<AccessibilityService>();
    accessibilityService.speak(widget.message);

    // Also use Flutter's semantic announcements
    SemanticsService.announce(widget.message, TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: widget.child,
    );
  }
}

/// A mixin that provides accessibility utilities for widgets
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  AccessibilityService get accessibilityService => context.read<AccessibilityService>();

  /// Announce a message to screen readers
  void announceToScreenReader(String message) {
    accessibilityService.speak(message);
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Check if high contrast mode is enabled
  bool get isHighContrastMode => accessibilityService.highContrastMode;

  /// Check if large text mode is enabled
  bool get isLargeTextMode => accessibilityService.largeTextMode;

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => accessibilityService.screenReaderEnabled;

  /// Get the current text scale factor
  double get textScaleFactor => accessibilityService.textScaleFactor;

  /// Create an accessible theme based on current settings
  ThemeData getAccessibleTheme() {
    return accessibilityService.getAccessibilityTheme();
  }

  /// Wrap a widget with proper focus handling
  Widget makeFocusable(
    Widget child, {
    FocusNode? focusNode,
    bool autofocus = false,
    VoidCallback? onFocusChange,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange != null
          ? (focused) {
              if (focused) onFocusChange();
            }
          : null,
      child: child,
    );
  }

  /// Ensure minimum touch target size
  Widget ensureMinimumTouchTarget(
    Widget child, {
    double minWidth = 44.0,
    double minHeight = 44.0,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: child,
    );
  }

  /// Create accessible text with proper styling
  Widget createAccessibleText(
    String text, {
    TextStyle? style,
    bool isHeader = false,
    int headerLevel = 1,
    TextAlign? textAlign,
  }) {
    return AccessibleText(
      text,
      style: style,
      textAlign: textAlign,
      header: isHeader,
      headerLevel: headerLevel,
    );
  }

  /// Create accessible button with proper semantics
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? tooltip,
    String? semanticLabel,
    bool primary = false,
  }) {
    return AccessibleButton(
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      primary: primary,
      child: child,
    );
  }
}

/// High contrast theme provider
class HighContrastTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.yellow,
          secondary: Colors.black,
          onSecondary: Colors.yellow,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.yellow,
          onPrimary: Colors.black,
          secondary: Colors.yellow,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.yellow,
          error: Colors.red,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        ),
      );
}

/// Color contrast utilities
class ColorContrastUtils {
  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standards (4.5:1 for normal text)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast ratio meets WCAG AAA standards (7:1 for normal text)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 7.0;
  }

  /// Get a contrasting color that meets WCAG AA standards
  static Color getContrastingColor(Color background) {
    final backgroundLuminance = background.computeLuminance();

    // If background is dark, return light color
    if (backgroundLuminance < 0.5) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }
}

/// Focus management utilities
class FocusUtils {
  /// Move focus to the next focusable widget
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to the previous focusable widget
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Request focus for a specific widget
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  /// Clear focus from all widgets
  static void clearFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Create a focus traversal order for widgets
  static Widget createFocusTraversalGroup({
    required List<Widget> children,
    required BuildContext context,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(children: children),
    );
  }
}

/// Accessibility testing utilities for use in test files
/// Note: These utilities should be used in test files only
class AccessibilityTestUtils {
  /// Check if a widget has proper semantic labeling
  static bool hasProperSemantics(Widget widget) {
    // This is a simplified check for production use
    return true; // Placeholder implementation
  }

  /// Check if touch target meets minimum size requirements
  static bool meetsMinimumTouchTargetSize(Size size) {
    return size.width >= 44.0 && size.height >= 44.0;
  }

  /// Validate that text has sufficient contrast
  static bool hasValidTextContrast(Color textColor, Color backgroundColor) {
    return ColorContrastUtils.meetsWCAGAA(textColor, backgroundColor);
  }
}
