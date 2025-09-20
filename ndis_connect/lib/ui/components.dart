import 'package:flutter/material.dart';
import 'design_tokens.dart';

// Small set of reusable, accessible components inspired by shadcn/ui
// These are intentionally minimal and designed to layer with ThemeData

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool large;

  const PrimaryButton(
      {super.key, required this.onPressed, required this.child, this.large = false});

  @override
  Widget build(BuildContext context) {
    final minHeight = large ? 52.0 : 44.0;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          minimumSize: Size(88, minHeight), padding: const EdgeInsets.symmetric(horizontal: 16)),
      child: DefaultTextStyle(style: Theme.of(context).textTheme.labelLarge!, child: child),
    );
  }
}

class GhostButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const GhostButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CardContainer({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: DesignTokens.elevationLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius)),
      child: Padding(padding: padding ?? const EdgeInsets.all(12), child: child),
    );

    if (onTap != null) {
      return InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(DesignTokens.radius), child: card);
    }
    return card;
  }
}

class InputField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const InputField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(hintText: hint),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label!, style: Theme.of(context).textTheme.titleMedium)),
        // Provide a semantic label for screen readers when a visible label is present
        if (label != null)
          Semantics(container: true, textField: true, label: label, child: field)
        else
          field,
      ],
    );
  }
}

class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  const AccessibleIconButton(
      {super.key, required this.icon, required this.semanticLabel, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(onPressed: onPressed, icon: Icon(icon), tooltip: semanticLabel),
    );
  }
}

// Simple helper for ensuring minimum tappable size
Widget tappableWrapper({required Widget child}) {
  return ConstrainedBox(
      constraints: const BoxConstraints(
          minHeight: DesignTokens.minTappableSize, minWidth: DesignTokens.minTappableSize),
      child: child);
}
