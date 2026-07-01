import 'dart:async';

import 'package:flutter/material.dart';

class SwipeRevealDelete extends StatefulWidget {
  const SwipeRevealDelete({
    required this.child,
    required this.onDelete,
    this.deletedMessage = 'Elemento eliminato',
    super.key,
  });

  final Widget child;
  final Future<void> Function() onDelete;
  final String deletedMessage;

  @override
  State<SwipeRevealDelete> createState() => _SwipeRevealDeleteState();
}

class _SwipeRevealDeleteState extends State<SwipeRevealDelete> {
  static const _actionWidth = 76.0;
  double _offset = 0;
  bool _pendingDelete = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _drag(double delta) {
    if (_pendingDelete) return;
    setState(() => _offset = (_offset + delta).clamp(0, _actionWidth));
  }

  void _settle() {
    if (_pendingDelete) return;
    setState(() => _offset = _offset > _actionWidth / 2 ? _actionWidth : 0);
  }

  void _requestDelete() {
    if (_pendingDelete) return;
    setState(() {
      _pendingDelete = true;
      _offset = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text('${widget.deletedMessage}. Eliminazione tra 10 secondi.'),
        action: SnackBarAction(
          label: 'ANNULLA',
          onPressed: () {
            _timer?.cancel();
            if (mounted) setState(() => _pendingDelete = false);
          },
        ),
      ),
    );
    _timer = Timer(const Duration(seconds: 10), () async {
      if (!_pendingDelete) return;
      try {
        await widget.onDelete();
      } catch (_) {
        if (!mounted) return;
        setState(() => _pendingDelete = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminazione non riuscita')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    child: _pendingDelete
        ? const SizedBox.shrink()
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Align(
                      alignment: Alignment.centerLeft,
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
                    onHorizontalDragUpdate: (details) =>
                        _drag(details.delta.dx),
                    onHorizontalDragEnd: (_) => _settle(),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
  );
}
