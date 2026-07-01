import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('it'),
    initializeDateFormatting('en'),
    initializeDateFormatting('es'),
    initializeDateFormatting('de'),
  ]);
  Intl.defaultLocale = 'it';
  runApp(const ProviderScope(child: SpendWiseApp()));
}
