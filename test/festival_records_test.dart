import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/festival_records.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'Restores both sliders from the chosen chorus and preserves the log',
    () {
      final performance = FestivalPerformance();
      performance.advanceTicks(160);
      performance.setVolume(FestivalZone.front, 37);
      performance.setVolume(FestivalZone.back, 62);
      performance.advanceTicks(208);
      performance.setVolume(FestivalZone.front, 55);
      performance.advanceTicks(432);

      final original = performance.chorusResult(2);
      final replay = FestivalPerformance.replay(original.checkpoint);
      expect(replay.seconds, 46);
      expect(replay.volume(FestivalZone.front), 37);
      expect(replay.volume(FestivalZone.back), 62);
      expect(replay.score, 0);
      replay.advanceTicks(128);
      expect(replay.chorusResult(2).beatCount, 20);
      expect(
        original.checkpoint.toRecord(),
        replay.chorusResult(2).checkpoint.toRecord(),
      );
      expect(original.beatCount, 20);
    },
  );

  test(
    'Reloads settings and keeps concert and mastery records independent',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final records = FestivalRecords(preferences);
      expect(await records.setVolume(35), isTrue);
      expect(await records.setVibration(false), isTrue);

      final concert = FestivalPerformance()
        ..advanceTicks(160)
        ..setVolume(FestivalZone.front, 35)
        ..setVolume(FestivalZone.back, 50)
        ..advanceTicks(640);
      expect(await records.record(concert), isTrue);
      final best = records.concertBest!;
      final replay = FestivalPerformance.replay(best.checkpoint);
      replay.advanceTicks(48);
      expect(replay.generatorRunning, isFalse);
      replay.advanceTicks(80);
      expect(await records.record(replay), isTrue);
      expect(records.masteryBest, isNull);

      final mastery = FestivalPerformance.replay(
        best.checkpoint,
        mastery: true,
      );
      mastery.advanceTicks(48);
      expect(mastery.generatorRunning, isTrue);
      mastery.advanceTicks(80);
      expect(await records.record(mastery), isTrue);
      final lower = FestivalPerformance()..advanceTicks(800);
      await records.record(lower);
      await preferences.reload();

      final reloaded = FestivalRecords(preferences);
      expect(reloaded.volume, 35);
      expect(reloaded.vibration, isFalse);
      expect(reloaded.concertBest?.score, concert.score);
      expect(reloaded.masteryBest, mastery.score);
      expect(
        reloaded.concertBest?.checkpoint.toRecord(),
        best.checkpoint.toRecord(),
      );
    },
  );
}
