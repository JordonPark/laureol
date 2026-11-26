import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/performance_controls.dart';

void _at(FestivalPerformance performance, double seconds) {
  performance.advanceTicks((seconds * 8).round() - performance.tick);
}

void main() {
  test('Signal openings vary and survive a saved chorus replay', () {
    final performance = FestivalPerformance(signalTiming: math.Random(19));
    const front = FestivalZone.front;
    const back = FestivalZone.back;
    final advances = <int>{};
    performance.startMainConcert();
    performance.setVolume(back, 53);
    performance.startMainConcert();
    for (final (chorus, preview, regularOpening, close) in [
      (1, 20.0, 22.0, 24.0),
      (2, 46.0, 50.0, 52.0),
      (3, 74.0, 78.0, 81.0),
    ]) {
      _at(performance, preview);
      final saved = performance.chorusResult(chorus).checkpoint.toRecord();
      final restored = FestivalPerformance.replay(
        ChorusCheckpoint.fromRecord(saved)!,
      );
      if (chorus == 1) expect(restored.volume(back), 53);

      while (performance.signal(front) == SignalState.waiting &&
          performance.tick < (regularOpening * 8).round()) {
        performance.advanceTicks(1);
      }
      final openingTick = performance.tick;
      expect(performance.signal(front), SignalState.available);
      final earlier = (regularOpening * 8).round() - openingTick;
      expect(earlier, inInclusiveRange(0, 12));
      advances.add(earlier);

      restored.advanceTicks(openingTick - restored.tick - 1);
      expect(restored.signal(front), SignalState.waiting);
      restored.advanceTicks(1);
      expect(restored.signal(front), SignalState.available);
      _at(restored, close);
      expect(restored.signal(front), SignalState.waiting);

      final legacy = FestivalPerformance.replay(
        ChorusCheckpoint.fromRecord(saved.take(6).toList())!,
      );
      _at(legacy, regularOpening - .125);
      expect(legacy.signal(front), SignalState.waiting);
      legacy.advanceTicks(1);
      expect(legacy.signal(front), SignalState.available);
    }
    expect(advances, hasLength(3));
  });

  test('First chorus reserves once and scores each occupied half-second', () {
    final performance = FestivalPerformance();
    const front = FestivalZone.front;
    const back = FestivalZone.back;
    _at(performance, 22);
    expect(performance.remainingBeats, 4);
    expect(performance.recommendedSignalZone, front);
    expect(performance.cueFor(back), MixCue.adjust);
    expect(performance.volumeWarningMask, 2);
    expect(performance.readyVolumeRange(back), (minimum: 46, maximum: 58));
    performance.setVolume(back, 50);
    expect(performance.volumeWarningMask, 0);
    expect(performance.takeRecentCues(), [FestivalCue.applause]);
    performance.queue(front);
    performance.queue(back);
    expect(performance.signal(front), SignalState.queued);
    expect(performance.signal(back), SignalState.waiting);

    _at(performance, 24);
    expect(performance.position, const Duration(seconds: 24));
    expect(performance.takeRecentCues(), [FestivalCue.call]);
    expect(performance.takeRecentCues(), isEmpty);
    expect(performance.status(front), CrowdStatus.singing);
    expect(performance.signal(back), SignalState.responding);
    _at(performance, 25);
    expect(performance.takeRecentCues(), [FestivalCue.singalong]);
    expect(performance.status(back), CrowdStatus.singing);
    expect(performance.waveFrame, 0);
    expect(performance.score, 1);
    _at(performance, 30);
    expect(performance.comboEffect, (count: 10, elapsedTicks: 0));
    _at(performance, 31);
    expect(performance.comboEffect, (count: 10, elapsedTicks: 8));
    _at(performance, 31.5);
    expect(performance.comboEffect, isNull);
    _at(performance, 34);
    expect(performance.chorusScores, [28, 0, 0]);
  });

  test('Interludes turn the previous chorus into the next sound check', () {
    final performance = FestivalPerformance();
    const front = FestivalZone.front;
    const back = FestivalZone.back;
    _at(performance, 22);
    performance.setVolume(back, 50);
    performance.queue(front);
    _at(performance, 34);
    expect(performance.chorusScores, [28, 0, 0]);
    expect(performance.eventNotice, ('후렴 1 · 함께 떼창 9.0초', null));
    expect(performance.nextSignalCountdown, (
      chorus: 2,
      remaining: 16,
      total: 16,
    ));
    expect(performance.combo, 18);
    expect(performance.lightingTier, 1);
    expect(performance.holdingCombo, isTrue);
    expect(performance.readyVolumeRange(front), (minimum: 32, maximum: 44));
    expect(performance.status(front), CrowdStatus.loud);

    _at(performance, 36);
    expect(performance.eventNotice.$1, contains('앞줄 볼륨을 내려요'));
    expect(performance.advancePastInterlude(), isFalse);
    _at(performance, 36.125);
    performance.setVolume(front, 40);
    expect(performance.eventNotice.$1, contains('두 줄 ✓ 준비'));
    expect(performance.status(front), CrowdStatus.ready);
    expect(performance.nextSignalCountdown?.remaining, 8);
    expect(performance.advancePastInterlude(), isTrue);
    expect(performance.position, const Duration(milliseconds: 46125));
    expect(performance.combo, 18);
    expect(performance.advancePastInterlude(), isFalse);
    expect(performance.eventNotice, ('앞줄 관객 접근', 4));
    expect(performance.nextSignalCountdown?.remaining, 8);
    _at(performance, 48);
    expect(performance.status(front), CrowdStatus.ready);
    expect(performance.volume(front), 40);
    _at(performance, 50);
    expect(performance.nextSignalCountdown, isNull);
    expect(performance.signal(back), SignalState.available);
    expect(performance.chorusScores, [28, 0, 0]);

    performance.queue(back);
    _at(performance, 53);
    expect(performance.combo, 18);
    _at(performance, 53.5);
    expect(performance.combo, 19);
    expect(performance.holdingCombo, isFalse);
    _at(performance, 56.5);
    expect(performance.comboEffect, (count: 25, elapsedTicks: 0));
    _at(performance, 62);
    expect(performance.eventNotice.$1, startsWith('후렴 2 · 함께 떼창'));
    expect(performance.nextSignalCountdown, (
      chorus: 3,
      remaining: 12,
      total: 12,
    ));
    expect(performance.combo, 36);
    expect(performance.lightingTier, 2);
    _at(performance, 64);
    expect(performance.eventNotice.$1, contains('발전기가 켜지면 뒷줄'));
    expect(performance.advancePastInterlude(), isTrue);
    expect(performance.position, const Duration(seconds: 74));
    expect(performance.eventNotice, ('발전기 가동', 4));
    expect(performance.nextSignalCountdown?.remaining, 8);
    _at(performance, 78);
    expect(performance.nextSignalCountdown, isNull);
    expect(performance.signal(front), SignalState.available);
    performance.queue(front);
    _at(performance, 83);
    expect(performance.lightingTier, 3);
    expect(performance.comboEffect, (count: 40, elapsedTicks: 0));
  });

  test('Sound check keeps four seconds when a row still needs adjustment', () {
    final performance = FestivalPerformance();
    _at(performance, 37.875);
    expect(performance.advancePastInterlude(), isFalse);
    _at(performance, 38);
    expect(performance.advancePastInterlude(), isTrue);
    expect(performance.position, const Duration(seconds: 46));
  });

  test('The final two seconds fade and preserve the finished score', () {
    final performance = FestivalPerformance();
    _at(performance, 90);
    final score = performance.score;
    expect(performance.musicGain, 1);
    expect(performance.finished, isFalse);
    _at(performance, 91);
    expect(performance.musicGain, .5);
    expect(performance.finished, isFalse);
    _at(performance, 92);
    expect(performance.musicGain, 0);
    expect(performance.finished, isTrue);
    expect(performance.score, score);
  });

  test('A missed beat ends the combo after the next chorus grace period', () {
    final performance = FestivalPerformance();
    _at(performance, 22);
    performance.setVolume(FestivalZone.back, 50);
    performance.queue(FestivalZone.front);
    _at(performance, 34);
    performance.setVolume(FestivalZone.back, 0);
    _at(performance, 55);
    expect(performance.combo, 18);
    _at(performance, 55.5);
    expect(performance.combo, 0);
    expect(performance.bestCombo, 18);
  });

  test(
    'One rescue per chorus keeps the combo without awarding missed beats',
    () {
      final performance = FestivalPerformance();
      _at(performance, 22);
      performance.setVolume(FestivalZone.back, 50);
      performance.queue(FestivalZone.front);
      _at(performance, 26);
      performance.setVolume(FestivalZone.back, 75);
      _at(performance, 27);
      expect(performance.combo, 3);
      expect(performance.rescueBeats, 2);
      expect(performance.needsRescue(FestivalZone.back), isTrue);
      expect(performance.needsRescue(FestivalZone.front), isFalse);
      final scoreBeforeCorrection = performance.score;
      performance.setVolume(FestivalZone.back, 50);
      _at(performance, 28);
      expect(performance.combo, 4);
      expect(performance.rescueBeats, 0);
      expect(performance.score - scoreBeforeCorrection, 2);

      performance.setVolume(FestivalZone.back, 75);
      _at(performance, 29);
      expect(performance.rescueBeats, 0);
      expect(performance.combo, 0);
      expect(performance.comboBreak?.zoneLabel, '뒷줄');
    },
  );

  test(
    'A failed rescue restores the mix exactly three seconds before the miss',
    () {
      final performance = FestivalPerformance();
      _at(performance, 22);
      performance.setVolume(FestivalZone.back, 50);
      performance.queue(FestivalZone.front);
      _at(performance, 26);
      performance.setVolume(FestivalZone.back, 75);
      _at(performance, 28);
      final lost = performance.comboBreak!;
      expect(lost.zoneLabel, '뒷줄');
      expect(lost.missedTick - lost.rewindTick, 24);

      final practice = FestivalPerformance.rewind(
        lost,
        venue: FestivalVenue.neighborhood,
      );
      expect(practice.position, const Duration(milliseconds: 23500));
      expect(practice.volume(FestivalZone.back), 50);
      expect(practice.signal(FestivalZone.front), SignalState.queued);
      practice.advanceTicks(48);
      expect(practice.finished, isTrue);
      expect(practice.recoverySucceeded, isTrue);
    },
  );

  test(
    'The generator stop changes which final chorus strategy scores best',
    () {
      int score({required bool mastery, required bool wait}) {
        final performance = FestivalPerformance(
          practiceChorus: 3,
          mastery: mastery,
        );
        _at(performance, wait ? (mastery ? 80.5 : 79.5) : 78);
        performance.queue(wait ? FestivalZone.back : FestivalZone.front);
        _at(performance, 90);
        return performance.score;
      }

      expect(
        score(mastery: false, wait: true),
        greaterThan(score(mastery: false, wait: false)),
      );
      expect(
        score(mastery: true, wait: false),
        greaterThan(score(mastery: true, wait: true)),
      );
    },
  );

  test('Generator follows the timeline even without a queued signal', () {
    final performance = FestivalPerformance(practiceChorus: 3);
    expect(performance.eventNotice, ('발전기 가동', 4));
    _at(performance, 76);
    expect(performance.generatorRunning, isTrue);
    expect(performance.generatorLoopPosition, Duration.zero);
    expect(performance.status(FestivalZone.back), CrowdStatus.quiet);
    expect(performance.eventNotice, ('발전기 정지', 7));
    _at(performance, 79.5);
    expect(performance.takeRecentCues(), [FestivalCue.generatorStop]);
    expect(performance.generatorRunning, isFalse);
    expect(performance.recommendedSignalZone, FestivalZone.back);
    expect(performance.startsBothRows(FestivalZone.back), isTrue);
    expect(performance.cueFor(FestivalZone.front), MixCue.signal);
    expect(performance.cueFor(FestivalZone.back), MixCue.signal);
    expect(performance.status(FestivalZone.back), CrowdStatus.ready);
    _at(performance, 82.5);
    expect(performance.status(FestivalZone.back), CrowdStatus.ready);
    _at(performance, 83);
    expect(performance.status(FestivalZone.back), CrowdStatus.singing);
    _at(performance, 90);
    expect(performance.score, 21);
    expect(performance.finished, isTrue);
  });

  test('Replay uses the original audio offset and drops expired cues', () {
    final performance = FestivalPerformance();
    _at(performance, 92);
    expect(performance.takeRecentCues(), isEmpty);
    final replay = FestivalPerformance.replay(
      performance.chorusResult(3).checkpoint,
    );
    expect(replay.position, const Duration(seconds: 74));
    expect(replay.takeRecentCues(), isEmpty);
    _at(replay, 78.25);
    expect(replay.generatorLoopPosition, const Duration(milliseconds: 250));
  });
}
