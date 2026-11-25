import 'performance_controls.dart';

const festivalTick = Duration(milliseconds: 125);
const _ticksPerBeat = 4;
const _ticksPerSecond = 8;
const _interludeLength = 4 * _ticksPerSecond;
const _joinGrace = 3 * _ticksPerSecond;
const _frontProximityBoost = 14;
const _generatorStopTick = 79 * _ticksPerSecond + _ticksPerBeat;

enum FestivalZone { front, back }

enum FestivalCue { call, applause, singalong, generatorStop }

class ChorusCheckpoint {
  ChorusCheckpoint._(
    this.chorus,
    this.tick,
    List<int> volumes,
    List<CrowdStatus> levels,
  ) : _volumes = List.unmodifiable(volumes),
      _levels = List.unmodifiable(levels);

  final int chorus;
  final int tick;
  final List<int> _volumes;
  final List<CrowdStatus> _levels;

  List<int> toRecord() => [
    chorus,
    tick,
    ..._volumes,
    ..._levels.map((level) => level.index),
  ];

  static ChorusCheckpoint? fromRecord(Object? value) {
    if (value is! List ||
        value.length != 6 ||
        value.any((item) => item is! int)) {
      return null;
    }
    final values = value.cast<int>();
    final chorus = values[0];
    if (chorus < 1 ||
        chorus > _choruses.length ||
        values[1] != _choruses[chorus - 1].preview * _ticksPerSecond ||
        values.skip(2).take(2).any((volume) => volume < 0 || volume > 100) ||
        values
            .skip(4)
            .any((level) => level < 0 || level >= CrowdStatus.singing.index)) {
      return null;
    }
    return ChorusCheckpoint._(
      chorus,
      values[1],
      values.sublist(2, 4),
      values.skip(4).map((level) => CrowdStatus.values[level]).toList(),
    );
  }
}

class ChorusResult {
  ChorusResult._(this.checkpoint, this.score, List<int> beats)
    : _beats = List.unmodifiable(beats);

  final ChorusCheckpoint checkpoint;
  final int score;
  final List<int> _beats;

  int get chorus => checkpoint.chorus;
  int get beatCount => _beats.length;
  bool sangAt(FestivalZone zone, int beat) =>
      _beats[beat] & (1 << zone.index) != 0;
  int? firstBeat(FestivalZone zone) {
    final index = _beats.indexWhere((beat) => beat & (1 << zone.index) != 0);
    return index < 0 ? null : index + 1;
  }

  int get togetherBeats => _beats.where((beat) => beat == 3).length;
}

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
  FestivalPerformance({
    this.practiceChorus,
    this.mastery = false,
    this.preserveRehearsalMix = false,
  }) : assert(
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
    if (practiceChorus != null) _saveCheckpoint(practiceChorus!);
  }

  factory FestivalPerformance.replay(
    ChorusCheckpoint checkpoint, {
    bool mastery = false,
  }) {
    assert(!mastery || checkpoint.chorus == 3);
    final performance = FestivalPerformance(
      practiceChorus: checkpoint.chorus,
      mastery: mastery,
    );
    performance._tick = checkpoint.tick;
    performance._volumes.setAll(0, checkpoint._volumes);
    performance._levels.setAll(0, checkpoint._levels);
    performance._checkpoints[checkpoint.chorus - 1] = checkpoint;
    return performance;
  }

  final int? practiceChorus;
  final bool mastery;
  final bool preserveRehearsalMix;
  int get _generatorEnd =>
      _generatorStopTick + (mastery ? 2 * _ticksPerBeat : 0);
  int _tick;
  final _volumes = [50, 40];
  final _levels = [CrowdStatus.quiet, CrowdStatus.quiet];
  final _singing = [false, false];
  final _halfPoints = [0, 0, 0];
  final _checkpoints = List<ChorusCheckpoint?>.filled(3, null);
  final _chorusBeats = List.generate(3, (_) => <int>[]);
  final _cues = <(FestivalCue, int)>[];
  FestivalZone? _reserved;
  int? _reservedTick;
  bool _signalSucceeded = false;
  int _leadBeats = 0;
  int _combo = 0;
  int _bestCombo = 0;
  bool _joinedTogetherThisChorus = false;
  bool _transferReady = false;
  int? _waveTick;
  bool _waveTowardBack = true;

  int get tick => _tick;
  Duration get position => festivalTick * _tick;
  int get seconds => _tick ~/ _ticksPerSecond;
  bool get concertStarted => _tick >= _choruses.first.preview * _ticksPerSecond;
  int get score => _halfPoints.reduce((a, b) => a + b) ~/ 2;
  int get combo => _combo;
  int get bestCombo => _bestCombo;
  bool get holdingCombo =>
      _combo > 0 &&
      !_joinedTogetherThisChorus &&
      !finished &&
      seconds < _choruses.last.end;
  List<int> get chorusScores =>
      _halfPoints.map((points) => points ~/ 2).toList(growable: false);
  ChorusResult chorusResult(int chorus) {
    final i = chorus - 1;
    return ChorusResult._(
      _checkpoints[i]!,
      _halfPoints[i] ~/ 2,
      _chorusBeats[i],
    );
  }

  int get maximum => practiceChorus == null ? 90 : 30;
  bool get finished =>
      _tick >=
      (practiceChorus == null ? 100 : _choruses[practiceChorus! - 1].end) *
          _ticksPerSecond;
  bool get generatorRunning =>
      _tick >= 76 * _ticksPerSecond && _tick < _generatorEnd;
  Duration get generatorLoopPosition =>
      festivalTick * ((_tick - 76 * _ticksPerSecond) % (2 * _ticksPerSecond));
  bool get signalQueued => _reservedTick != null && _tick < _reservedTick!;
  bool get waveTowardBack => _waveTowardBack;

  void openRehearsalSignal() {
    if (practiceChorus != null) return;
    final start = _rehearsal.opens * _ticksPerSecond;
    if (_tick < start) advanceTicks(start - _tick);
  }

  void startMainConcert() {
    if (practiceChorus != null || concertStarted) return;
    advanceTicks(_choruses.first.preview * _ticksPerSecond - _tick);
  }

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

  ({_Chorus previous, _Chorus next})? get _interlude {
    if (practiceChorus != null) return null;
    for (var index = 1; index < _choruses.length; index++) {
      final previous = _choruses[index - 1];
      final next = _choruses[index];
      if (seconds >= previous.end && seconds < next.opens) {
        return (previous: previous, next: next);
      }
    }
    return null;
  }

  ({int chorus, int remaining, int total})? get nextSignalCountdown {
    final interlude = _interlude;
    if (interlude == null) return null;
    final cut = interlude.previous.end * _ticksPerSecond + _interludeLength;
    final preview = interlude.next.preview * _ticksPerSecond;
    final target = interlude.next.opens * _ticksPerSecond;
    final skipped = preview - _tick.clamp(cut, preview);
    return (
      chorus: interlude.next.number,
      remaining:
          (target - _tick - skipped + _ticksPerBeat - 1) ~/ _ticksPerBeat,
      total: (_interludeLength + target - preview) ~/ _ticksPerBeat,
    );
  }

  /// After the sound check, jump to the next cue on the same musical beat.
  /// Returns true if the music needs to seek to the new position.
  bool advancePastInterlude() {
    final interlude = _interlude;
    if (interlude == null) return false;
    final cut = interlude.previous.end * _ticksPerSecond + _interludeLength;
    final preview = interlude.next.preview * _ticksPerSecond;
    if (_tick < cut || _tick >= preview) return false;
    advanceTicks(preview - cut);
    return true;
  }

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
    if (finished) return ('공연 종료 · 결과를 확인해요', null);
    if (seconds < 14 && practiceChorus == null) {
      return status(FestivalZone.back) == CrowdStatus.ready
          ? ('리허설 · 노란 신호 버튼을 기다려요', null)
          : ('리허설 · 뒷줄 볼륨을 밀어 ✓ 준비에 맞춰요', null);
    }
    final due = switch (seconds) {
      >= 46 && < 48 => ('앞줄 관객 접근', 48 * _ticksPerSecond),
      >= 74 && < 76 => ('발전기 가동', 76 * _ticksPerSecond),
      >= 76 && < 81 => ('발전기 정지', _generatorEnd),
      _ => null,
    };
    if (due != null && _tick < due.$2) {
      return (due.$1, (due.$2 - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat);
    }
    if (_tick >= _generatorEnd && seconds < 82) return ('발전기 정지 완료', null);
    final interlude = _interlude;
    if (interlude != null) {
      return (_interludeNotice(interlude.previous, interlude.next), null);
    }
    if (seconds >= 48 && seconds < 50) return ('앞줄 체감 볼륨 증가', null);
    final chorus = _chorusAt(_tick);
    if (chorus != null && chorus.number == 1 && seconds < chorus.opens) {
      return ('첫 후렴 · 두 줄을 ✓ 준비에 맞춰요', null);
    }
    if (signalQueued) return ('신호 예약 · 박자에 맞춰 떼창이 시작돼요', null);
    if (chorus != null && _reserved == null && _isOpen(chorus)) {
      return ('노란 ‘라우럴!’ 버튼을 준비된 쪽에서 눌러요', null);
    }
    if (chorus != null &&
        _tick >= chorus.start * _ticksPerSecond + _joinGrace &&
        _tick < chorus.end * _ticksPerSecond &&
        !_signalSucceeded) {
      return ('볼륨을 ✓ 준비에 맞추면 떼창에 합류해요', null);
    }
    if (chorus != null && seconds >= chorus.start) {
      return (
        chorus.number == 0 ? '리허설 · 관객 반응을 확인하세요' : '후렴 ${chorus.number} 진행 중',
        null,
      );
    }
    if (seconds >= _choruses.last.end) return ('마지막 후렴 종료 · 공연 마무리 중', null);
    return holdingCombo ? ('두 줄을 다시 맞추면 콤보가 이어져요', null) : ('다음 신호 준비', null);
  }

  String _interludeNotice(_Chorus previous, _Chorus next) {
    if (seconds < previous.end + 2) {
      final together = chorusResult(previous.number).togetherBeats;
      return together == 0
          ? '후렴 ${previous.number} 종료 · 다음은 두 줄을 맞춰요'
          : '후렴 ${previous.number} · 함께 떼창 ${(together / 2).toStringAsFixed(1)}초';
    }
    final front = _levelFor(FestivalZone.front.index, _frontProximityBoost);
    if (next.number == 2) {
      final approach = seconds < 48 ? '앞줄 접근 대비' : '앞줄 접근';
      return switch (front) {
        CrowdStatus.quiet => '$approach · 앞줄 볼륨을 올려요',
        CrowdStatus.loud => '$approach · 앞줄 볼륨을 내려요',
        _ => _rearStatusHint ?? '다음 후렴 두 줄 ✓ 준비 · 볼륨을 유지해요',
      };
    }
    if (front != CrowdStatus.ready) {
      return front == CrowdStatus.quiet
          ? '발전기 대비 · 앞줄 볼륨을 올려요'
          : '발전기 대비 · 앞줄 볼륨을 내려요';
    }
    return _rearStatusHint ?? '두 줄 ✓ 준비 · 발전기가 켜지면 뒷줄을 살펴요';
  }

  String? get _rearStatusHint => switch (_levels[FestivalZone.back.index]) {
    CrowdStatus.quiet => '뒷줄 볼륨을 올려 ✓ 준비에 맞춰요',
    CrowdStatus.loud => '뒷줄 볼륨을 내려 ✓ 준비에 맞춰요',
    _ => null,
  };

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
    final previous = List.of(_levels);
    _volumes[zone.index] = value.clamp(0, 100);
    _refreshLevels();
    if (!finished &&
        _chorusAt(_tick) != null &&
        (previous[0] != CrowdStatus.ready && _levels[0] == CrowdStatus.ready ||
            previous[1] != CrowdStatus.ready &&
                _levels[1] == CrowdStatus.ready)) {
      _cues.add((FestivalCue.applause, _tick));
    }
  }

  List<FestivalCue> takeRecentCues() {
    final cues = {
      for (final (cue, at) in _cues)
        if (_tick - at <= 2) cue,
    };
    _cues.clear();
    return cues.toList(growable: false);
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
      if (_tick == _generatorEnd) _cues.add((FestivalCue.generatorStop, _tick));
      if (_tick % _ticksPerBeat != 0) continue;

      _awardPreviousBeat(previous);
      final current = _chorusAt(_tick);
      if (current != previous) _resetChorus();
      if (_tick == _choruses.first.preview * _ticksPerSecond &&
          practiceChorus == null &&
          !preserveRehearsalMix) {
        _volumes[0] = 50;
        _volumes[1] = 40;
        _levels.fillRange(0, 2, CrowdStatus.quiet);
      }
      _refreshLevels();
      if (current != null &&
          current.number != 0 &&
          _tick == current.preview * _ticksPerSecond) {
        _saveCheckpoint(current.number);
      }
      if (current != null) _applyBeat(current);
    }
  }

  void _saveCheckpoint(int chorus) {
    _checkpoints[chorus - 1] = ChorusCheckpoint._(
      chorus,
      _tick,
      _volumes,
      _levels,
    );
  }

  void _awardPreviousBeat(_Chorus? chorus) {
    if (chorus == null || chorus.number == 0) return;
    final beatStart = _tick - _ticksPerBeat;
    if (beatStart < chorus.start * _ticksPerSecond ||
        beatStart >= chorus.end * _ticksPerSecond) {
      return;
    }
    final index = chorus.number - 1;
    final together = _singing[0] && _singing[1];
    _chorusBeats[index].add((_singing[0] ? 1 : 0) | (_singing[1] ? 2 : 0));
    _halfPoints[index] +=
        (_singing[0] ? 1 : 0) + (_singing[1] ? 1 : 0) + (together ? 1 : 0);
    if (together) {
      _joinedTogetherThisChorus = true;
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
    } else if (_joinedTogetherThisChorus ||
        beatStart >= chorus.start * _ticksPerSecond + _joinGrace) {
      _combo = 0;
    }
  }

  void _refreshLevels() {
    for (var i = 0; i < 2; i++) {
      final modifier = i == 0
          ? (seconds >= 48 ? _frontProximityBoost : 0)
          : (generatorRunning ? -16 : 0);
      _levels[i] = _levelFor(i, modifier);
    }
  }

  CrowdStatus _levelFor(int index, int modifier) {
    final heard = (_volumes[index] + _volumes[1 - index] / 5 + modifier).clamp(
      0,
      100,
    );
    final margin = _levels[index] == CrowdStatus.ready ? 2 : 0;
    return heard < 56 - margin
        ? CrowdStatus.quiet
        : heard > 68 + margin
        ? CrowdStatus.loud
        : CrowdStatus.ready;
  }

  void _resetChorus() {
    _singing.fillRange(0, 2, false);
    _reserved = null;
    _reservedTick = null;
    _signalSucceeded = false;
    _leadBeats = 0;
    _joinedTogetherThisChorus = false;
    _transferReady = false;
    _waveTick = null;
  }

  void _applyBeat(_Chorus chorus) {
    if (_tick < chorus.start * _ticksPerSecond) return;
    if (_tick == _reservedTick) {
      _signalSucceeded = _levels[_reserved!.index] == CrowdStatus.ready;
      _cues.add((FestivalCue.call, _tick));
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
    } else if (_tick >= chorus.start * _ticksPerSecond + _joinGrace) {
      for (var i = 0; i < 2; i++) {
        _singing[i] = _levels[i] == CrowdStatus.ready;
      }
    }
    if (!wasTogether && _singing.every((value) => value)) {
      _waveTick = _tick;
      _waveTowardBack = _reserved != FestivalZone.back;
      _cues.add((FestivalCue.singalong, _tick));
    }
  }
}
