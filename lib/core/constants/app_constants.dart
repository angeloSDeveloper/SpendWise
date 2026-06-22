import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://spendwise-api-prod.lopreteangelo97.workers.dev/api');
  static const appName = 'SpendWise';
  static const appVersion = '1.0.0';
  static const syncIntervalSeconds = 30;
  static const tokenRefreshMarginSeconds = 60;
  static const kLastSyncKey = 'last_sync';
  static const kUserIdKey = 'user_id';
  static const kAccessTokenKey = 'access_token';
  static const kRefreshTokenKey = 'refresh_token';
  static const kFuelTypes = ['gasoline', 'diesel', 'electric', 'hybrid', 'lpg'];
  static const kMaintenanceCategories = ['tagliando', 'pneumatici', 'freni', 'elettrico', 'batteria', 'carrozzeria', 'altro'];
}

abstract final class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF7C3AED);
  static const daily = Color(0xFFF59E0B);
  static const subscription = Color(0xFF8B5CF6);
  static const installment = Color(0xFFEC4899);
  static const vehicle = Color(0xFF10B981);
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
}
