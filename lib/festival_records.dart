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
  static const _mastery = 'festival.mastery';

  int get volume => _preferences.getInt(_volume) ?? 70;
  bool get vibration => _preferences.getBool(_vibration) ?? true;
  bool get rehearsalCompleted => _preferences.getBool(_rehearsal) ?? false;
  int? get masteryBest => _preferences.getInt(_mastery);

  Future<bool> setVolume(int value) =>
      _preferences.setInt(_volume, value.clamp(0, 100));
  Future<bool> setVibration(bool value) =>
      _preferences.setBool(_vibration, value);
  Future<bool> completeRehearsal() => _preferences.setBool(_rehearsal, true);

  ({int score, ChorusCheckpoint checkpoint})? get concertBest {
    final stored = _preferences.getString(_concert);
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
    final best = concertBest;
    if (best != null && score <= best.score) return true;
    return _preferences.setString(
      _concert,
      jsonEncode({
        'score': score,
        'finalChorus': performance.chorusResult(3).checkpoint.toRecord(),
      }),
    );
  }
}
