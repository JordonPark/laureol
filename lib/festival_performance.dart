import 'performance_controls.dart';

const festivalTick = Duration(milliseconds: 125);
const _ticksPerBeat = 4;
const _ticksPerSecond = 8;
const _generatorStopTick = 79 * _ticksPerSecond + _ticksPerBeat;

enum FestivalZone { front, back }

class _Chorus {
  const _Chorus(this.number, this.preview, this.opens, this.closes, this.start);

  final int number;
  final int preview;
  final int opens;
  final int closes;
  final int start;
  int get end => start + 10;
}

const _rehearsal = _Chorus(0, 0, 14, 16, 14);
const _choruses = [
  _Chorus(1, 20, 22, 24, 24),
  _Chorus(2, 46, 50, 52, 52),
  _Chorus(3, 74, 78, 81, 80),
];

/// Deterministic 120 BPM festival simulation shared by audio-free UI states.
class FestivalPerformance {
  FestivalPerformance({this.practiceChorus})
    : assert(
        practiceChorus == null || (practiceChorus >= 1 && practiceChorus <= 3),
      ),
      _tick = practiceChorus == null
          ? 0
          : _choruses[practiceChorus - 1].preview * _ticksPerSecond {
    if (practiceChorus == 2 || practiceChorus == 3) {
      _volumes[FestivalZone.back.index] = 50;
    }
    if (practiceChorus == 3) _volumes[FestivalZone.front.index] = 35;
    _refreshLevels();
  }

  final int? practiceChorus;
  int _tick;
  final _volumes = [50, 40];
  final _levels = [CrowdStatus.quiet, CrowdStatus.quiet];
  final _singing = [false, false];
  final _halfPoints = [0, 0, 0];
  FestivalZone? _reserved;
  int? _reservedTick;
  bool _signalSucceeded = false;
  int _leadBeats = 0;
  bool _transferReady = false;
  int? _waveTick;
  bool _waveTowardBack = true;

  int get tick => _tick;
  int get seconds => _tick ~/ _ticksPerSecond;
  int get score => _halfPoints.reduce((a, b) => a + b) ~/ 2;
  List<int> get chorusScores =>
      _halfPoints.map((points) => points ~/ 2).toList(growable: false);
  int get maximum => practiceChorus == null ? 90 : 30;
  bool get finished =>
      _tick >=
      (practiceChorus == null ? 100 : _choruses[practiceChorus! - 1].end) *
          _ticksPerSecond;
  bool get generatorRunning =>
      _tick >= 76 * _ticksPerSecond && _tick < _generatorStopTick;
  bool get signalQueued => _reservedTick != null && _tick < _reservedTick!;
  bool get waveTowardBack => _waveTowardBack;
  int? get waveFrame {
    final from = _waveTick;
    return from != null && _tick - from < _ticksPerBeat ? _tick - from : null;
  }

  _Chorus? _chorusAt(int tick) {
    if (practiceChorus != null) {
      final chorus = _choruses[practiceChorus! - 1];
      return tick < chorus.end * _ticksPerSecond ? chorus : null;
    }
    if (tick < 20 * _ticksPerSecond) return _rehearsal;
    for (final chorus in _choruses) {
      if (tick >= chorus.preview * _ticksPerSecond &&
          tick < chorus.end * _ticksPerSecond) {
        return chorus;
      }
    }
    return null;
  }

  bool _isOpen(_Chorus chorus) =>
      _tick >= chorus.opens * _ticksPerSecond &&
      _tick < chorus.closes * _ticksPerSecond;

  int get remainingBeats {
    final chorus = _chorusAt(_tick);
    if (chorus == null) return 0;
    final reserved = _reservedTick;
    if (reserved != null && signalQueued) {
      return (reserved - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat;
    }
    return _isOpen(chorus)
        ? (chorus.closes * _ticksPerSecond - _tick + _ticksPerBeat - 1) ~/
              _ticksPerBeat
        : 0;
  }

  (String, int?) get eventNotice {
    if (seconds < 14 && practiceChorus == null) {
      return ('리허설 · 뒷줄 볼륨을 올려보세요', null);
    }
    final due = switch (seconds) {
      >= 46 && < 48 => ('앞줄 관객 접근', 48 * _ticksPerSecond),
      >= 74 && < 76 => ('발전기 가동', 76 * _ticksPerSecond),
      >= 76 && < 80 => ('발전기 정지', _generatorStopTick),
      _ => null,
    };
    if (due != null && _tick < due.$2) {
      return (due.$1, (due.$2 - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat);
    }
    if (seconds >= 79 && seconds < 82) return ('발전기 정지 완료', null);
    if (seconds >= 48 && seconds < 50) return ('앞줄 체감 볼륨 증가', null);
    final chorus = _chorusAt(_tick);
    if (chorus != null && _isOpen(chorus)) {
      return (chorus.number == 0 ? '리허설 · 신호를 예약해 보세요' : '시작 구역을 선택하세요', null);
    }
    if (chorus != null &&
        _tick >= (chorus.start + 3) * _ticksPerSecond &&
        _tick < chorus.end * _ticksPerSecond &&
        !_signalSucceeded) {
      return ('볼륨을 맞추면 떼창에 합류해요', null);
    }
    if (chorus != null && seconds >= chorus.start) {
      return (
        chorus.number == 0 ? '리허설 · 관객 반응을 확인하세요' : '후렴 ${chorus.number} 진행 중',
        null,
      );
    }
    return ('다음 신호 준비', null);
  }

  int volume(FestivalZone zone) => _volumes[zone.index];
  CrowdStatus status(FestivalZone zone) {
    final i = zone.index;
    return _singing[i] && _levels[i] == CrowdStatus.ready
        ? CrowdStatus.singing
        : _levels[i];
  }

  SignalState signal(FestivalZone zone) {
    final chorus = _chorusAt(_tick);
    if (chorus == null) return SignalState.waiting;
    if (signalQueued && _reserved == zone) return SignalState.queued;
    if (_signalSucceeded && _reserved != zone && !_singing[zone.index]) {
      return SignalState.responding;
    }
    return _reserved == null && _isOpen(chorus)
        ? SignalState.available
        : SignalState.waiting;
  }

  void setVolume(FestivalZone zone, int value) {
    _volumes[zone.index] = value.clamp(0, 100);
    _refreshLevels();
  }

  void queue(FestivalZone zone) {
    final chorus = _chorusAt(_tick);
    if (chorus == null || signal(zone) != SignalState.available) return;
    _reserved = zone;
    final nextBeat = (_tick ~/ _ticksPerBeat + 1) * _ticksPerBeat;
    final start = chorus.start * _ticksPerSecond;
    _reservedTick = nextBeat < start ? start : nextBeat;
  }

  void advanceTicks(int count) {
    for (var step = 0; step < count && !finished; step++) {
      final previous = _chorusAt(_tick);
      _tick++;
      if (_tick % _ticksPerBeat != 0) continue;

      _awardPreviousBeat(previous);
      final current = _chorusAt(_tick);
      if (current != previous) _resetChorus();
      if (_tick == 20 * _ticksPerSecond && practiceChorus == null) {
        _volumes[0] = 50;
        _volumes[1] = 40;
        _levels.fillRange(0, 2, CrowdStatus.quiet);
      }
      _refreshLevels();
      if (current != null) _applyBeat(current);
    }
  }

  void _awardPreviousBeat(_Chorus? chorus) {
    if (chorus == null || chorus.number == 0) return;
    final beatStart = _tick - _ticksPerBeat;
    if (beatStart < chorus.start * _ticksPerSecond ||
        beatStart >= chorus.end * _ticksPerSecond) {
      return;
    }
    _halfPoints[chorus.number - 1] +=
        (_singing[0] ? 1 : 0) +
        (_singing[1] ? 1 : 0) +
        (_singing.every((value) => value) ? 1 : 0);
  }

  void _refreshLevels() {
    for (var i = 0; i < 2; i++) {
      final modifier = i == 0
          ? (seconds >= 48 ? 14 : 0)
          : (generatorRunning ? -16 : 0);
      final heard = (_volumes[i] + _volumes[1 - i] / 5 + modifier).clamp(
        0,
        100,
      );
      final margin = _levels[i] == CrowdStatus.ready ? 2 : 0;
      _levels[i] = heard < 56 - margin
          ? CrowdStatus.quiet
          : heard > 68 + margin
          ? CrowdStatus.loud
          : CrowdStatus.ready;
    }
  }

  void _resetChorus() {
    _singing.fillRange(0, 2, false);
    _reserved = null;
    _reservedTick = null;
    _signalSucceeded = false;
    _leadBeats = 0;
    _transferReady = false;
    _waveTick = null;
  }

  void _applyBeat(_Chorus chorus) {
    if (_tick < chorus.start * _ticksPerSecond) return;
    if (_tick == _reservedTick) {
      _signalSucceeded = _levels[_reserved!.index] == CrowdStatus.ready;
    }

    final wasTogether = _singing.every((value) => value);
    final lead = _reserved?.index;
    if (_signalSucceeded && lead != null) {
      final other = 1 - lead;
      _leadBeats = _singing[lead] ? _leadBeats + 1 : 0;
      if (_leadBeats >= 2) _transferReady = true;
      final leadReady = _levels[lead] == CrowdStatus.ready;
      _singing[other] =
          _levels[other] == CrowdStatus.ready &&
          (_singing[other] || (_transferReady && leadReady));
      _singing[lead] = leadReady;
    } else if (_tick >= (chorus.start + 3) * _ticksPerSecond) {
      for (var i = 0; i < 2; i++) {
        _singing[i] = _levels[i] == CrowdStatus.ready;
      }
    }
    if (!wasTogether && _singing.every((value) => value)) {
      _waveTick = _tick;
      _waveTowardBack = _reserved != FestivalZone.back;
    }
  }
}
