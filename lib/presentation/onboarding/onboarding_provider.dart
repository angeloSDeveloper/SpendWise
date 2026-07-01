import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'onboarding_completed_v1';

class OnboardingState {
  const OnboardingState({this.loading = true, this.completed = false});

  final bool loading;
  final bool completed;
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier()..load(),
    );

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = OnboardingState(
      loading: false,
      completed: preferences.getBool(_onboardingKey) ?? false,
    );
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingKey, true);
    state = const OnboardingState(loading: false, completed: true);
  }

  Future<void> restart() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_onboardingKey);
    state = const OnboardingState(loading: false);
  }
}
