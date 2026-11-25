import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/performance_controls.dart';

void _at(FestivalPerformance performance, double seconds) {
  performance.advanceTicks((seconds * 8).round() - performance.tick);
}

void main() {
  test('First chorus reserves once and scores each occupied half-second', () {
    final performance = FestivalPerformance();
    const front = FestivalZone.front;
    const back = FestivalZone.back;
    _at(performance, 22);
    expect(performance.remainingBeats, 4);
    performance.setVolume(back, 50);
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
    expect(performance.holdingCombo, isTrue);

    _at(performance, 36);
    expect(performance.eventNotice.$1, contains('앞줄 볼륨을 내려요'));
    performance.setVolume(front, 40);
    expect(performance.eventNotice.$1, contains('두 줄 ✓ 준비'));
    expect(performance.status(front), CrowdStatus.quiet);
    expect(performance.advancePastInterlude(), isFalse);
    _at(performance, 38);
    expect(performance.nextSignalCountdown?.remaining, 8);
    expect(performance.advancePastInterlude(), isTrue);
    expect(performance.position, const Duration(seconds: 46));
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
    _at(performance, 62);
    expect(performance.eventNotice.$1, startsWith('후렴 2 · 함께 떼창'));
    expect(performance.nextSignalCountdown, (
      chorus: 3,
      remaining: 16,
      total: 16,
    ));
    expect(performance.combo, 36);
    _at(performance, 64);
    expect(performance.eventNotice.$1, contains('발전기가 켜지면 뒷줄'));
    _at(performance, 66);
    expect(performance.advancePastInterlude(), isTrue);
    expect(performance.position, const Duration(seconds: 74));
    expect(performance.eventNotice, ('발전기 가동', 4));
    expect(performance.nextSignalCountdown?.remaining, 8);
    _at(performance, 78);
    expect(performance.nextSignalCountdown, isNull);
    expect(performance.signal(front), SignalState.available);
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
    _at(performance, 100);
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
