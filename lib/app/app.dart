import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/app/router.dart';
import 'package:spendwise/app/theme.dart';
class SpendWiseApp extends ConsumerWidget { const SpendWiseApp({super.key}); @override Widget build(BuildContext context,WidgetRef ref) => MaterialApp.router(title:'SpendWise',debugShowCheckedModeBanner:false,theme:AppTheme.lightTheme(),darkTheme:AppTheme.darkTheme(),routerConfig:ref.watch(routerProvider)); }
