import 'package:flutter/widgets.dart';

/// Calls [onReload] each time [signal] notifies, e.g. when a tab of
/// HomePage is opened again. [onReload] gets this widget's context, so it
/// can read blocs provided above it.
class ReloadListener extends StatefulWidget {
  final Listenable? signal;
  final void Function(BuildContext context) onReload;
  final Widget child;

  const ReloadListener({
    super.key,
    required this.signal,
    required this.onReload,
    required this.child,
  });

  @override
  State<ReloadListener> createState() => _ReloadListenerState();
}

class _ReloadListenerState extends State<ReloadListener> {
  @override
  void initState() {
    super.initState();
    widget.signal?.addListener(_reload);
  }

  @override
  void didUpdateWidget(ReloadListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal != widget.signal) {
      oldWidget.signal?.removeListener(_reload);
      widget.signal?.addListener(_reload);
    }
  }

  @override
  void dispose() {
    widget.signal?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) widget.onReload(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
