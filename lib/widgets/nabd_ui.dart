import 'package:flutter/material.dart';

/// Shared building blocks of the Nabd look: soft cards, section headers,
/// feature tiles and empty states. Screens compose these instead of styling
/// containers by hand, so the app reads as one design.

/// A rounded surface card with an optional tap and an optional gradient.
class NabdCard extends StatelessWidget {
  const NabdCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
    this.color,
    this.radius = 22,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null
              ? (color ?? (dark ? scheme.surfaceContainer : Colors.white))
              : null,
          gradient: gradient,
          borderRadius: shape,
          border: gradient == null && color == null
              ? Border.all(color: scheme.outlineVariant)
              : null,
          boxShadow: gradient == null && !dark
              ? [
                  BoxShadow(
                    color: const Color(0xFF2B2140).withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A section title with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 10),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
            ),
          ),
          // A long action label (some languages run long) wraps rather than
          // pushing the row past the screen edge.
          if (actionLabel != null)
            Flexible(
              child: TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, textAlign: TextAlign.end),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact tile that opens one feature.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = color ?? scheme.primary;
    return NabdCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.tertiary),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
            ),
        ],
      ),
    );
  }
}

/// A grid of [FeatureTile]s that adapts its column count to the width.
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: EqualHeightGrid(
        columns: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
        children: children,
      ),
    );
  }
}

/// A grid whose rows are as tall as their tallest cell. Unlike a GridView
/// with a fixed aspect ratio, nothing is clipped when the system font is
/// large, and cells in a row still line up.
class EqualHeightGrid extends StatelessWidget {
  const EqualHeightGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 12,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var i = start; i < start + columns; i++) {
        if (cells.isNotEmpty) cells.add(SizedBox(width: spacing));
        cells.add(Expanded(
          child: i < children.length ? children[i] : const SizedBox.shrink(),
        ));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// A friendly empty state: a large emoji, a title, a line and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A small figure with its label, used in summary rows.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Expanded(
      child: NabdCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: tint, size: 22),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
