import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 360;
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1280;
}

enum ScreenSize { mobile, tablet, desktop }

class AppResponsive {
  AppResponsive._();

  static ScreenSize screenSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppBreakpoints.mobile) return ScreenSize.mobile;
    if (w < AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= AppBreakpoints.mobile && w < AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static EdgeInsets screenPadding(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 12);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 20);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 28);
    }
  }

  static double spacing(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 18;
      case ScreenSize.desktop:
        return 24;
    }
  }

  static double cardRadius(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 16;
      case ScreenSize.desktop:
        return 18;
    }
  }

  static double titleFontSize(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 22;
      case ScreenSize.tablet:
        return 28;
      case ScreenSize.desktop:
        return 34;
    }
  }

  static double subtitleFontSize(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 14;
      case ScreenSize.tablet:
        return 15;
      case ScreenSize.desktop:
        return 17;
    }
  }

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 400) return 1;
    if (w < AppBreakpoints.mobile) return 2;
    if (w < AppBreakpoints.tablet) return 2;
    if (w < AppBreakpoints.desktop) return 3;
    return 4;
  }

  static double maxFormWidth(BuildContext context) {
    final size = screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 540;
      case ScreenSize.desktop:
        return 640;
    }
  }

  static double dialogMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.92).clamp(280.0, 560.0);
  }

  static double dialogMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.82).clamp(240.0, 680.0);
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.compact) return const EdgeInsets.all(10);
    if (width < AppBreakpoints.mobile) return const EdgeInsets.all(16);
    if (width < AppBreakpoints.tablet) return const EdgeInsets.all(20);
    return const EdgeInsets.all(28);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, AppResponsive.screenSize(context));
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.screenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Keeps long dialog content inside the visible, keyboard-adjusted viewport.
class ResponsiveDialogBody extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool scrollable;

  const ResponsiveDialogBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          )
        : child;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? AppResponsive.dialogMaxWidth(context),
        maxHeight: AppResponsive.dialogMaxHeight(context),
      ),
      child: content,
    );
  }
}
