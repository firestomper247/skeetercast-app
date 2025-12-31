import 'dart:ui' show DisplayFeatureType;
import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design guidelines
class Breakpoints {
  static const double compact = 600;   // Phones
  static const double medium = 840;    // Tablets, foldables unfolded
  static const double expanded = 1200; // Large tablets, desktops
}

/// Screen size categories
enum ScreenSize { compact, medium, expanded }

/// Utility class for responsive design
class Responsive {
  /// Get the current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return ScreenSize.compact;
    if (width < Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  /// Check if the screen is compact (phone)
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.compact;
  }

  /// Check if the screen is medium (small tablet, foldable)
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.compact && width < Breakpoints.medium;
  }

  /// Check if the screen is expanded (large tablet, desktop)
  static bool isExpanded(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.medium;
  }

  /// Check if we should use tablet layout (medium or expanded)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.compact;
  }

  /// Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.compact:
        return const EdgeInsets.all(16);
      case ScreenSize.medium:
        return const EdgeInsets.all(24);
      case ScreenSize.expanded:
        return const EdgeInsets.all(32);
    }
  }

  /// Get the number of columns for grid layouts
  static int getGridColumns(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.compact:
        return 1;
      case ScreenSize.medium:
        return 2;
      case ScreenSize.expanded:
        return 3;
    }
  }

  /// Get the detail panel width ratio for master-detail layouts
  static double getDetailRatio(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.compact:
        return 1.0; // Full width
      case ScreenSize.medium:
        return 0.55; // 55% for detail
      case ScreenSize.expanded:
        return 0.65; // 65% for detail
    }
  }
}

/// A widget that builds different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.medium && expanded != null) {
          return expanded!;
        }
        if (constraints.maxWidth >= Breakpoints.compact && medium != null) {
          return medium!;
        }
        return compact;
      },
    );
  }
}

/// A master-detail layout for tablet/foldable screens
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterWidth;
  final bool showDivider;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 350,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isTablet(context) || detail == null) {
      return master;
    }

    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        if (showDivider) const VerticalDivider(width: 1),
        Expanded(
          child: detail!,
        ),
      ],
    );
  }
}

/// A widget that adapts to foldable devices with a hinge
/// Shows content side-by-side when the device is unfolded with a hinge
class FoldableLayout extends StatelessWidget {
  final Widget startPane;
  final Widget? endPane;
  final double paneProportion; // Proportion of start pane (0.0 to 1.0)

  const FoldableLayout({
    super.key,
    required this.startPane,
    this.endPane,
    this.paneProportion = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final hingeBounds = mediaQuery.hingeBounds;
    final screenWidth = mediaQuery.size.width;

    // If phone or no end pane, just show start pane
    if (screenWidth < Breakpoints.compact || endPane == null) {
      return startPane;
    }

    // If foldable with hinge, position content around the hinge
    if (hingeBounds != null) {
      return Row(
        children: [
          SizedBox(
            width: hingeBounds.left,
            child: startPane,
          ),
          SizedBox(width: hingeBounds.width), // Space for hinge
          Expanded(child: endPane!),
        ],
      );
    }

    // Regular tablet - use proportion
    return Row(
      children: [
        SizedBox(
          width: screenWidth * paneProportion,
          child: startPane,
        ),
        Expanded(child: endPane!),
      ],
    );
  }
}

/// Widget that detects if device is a foldable and provides hinge info
class FoldableDetector extends StatelessWidget {
  final Widget Function(BuildContext context, MediaQueryData mediaQuery, bool isFoldable, Rect? hingeBounds) builder;

  const FoldableDetector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final hingeFeatures = mediaQuery.displayFeatures
        .where((f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold)
        .toList();

    final isFoldable = hingeFeatures.isNotEmpty;
    final hingeBounds = isFoldable ? hingeFeatures.first.bounds : null;

    return builder(context, mediaQuery, isFoldable, hingeBounds);
  }
}

/// Extension to check if the device is a foldable
extension FoldableMediaQuery on MediaQueryData {
  bool get isFoldable {
    return displayFeatures.any(
      (f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold,
    );
  }

  Rect? get hingeBounds {
    final hinges = displayFeatures.where(
      (f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold,
    );
    return hinges.isNotEmpty ? hinges.first.bounds : null;
  }

  bool get isUnfolded {
    // Consider unfolded if screen is wider than compact breakpoint
    return size.width >= Breakpoints.compact;
  }
}
