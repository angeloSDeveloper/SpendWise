import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/dashboard/dashboard_layout_provider.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/onboarding/onboarding_screen.dart';
import 'package:spendwise/domain/models/daily_expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dashboard layout persists visibility, size and order', () async {
    final notifier = DashboardLayoutNotifier();
    await notifier.load();

    await notifier.setSize('categories', DashboardWidgetSize.wide);
    await notifier.setVisible('trend', false);
    await notifier.reorder(3, 0);

    final restored = DashboardLayoutNotifier();
    await restored.load();

    expect(restored.state.first.id, 'recent');
    expect(
      restored.state.singleWhere((item) => item.id == 'categories').size,
      DashboardWidgetSize.wide,
    );
    expect(
      restored.state.singleWhere((item) => item.id == 'trend').visible,
      isFalse,
    );
  });

  test('dashboard layout restores safe defaults from invalid json', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_widget_layout_v1': '{invalid',
    });

    final notifier = DashboardLayoutNotifier();
    await notifier.load();

    expect(notifier.state, defaultDashboardWidgets);
  });

  testWidgets('onboarding resta leggibile su mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pump();

    expect(find.text('Benvenuto in SpendWise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor widget non va in overflow su mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DashboardWidgetEditorSheet())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personalizza dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('riepiloghi dashboard si riposizionano su web compatto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardOverview(
            data: const DashboardData(
              categories: [10, 20, 30, 40],
              months: [1, 2, 3, 4, 5, 6],
              recent: <DailyExpense>[],
            ),
            modules: const {
              'daily',
              'subscriptions',
              'installments',
              'vehicle',
            },
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final firstY = tester.getTopLeft(find.text('Spese del mese')).dy;
    final fourthY = tester.getTopLeft(find.text('Rate')).dy;
    expect(fourthY, greaterThan(firstY));
    expect(tester.takeException(), isNull);
  });
}
