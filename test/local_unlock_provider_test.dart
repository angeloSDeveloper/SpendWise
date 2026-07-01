import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'il PIN richiede almeno quattro cifre e sblocca solo se corretto',
    () async {
      final notifier = LocalUnlockNotifier();
      await notifier.load();

      expect(() => notifier.setPin('123'), throwsArgumentError);
      await notifier.setPin('1234');
      expect(notifier.state.pinEnabled, isTrue);
      expect(await notifier.unlockWithPin('0000'), isFalse);
      expect(await notifier.unlockWithPin('1234'), isTrue);
    },
  );
}
