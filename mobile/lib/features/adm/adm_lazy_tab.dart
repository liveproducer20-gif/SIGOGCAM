import 'package:flutter/material.dart';

/// Exposes Administration's explicit controller to lazy tabs.
class AdmTabScope extends InheritedNotifier<TabController> {
  const AdmTabScope({
    super.key,
    required TabController controller,
    required super.child,
  }) : super(notifier: controller);

  static TabController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdmTabScope>()?.notifier;
}

/// Loads a tab only the first time it becomes visible and keeps its state.
mixin AdmLazyTabMixin<T extends StatefulWidget> on State<T> {
  bool _didLoad = false;
  TabController? _controller;
  int? _myIndex;
  Future<void> Function()? _loader;

  void initLazy(int myIndex, Future<void> Function() load) {
    _myIndex = myIndex;
    _loader = load;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller =
          AdmTabScope.maybeOf(context) ?? DefaultTabController.maybeOf(context);
      if (_controller == null) {
        _loadOnce();
        return;
      }
      _controller!.addListener(_handleTabChange);
      _handleTabChange();
    });
  }

  void _handleTabChange() {
    if (mounted && _controller?.index == _myIndex) _loadOnce();
  }

  void _loadOnce() {
    if (_didLoad || !mounted || _loader == null) return;
    _didLoad = true;
    _loader!();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }
}
