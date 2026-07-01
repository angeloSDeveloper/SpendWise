import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

class SwipeRevealDelete extends ConsumerStatefulWidget {
  const SwipeRevealDelete({
    required this.child,
    required this.onDelete,
    this.onUndo,
    this.deletedMessage = 'Elemento eliminato',
    super.key,
  });

  final Widget child;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onUndo;
  final String deletedMessage;

  @override
  ConsumerState<SwipeRevealDelete> createState() => _SwipeRevealDeleteState();
}

class _SwipeRevealDeleteState extends ConsumerState<SwipeRevealDelete> {
  static const _actionWidth = 76.0;
  static final _openItem = ValueNotifier<Object?>(null);

  final _token = Object();
  double _offset = 0;
  bool _pendingDelete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _openItem.addListener(_closeWhenAnotherOpens);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _openItem.removeListener(_closeWhenAnotherOpens);
    if (identical(_openItem.value, _token)) _openItem.value = null;
    super.dispose();
  }

  void _closeWhenAnotherOpens() {
    if (!identical(_openItem.value, _token) && _offset != 0 && mounted) {
      setState(() => _offset = 0);
    }
  }

  void _close() {
    if (_offset == 0 || _pendingDelete) return;
    setState(() => _offset = 0);
    if (identical(_openItem.value, _token)) _openItem.value = null;
  }

  void _drag(double delta) {
    if (_pendingDelete) return;
    final left = ref.read(settingsProvider).swipeDirection == 'left';
    setState(() {
      _offset = left
          ? (_offset + delta).clamp(-_actionWidth, 0)
          : (_offset + delta).clamp(0, _actionWidth);
    });
  }

  void _settle() {
    if (_pendingDelete) return;
    final left = ref.read(settingsProvider).swipeDirection == 'left';
    final reveal = _offset.abs() > _actionWidth / 2;
    setState(
      () => _offset = reveal ? (left ? -_actionWidth : _actionWidth) : 0,
    );
    _openItem.value = reveal ? _token : null;
  }

  Future<void> _commitDelete() async {
    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      await widget.onDelete();
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingDelete = false);
      showAppMessage(context, 'Eliminazione non riuscita');
    }
  }

  void _requestDelete() {
    if (_pendingDelete) return;
    final seconds = ref.read(settingsProvider).bannerDurationSeconds;
    setState(() {
      _pendingDelete = true;
      _offset = 0;
    });
    _openItem.value = null;
    if (widget.onUndo != null) {
      _commitDelete();
      if (seconds == 0) return;
      showAppMessage(
        context,
        widget.deletedMessage,
        durationSeconds: seconds,
        actionLabel: 'ANNULLA',
        onAction: () async {
          _timer?.cancel();
          try {
            await widget.onUndo!();
            if (mounted) setState(() => _pendingDelete = false);
          } catch (_) {
            if (mounted) showAppMessage(context, 'Ripristino non riuscito');
          }
        },
      );
      return;
    }
    if (seconds == 0) {
      _commitDelete();
      return;
    }
    showAppMessage(
      context,
      '${widget.deletedMessage}. Eliminazione tra $seconds secondi.',
      durationSeconds: seconds,
      actionLabel: 'ANNULLA',
      onAction: () {
        _timer?.cancel();
        if (mounted) setState(() => _pendingDelete = false);
      },
    );
    _timer = Timer(Duration(seconds: seconds), () {
      if (_pendingDelete) _commitDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final left = ref.watch(settingsProvider).swipeDirection == 'left';
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: _pendingDelete
          ? const SizedBox.shrink()
          : TapRegion(
              onTapOutside: (_) => _close(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.transparent,
                        child: Align(
                          alignment: left
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: SizedBox(
                            width: _actionWidth,
                            child: IconButton(
                              tooltip: 'Elimina',
                              onPressed: _requestDelete,
                              color: Theme.of(context).colorScheme.error,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(_offset, 0, 0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => _close(),
                        onHorizontalDragUpdate: (details) =>
                            _drag(details.delta.dx),
                        onHorizontalDragEnd: (_) => _settle(),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
