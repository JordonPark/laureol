import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'festival_performance.dart';

class FestivalRecords {
  FestivalRecords(this._preferences);

  final SharedPreferences _preferences;
  static const _volume = 'festival.volume';
  static const _vibration = 'festival.vibration';
  static const _rehearsal = 'festival.guidedRehearsal.v2';
  static const _concert = 'festival.concert.v1';
  static const _marketConcert = 'festival.marketConcert.v1';
  static const _marketUnlocked = 'festival.marketUnlocked';
  static const _mastery = 'festival.mastery';

  int get volume => _preferences.getInt(_volume) ?? 70;
  bool get vibration => _preferences.getBool(_vibration) ?? true;
  bool get rehearsalCompleted => _preferences.getBool(_rehearsal) ?? false;
  int? get masteryBest => _preferences.getInt(_mastery);
  bool get nightMarketUnlocked =>
      _preferences.getBool(_marketUnlocked) ?? false;

  Future<bool> setVolume(int value) =>
      _preferences.setInt(_volume, value.clamp(0, 100));
  Future<bool> setVibration(bool value) =>
      _preferences.setBool(_vibration, value);
  Future<bool> completeRehearsal() => _preferences.setBool(_rehearsal, true);

  ({int score, ChorusCheckpoint checkpoint})? get concertBest =>
      bestFor(FestivalVenue.neighborhood);

  bool isUnlocked(FestivalVenue venue) => switch (venue) {
    FestivalVenue.neighborhood => true,
    FestivalVenue.nightMarket => nightMarketUnlocked,
    FestivalVenue.liveClub => bestFor(FestivalVenue.nightMarket) != null,
    FestivalVenue.rooftop => bestFor(FestivalVenue.liveClub) != null,
  };

  String _recordKey(FestivalVenue venue) => switch (venue) {
    FestivalVenue.neighborhood => _concert,
    FestivalVenue.nightMarket => _marketConcert,
    FestivalVenue.liveClub => 'festival.liveClubConcert.v1',
    FestivalVenue.rooftop => 'festival.rooftopConcert.v1',
  };

  bool missionCompleted(FestivalVenue venue) =>
      (venue == FestivalVenue.neighborhood && nightMarketUnlocked) ||
      (_preferences.getBool('${_recordKey(venue)}.mission') ?? false);

  ({int score, ChorusCheckpoint checkpoint})? bestFor(FestivalVenue venue) {
    final stored = _preferences.getString(_recordKey(venue));
    if (stored == null) return null;
    try {
      final value = jsonDecode(stored);
      if (value is! Map) return null;
      final score = value['score'];
      final checkpoint = ChorusCheckpoint.fromRecord(value['finalChorus']);
      if (score is! int || score < 0 || score > 90 || checkpoint?.chorus != 3) {
        return null;
      }
      return (score: score, checkpoint: checkpoint!);
    } on FormatException {
      return null;
    }
  }

  Future<bool> record(FestivalPerformance performance) async {
    if (!performance.finished) return false;
    final score = performance.score;
    if (performance.mastery) {
      final best = masteryBest;
      return best == null || score > best
          ? _preferences.setInt(_mastery, score)
          : true;
    }
    if (performance.practiceChorus != null) return true;
    final best = bestFor(performance.venue);
    final saved = await Future.wait([
      if (performance.venue == FestivalVenue.neighborhood &&
          performance.missionAchieved &&
          !nightMarketUnlocked)
        _preferences.setBool(_marketUnlocked, true),
      if (performance.venue != FestivalVenue.neighborhood &&
          performance.missionAchieved &&
          !missionCompleted(performance.venue))
        _preferences.setBool('${_recordKey(performance.venue)}.mission', true),
      if (best == null || score > best.score)
        _preferences.setString(
          _recordKey(performance.venue),
          jsonEncode({
            'score': score,
            'finalChorus': performance.chorusResult(3).checkpoint.toRecord(),
          }),
        ),
    ]);
    return saved.every((success) => success);
  }
}
