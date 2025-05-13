import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  bool _hasCompletedOnboarding = false;
  static const String _onboardingKey = 'has_completed_onboarding';

  OnboardingProvider() {
    loadOnboardingStatus();
  }

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading onboarding status: $e');
      _hasCompletedOnboarding = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      _hasCompletedOnboarding = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }
}
