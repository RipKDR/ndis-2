import 'package:flutter/material.dart';

/// Enhanced accessible button with proper semantics
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? minSize;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.label,
    this.hint,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.minSize = 44.0, // WCAG minimum touch target size
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled && onPressed != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize!,
          minHeight: minSize!,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            minimumSize: Size(minSize!, minSize!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible card with proper semantics
class AccessibleCard extends StatelessWidget {
  final String? label;
  final String? hint;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;

  const AccessibleCard({
    super.key,
    this.label,
    this.hint,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      onTap: onTap,
      child: Card(
        color: color,
        elevation: elevation,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Accessible text field with proper semantics
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      enabled: enabled,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Accessible list tile with proper semantics
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? hint;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.hint,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      hint: subtitle ?? hint,
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      onTap: onTap,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        selected: selected,
        enabled: enabled,
      ),
    );
  }
}

/// Accessible switch with proper semantics
class AccessibleSwitch extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AccessibleSwitch({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      toggled: value,
      enabled: enabled,
      onTap: enabled ? () => onChanged?.call(!value) : null,
      child: SwitchListTile(
        title: Text(label),
        subtitle: hint != null ? Text(hint!) : null,
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

/// Accessible slider with proper semantics
class AccessibleSlider extends StatelessWidget {
  final String label;
  final String? hint;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final bool enabled;

  const AccessibleSlider({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      slider: true,
      enabled: enabled,
      value: value.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
            label: value.toStringAsFixed(divisions != null ? 1 : 0),
          ),
        ],
      ),
    );
  }
}

/// Accessible progress indicator
class AccessibleProgressIndicator extends StatelessWidget {
  final String label;
  final String? hint;
  final double value;
  final double? minValue;
  final double? maxValue;
  final Color? color;
  final double? strokeWidth;

  const AccessibleProgressIndicator({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - minValue!) / (maxValue! - minValue!)) * 100;
    
    return Semantics(
      label: label,
      hint: hint,
      value: '${percentage.toStringAsFixed(1)}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Accessible image with proper semantics
class AccessibleImage extends StatelessWidget {
  final String imageUrl;
  final String? semanticLabel;
  final String? semanticHint;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AccessibleImage({
    super.key,
    required this.imageUrl,
    this.semanticLabel,
    this.semanticHint,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      image: true,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      ),
    );
  }
}

/// Accessible icon with proper semantics
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final String? semanticLabel;
  final String? semanticHint;
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AccessibleIcon({
    super.key,
    required this.icon,
    this.semanticLabel,
    this.semanticHint,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

/// Accessible container with proper semantics
class AccessibleContainer extends StatelessWidget {
  final String? semanticLabel;
  final String? semanticHint;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;

  const AccessibleContainer({
    super.key,
    this.semanticLabel,
    this.semanticHint,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      onTap: onTap,
      child: Container(
        padding: padding,
        margin: margin,
        color: color,
        decoration: decoration,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// Accessible focus scope for keyboard navigation
class AccessibleFocusScope extends StatelessWidget {
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleFocusScope({
    super.key,
    required this.child,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: autofocus,
      child: child,
    );
  }
}

/// Accessible announcement for screen readers
class AccessibleAnnouncement extends StatelessWidget {
  final String message;
  final Duration duration;
  final Widget child;

  const AccessibleAnnouncement({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 2),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: child,
    );
  }
}
