import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/models.dart';
import '../../../core/network/api_client.dart';

const String _profileKey = 'user_profile_data';
const String _onboardedKey = 'user_is_onboarded';

class ProfileState {
  final bool isOnboarded;
  final UserProfileModel profile;
  final bool isLoading;

  const ProfileState({
    this.isOnboarded = false,
    this.profile = const UserProfileModel(name: 'Explorer'),
    this.isLoading = true,
  });

  ProfileState copyWith({
    bool? isOnboarded,
    UserProfileModel? profile,
    bool? isLoading,
  }) =>
      ProfileState(
        isOnboarded: isOnboarded ?? this.isOnboarded,
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool(_onboardedKey) ?? false;
    final jsonStr = prefs.getString(_profileKey);

    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = ProfileState(
          isOnboarded: isOnboarded,
          profile: UserProfileModel.fromJson(map),
          isLoading: false,
        );
        _ensureBackendSession(state.profile.name);
        return;
      } catch (_) {}
    }

    state = ProfileState(
      isOnboarded: isOnboarded,
      profile: const UserProfileModel(name: 'Explorer'),
      isLoading: false,
    );
  }

  Future<void> setProfile({required String name, required List<String> interests}) async {
    final updated = state.profile.copyWith(
      name: name.trim().isEmpty ? 'Explorer' : name.trim(),
      interests: interests,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
    await prefs.setString(_profileKey, jsonEncode(updated.toJson()));

    state = ProfileState(
      isOnboarded: true,
      profile: updated,
      isLoading: false,
    );

    _ensureBackendSession(updated.name);
  }

  Future<void> updateStats({
    int xpEarned = 0,
    int scoreEarned = 0,
    bool isPerfect = false,
    int newStreak = 0,
  }) async {
    final current = state.profile;
    final newXp = current.xp + xpEarned;
    final newLevel = _calculateLevel(newXp);

    final updated = current.copyWith(
      xp: newXp,
      level: newLevel,
      totalGames: current.totalGames + 1,
      totalScore: current.totalScore + scoreEarned,
      perfectQuizzes: current.perfectQuizzes + (isPerfect ? 1 : 0),
      articlesRead: current.articlesRead + 1,
      currentStreak: newStreak > 0 ? newStreak : current.currentStreak,
      longestStreak: newStreak > current.longestStreak ? newStreak : current.longestStreak,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(updated.toJson()));
    state = state.copyWith(profile: updated);
  }

  int _calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    int lvl = 1;
    while ((300 * (lvl * 1.5)).toInt() <= totalXp) {
      lvl++;
    }
    return lvl;
  }

  Future<void> _ensureBackendSession(String username) async {
    try {
      final email = '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@guest.wikiroulette.app';
      try {
        await ApiClient.instance.login(email, 'GuestPassword123!');
      } catch (_) {
        await ApiClient.instance.register(username, email, 'GuestPassword123!');
      }
    } catch (_) {}
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (_) => ProfileNotifier(),
);
