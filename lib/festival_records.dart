import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'festival_performance.dart';

class FestivalRecords extends ChangeNotifier {
  FestivalRecords(this._preferences);

  final SharedPreferences _preferences;
  Future<void>? _pendingRecord;
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
    _ => true,
  };

  String _recordKey(FestivalVenue venue) => switch (venue) {
    FestivalVenue.neighborhood => _concert,
    FestivalVenue.nightMarket => _marketConcert,
    FestivalVenue.liveClub => 'festival.liveClubConcert.v1',
    FestivalVenue.rooftop => 'festival.rooftopConcert.v1',
    _ => 'festival.tour.${venue.name}.v1',
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

  Future<bool> record(FestivalPerformance performance) {
    if (!performance.finished) return Future.value(false);
    final previous = _pendingRecord;
    final saved = previous == null
        ? _recordFinished(performance)
        : previous.then((_) => _recordFinished(performance));
    final completion = saved.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pendingRecord = completion;
    unawaited(
      completion.then((_) {
        if (identical(_pendingRecord, completion)) _pendingRecord = null;
      }),
    );
    return saved;
  }

  Future<bool> _recordFinished(FestivalPerformance performance) async {
    final score = performance.score;
    if (performance.mastery) {
      final best = masteryBest;
      if (best != null && score <= best) return true;
      final saved = await _preferences.setInt(_mastery, score);
      if (saved) notifyListeners();
      return saved;
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
    if (saved.any((success) => success)) notifyListeners();
    return saved.every((success) => success);
  }
}
