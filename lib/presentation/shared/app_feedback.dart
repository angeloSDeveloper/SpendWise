import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static int bannerSeconds = 10;
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showAppMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  int? durationSeconds,
}) {
  final seconds = durationSeconds ?? AppFeedback.bannerSeconds;
  if (seconds <= 0 || !context.mounted) return null;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: seconds),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: messenger.hideCurrentSnackBar,
        child: Text(message),
      ),
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}
