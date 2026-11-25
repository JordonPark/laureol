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
    performance.queue(front);
    performance.queue(back);
    expect(performance.signal(front), SignalState.queued);
    expect(performance.signal(back), SignalState.waiting);

    _at(performance, 24);
    expect(performance.status(front), CrowdStatus.singing);
    expect(performance.signal(back), SignalState.responding);
    _at(performance, 25);
    expect(performance.status(back), CrowdStatus.singing);
    expect(performance.waveFrame, 0);
    expect(performance.score, 1);
    _at(performance, 34);
    expect(performance.chorusScores, [28, 0, 0]);
  });

  test('Generator follows the timeline even without a queued signal', () {
    final performance = FestivalPerformance(practiceChorus: 3);
    expect(performance.eventNotice, ('발전기 가동', 4));
    _at(performance, 76);
    expect(performance.generatorRunning, isTrue);
    expect(performance.status(FestivalZone.back), CrowdStatus.quiet);
    expect(performance.eventNotice, ('발전기 정지', 7));
    _at(performance, 79.5);
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
}
