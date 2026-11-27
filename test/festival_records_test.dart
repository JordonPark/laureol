import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/festival_records.dart';
import 'package:laureol/performance_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Ad permission starts undecided and can be withdrawn', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final records = FestivalRecords(preferences);
    expect(records.adConsent, isNull);

    expect(await records.setAdConsent(true), isTrue);
    await preferences.reload();
    expect(FestivalRecords(preferences).adConsent, isTrue);

    expect(await records.setAdConsent(false), isTrue);
    await preferences.reload();
    expect(FestivalRecords(preferences).adConsent, isFalse);
  });

  test(
    'Tour records stay independent across venues and keep the highest score',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final records = FestivalRecords(preferences);
      final first = TourRegion.alley.venues.first;
      final second = first.next!;
      expect(records.isUnlocked(second), isTrue);
      final strong = FestivalPerformance(venue: first)
        ..startMainConcert()
        ..setVolume(FestivalZone.back, 50)
        ..advanceTicks(576);
      final weak = FestivalPerformance(venue: first)..advanceTicks(736);
      final another = FestivalPerformance(venue: second)..advanceTicks(736);
      expect(strong.score, greaterThan(weak.score));
      expect(
        await Future.wait([
          records.record(strong),
          records.record(weak),
          records.record(another),
        ]),
        [true, true, true],
      );
      await preferences.reload();
      final reloaded = FestivalRecords(preferences);
      expect(reloaded.bestFor(first)?.score, strong.score);
      expect(reloaded.bestFor(second)?.score, another.score);
      expect(reloaded.concertBest, isNull);
    },
  );

  test(
    'Completing the audience goal unlocks a separate night market record',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final records = FestivalRecords(preferences);
      expect(records.nightMarketUnlocked, isFalse);
      final first = FestivalPerformance()..advanceTicks(22 * 8);
      first.setVolume(FestivalZone.back, 50);
      first.queue(FestivalZone.front);
      first.advanceTicks(100 * 8 - first.tick);
      expect(first.missionAchieved, isTrue);
      expect(await records.record(first), isTrue);
      await preferences.reload();
      expect(FestivalRecords(preferences).nightMarketUnlocked, isTrue);

      final market = FestivalPerformance(venue: FestivalVenue.nightMarket)
        ..advanceTicks(24 * 8);
      expect(records.isUnlocked(FestivalVenue.liveClub), isFalse);
      expect(market.eventNotice.$1, contains('야시장 소음'));
      market.advanceTicks(100 * 8 - market.tick);
      expect(await records.record(market), isTrue);
      expect(records.bestFor(FestivalVenue.nightMarket)?.score, market.score);
      expect(records.concertBest?.score, first.score);
      expect(records.isUnlocked(FestivalVenue.liveClub), isTrue);
      expect(records.isUnlocked(FestivalVenue.rooftop), isFalse);

      for (final venue in [FestivalVenue.liveClub, FestivalVenue.rooftop]) {
        expect(records.isUnlocked(venue), isTrue);
        final performance = FestivalPerformance(venue: venue)
          ..startMainConcert();
        while (!performance.finished) {
          for (final zone in FestivalZone.values) {
            final target = performance.readyVolumeRange(zone);
            final volume = performance.volume(zone);
            if (volume < target.minimum || volume > target.maximum) {
              performance.setVolume(
                zone,
                (target.minimum + target.maximum) ~/ 2,
              );
            }
          }
          if (performance.recommendedSignalZone case final zone?) {
            expect(performance.signal(zone), SignalState.available);
            performance.queue(zone);
          }
          performance.advanceTicks(1);
        }
        expect(performance.missionAchieved, isTrue);
        expect(await records.record(performance), isTrue);
        await preferences.reload();
        final reloaded = FestivalRecords(preferences);
        expect(reloaded.missionCompleted(venue), isTrue);
        expect(reloaded.bestFor(venue)?.score, performance.score);
        expect(
          reloaded.bestFor(FestivalVenue.nightMarket)?.score,
          market.score,
        );
      }
    },
  );
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
