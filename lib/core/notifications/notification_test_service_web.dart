// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class NotificationTestService {
  NotificationTestService._();
  static final instance = NotificationTestService._();

  Future<void> show(String title, String body) async {
    var permission = html.Notification.permission;
    if (permission != 'granted') {
      permission = await html.Notification.requestPermission();
    }
    if (permission != 'granted') {
      throw StateError('Permesso notifiche non concesso');
    }
    html.Notification(title, body: body, icon: 'icons/Icon-192.png');
  }
}
