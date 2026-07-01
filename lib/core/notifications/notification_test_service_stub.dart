class NotificationTestService {
  NotificationTestService._();
  static final instance = NotificationTestService._();

  Future<void> show(String title, String body) {
    throw UnsupportedError('Notifiche non supportate su questa piattaforma');
  }
}
