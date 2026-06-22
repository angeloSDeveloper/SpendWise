import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/app/router.dart';
import 'package:spendwise/app/theme.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';

class SpendWiseApp extends ConsumerWidget {
  const SpendWiseApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'SpendWise',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme(),
    darkTheme: AppTheme.darkTheme(),
    themeMode: ref.watch(settingsProvider).themeMode,
    routerConfig: ref.watch(routerProvider),
  );
}
