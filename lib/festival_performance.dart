import 'dart:math' as math;

import 'performance_controls.dart';

const festivalTick = Duration(milliseconds: 125);
const _ticksPerBeat = 4;
const _ticksPerSecond = 8;
const _interludeLength = 4 * _ticksPerSecond;
const _quickInterludeLength = 2 * _ticksPerSecond;
const _outroLength = 2 * _ticksPerSecond;
const _joinGrace = 3 * _ticksPerSecond;
const _frontProximityBoost = 14;
const _readyMinimum = 46;
const _readyMaximum = 58;
const _generatorStopTick = 79 * _ticksPerSecond + _ticksPerBeat;
const _rescueBeats = 2;
const _rewindTicks = 3 * _ticksPerSecond;
const _maxEarlySignalBeats = 3;
const comboEffectTicks = 12;

enum FestivalZone { front, back }

enum FestivalCue { call, applause, singalong, generatorStop }

enum FestivalVenue {
  neighborhood('동네 축제', '두 줄이 8박 연속 떼창하기', 'venue-neighborhood.png'),
  nightMarket('야외 야시장', '발전기가 꺼진 뒤 4박 안에 두 줄 합류시키기', 'venue-market.png');

  const FestivalVenue(this.title, this.mission, this.poster);

  final String title;
  final String mission;
  final String poster;

  String get posterAsset => 'docs/art/festival/$poster';
}

String _missingLabel(int mask) => switch (mask) {
  1 => '앞줄',
  2 => '뒷줄',
  _ => '두 줄',
};

typedef _MixSnapshot = ({
  int tick,
  List<int> volumes,
  List<CrowdStatus> levels,
  List<bool> singing,
  FestivalZone? reserved,
  int? reservedTick,
  bool signalSucceeded,
  int leadBeats,
  bool transferReady,
  int combo,
  bool joinedTogether,
  bool rescueUsed,
});

class ComboBreak {
  const ComboBreak._(
    this.chorus,
    this.beat,
    this.missedTick,
    this.combo,
    this._mask,
    this._mix,
    this._signalEarlierBeats,
  );

  final int chorus;
  final int beat;
  final int missedTick;
  final int combo;
  final int _mask;
  final _MixSnapshot _mix;
  final int _signalEarlierBeats;

  int get rewindTick => _mix.tick;
  String get zoneLabel => _missingLabel(_mask);
}

class ChorusCheckpoint {
  ChorusCheckpoint._(
    this.chorus,
    this.tick,
    List<int> volumes,
    List<CrowdStatus> levels,
    this._signalEarlierBeats,
  ) : _volumes = List.unmodifiable(volumes),
      _levels = List.unmodifiable(levels);

  final int chorus;
  final int tick;
  final List<int> _volumes;
  final List<CrowdStatus> _levels;
  final int _signalEarlierBeats;

  List<int> toRecord() => [
    chorus,
    tick,
    ..._volumes,
    ..._levels.map((level) => level.index),
    _signalEarlierBeats,
  ];

  static ChorusCheckpoint? fromRecord(Object? value) {
    if (value is! List ||
        (value.length != 6 && value.length != 7) ||
        value.any((item) => item is! int)) {
      return null;
    }
    final values = value.cast<int>();
    final chorus = values[0];
    final earlier = values.length == 7 ? values[6] : 0;
    if (chorus < 1 ||
        chorus > _choruses.length ||
        values[1] != _choruses[chorus - 1].preview * _ticksPerSecond ||
        values.skip(2).take(2).any((volume) => volume < 0 || volume > 100) ||
        values
            .skip(4)
            .take(2)
            .any((level) => level < 0 || level >= CrowdStatus.singing.index) ||
        earlier < 0 ||
        earlier > _maxEarlySignalBeats) {
      return null;
    }
    return ChorusCheckpoint._(
      chorus,
      values[1],
      values.sublist(2, 4),
      values.sublist(4, 6).map((level) => CrowdStatus.values[level]).toList(),
      earlier,
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

List<int> _signalOffsets(math.Random? random) {
  if (random == null) return List.filled(_choruses.length, 0);
  final offsets = List.generate(_maxEarlySignalBeats + 1, (i) => i)
    ..shuffle(random);
  return offsets.sublist(0, _choruses.length);
}

/// Deterministic 120 BPM festival simulation shared by audio-free UI states.
class FestivalPerformance {
  FestivalPerformance({
    this.practiceChorus,
    this.mastery = false,
    this.preserveRehearsalMix = false,
    this.venue = FestivalVenue.neighborhood,
    this.recovery,
    math.Random? signalTiming,
  }) : assert(
         practiceChorus == null || (practiceChorus >= 1 && practiceChorus <= 3),
       ),
       _signalEarlierBeats = _signalOffsets(signalTiming),
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
    FestivalVenue venue = FestivalVenue.neighborhood,
  }) {
    assert(!mastery || checkpoint.chorus == 3);
    final performance = FestivalPerformance(
      practiceChorus: checkpoint.chorus,
      mastery: mastery,
      venue: venue,
    );
    performance._tick = checkpoint.tick;
    performance._volumes.setAll(0, checkpoint._volumes);
    performance._levels.setAll(0, checkpoint._levels);
    performance._refreshLevels();
    performance._signalEarlierBeats[checkpoint.chorus - 1] =
        checkpoint._signalEarlierBeats;
    performance._saveCheckpoint(checkpoint.chorus);
    return performance;
  }

  factory FestivalPerformance.rewind(
    ComboBreak moment, {
    required FestivalVenue venue,
  }) {
    final performance = FestivalPerformance(
      practiceChorus: moment.chorus,
      recovery: moment,
      venue: venue,
    );
    final mix = moment._mix;
    performance._tick = mix.tick;
    performance._volumes.setAll(0, mix.volumes);
    performance._levels.setAll(0, mix.levels);
    performance._singing.setAll(0, mix.singing);
    performance._reserved = mix.reserved;
    performance._reservedTick = mix.reservedTick;
    performance._signalSucceeded = mix.signalSucceeded;
    performance._leadBeats = mix.leadBeats;
    performance._transferReady = mix.transferReady;
    performance._combo = mix.combo;
    performance._bestCombo = mix.combo;
    performance._joinedTogetherThisChorus = mix.joinedTogether;
    performance._rescueUsed = mix.rescueUsed;
    performance._signalEarlierBeats[moment.chorus - 1] =
        moment._signalEarlierBeats;
    return performance;
  }

  final int? practiceChorus;
  final bool mastery;
  final bool preserveRehearsalMix;
  final FestivalVenue venue;
  final ComboBreak? recovery;
  int get _generatorEnd =>
      _generatorStopTick +
      (mastery || venue == FestivalVenue.nightMarket ? 2 * _ticksPerBeat : 0);
  int _tick;
  final List<int> _signalEarlierBeats;
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
  ({int count, int tick})? _comboMilestone;
  int _togetherStreak = 0;
  int _bestTogetherStreak = 0;
  bool _marketMissionDone = false;
  bool _rescueUsed = false;
  int? _rescueUntil;
  int _missingMask = 0;
  ComboBreak? _pendingBreak;
  ComboBreak? _comboBreak;
  bool _recoverySucceeded = false;
  final _recentMixes = <int, _MixSnapshot>{};
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
  int get lightingTier => combo >= 40
      ? 3
      : combo >= 25
      ? 2
      : combo >= 10
      ? 1
      : 0;
  ({int count, int elapsedTicks})? get comboEffect {
    final milestone = _comboMilestone;
    if (milestone == null || _tick - milestone.tick >= comboEffectTicks) {
      return null;
    }
    return (count: milestone.count, elapsedTicks: _tick - milestone.tick);
  }

  ComboBreak? get comboBreak => _comboBreak;
  bool get recoverySucceeded => _recoverySucceeded;
  bool get missionAchieved => switch (venue) {
    FestivalVenue.neighborhood => _bestTogetherStreak >= 8,
    FestivalVenue.nightMarket => _marketMissionDone,
  };
  int get rescueBeats => _rescueUntil == null
      ? 0
      : (_rescueUntil! - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat;
  bool needsRescue(FestivalZone zone) =>
      rescueBeats > 0 && _missingMask & (1 << zone.index) != 0;
  bool get holdingCombo =>
      _combo > 0 &&
      (!_joinedTogetherThisChorus || rescueBeats > 0) &&
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
  bool get finished {
    final practice = practiceChorus;
    final end = practice == null
        ? _outroStart + _outroLength
        : _choruses[practice - 1].end * _ticksPerSecond;
    final drill = recovery;
    return _tick >= end ||
        (drill != null && _tick >= drill.missedTick + _rewindTicks);
  }

  int get _outroStart => _choruses.last.end * _ticksPerSecond;

  double get musicGain => practiceChorus == null
      ? 1 - (_tick - _outroStart).clamp(0, _outroLength) / _outroLength
      : 1;

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
    if (practiceChorus != null) return;
    if (ticksUntilMainConcert > 0) {
      advanceTicks(ticksUntilMainConcert);
    } else if (ticksUntilMainConcert == 0) {
      _saveCheckpoint(1);
    }
  }

  int get ticksUntilMainConcert =>
      _choruses.first.preview * _ticksPerSecond - _tick;

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

  int _signalOpensAt(_Chorus chorus) =>
      chorus.opens * _ticksPerSecond -
      (chorus.number == 0
          ? 0
          : _signalEarlierBeats[chorus.number - 1] * _ticksPerBeat);

  bool _isOpen(_Chorus chorus) =>
      _tick >= _signalOpensAt(chorus) &&
      _tick < chorus.closes * _ticksPerSecond;

  ({_Chorus previous, _Chorus next})? get _interlude {
    if (practiceChorus != null) return null;
    for (var index = 1; index < _choruses.length; index++) {
      final previous = _choruses[index - 1];
      final next = _choruses[index];
      if (seconds >= previous.end && _tick < _signalOpensAt(next)) {
        return (previous: previous, next: next);
      }
    }
    return null;
  }

  ({int chorus, int remaining, int total})? get nextSignalCountdown {
    final interlude = _interlude;
    if (interlude == null) return null;
    final length = _interludeLengthForCurrentMix;
    final cut = interlude.previous.end * _ticksPerSecond + length;
    final preview = interlude.next.preview * _ticksPerSecond;
    final target = _signalOpensAt(interlude.next);
    final skipped = preview - _tick.clamp(cut, preview);
    return (
      chorus: interlude.next.number,
      remaining:
          (target - _tick - skipped + _ticksPerBeat - 1) ~/ _ticksPerBeat,
      total: (length + target - preview) ~/ _ticksPerBeat,
    );
  }

  /// After the sound check, jump to the next cue on the same musical beat.
  /// Returns true if the music needs to seek to the new position.
  bool advancePastInterlude() {
    final interlude = _interlude;
    if (interlude == null) return false;
    final preview = interlude.next.preview * _ticksPerSecond;
    if (_tick >= preview) return false;
    final cut =
        interlude.previous.end * _ticksPerSecond +
        _interludeLengthForCurrentMix;
    if (_tick < cut) return false;
    advanceTicks(preview - _tick + _tick % _ticksPerBeat);
    return true;
  }

  int get _interludeLengthForCurrentMix =>
      _mixLevel(FestivalZone.front) == CrowdStatus.ready &&
          _mixLevel(FestivalZone.back) == CrowdStatus.ready
      ? _quickInterludeLength
      : _interludeLength;

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
    if (rescueBeats > 0) {
      return (
        '${_missingLabel(_missingMask)} 볼륨 복구 · $rescueBeats박 안에 ✓ 준비',
        null,
      );
    }
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
    if (seconds >= 78 && seconds < 81 && _reserved == null) {
      if (generatorRunning) {
        return (
          '앞줄 먼저 시작 · 또는 발전기 정지까지 기다려요',
          (_generatorEnd - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat,
        );
      }
      return (
        startsBothRows(FestivalZone.back)
            ? '발전기 정지 · 두 줄 동시 시작 가능'
            : '발전기 정지 · 목표 볼륨에 맞춰요',
        null,
      );
    }
    if (due != null && _tick < due.$2) {
      return (due.$1, (due.$2 - _tick + _ticksPerBeat - 1) ~/ _ticksPerBeat);
    }
    if (_tick >= _generatorEnd && seconds < 82) return ('발전기 정지 완료', null);
    if (_marketNoise) return ('야시장 소음 · 뒷줄 볼륨을 올려요', null);
    final interlude = _interlude;
    if (interlude != null) {
      return (_interludeNotice(interlude.previous, interlude.next), null);
    }
    if (seconds >= 48 && seconds < 50) return ('앞줄 체감 볼륨 증가', null);
    final chorus = _chorusAt(_tick);
    if (chorus != null &&
        chorus.number == 1 &&
        _tick < _signalOpensAt(chorus)) {
      final instruction = switch (_levels[FestivalZone.front.index]) {
        CrowdStatus.quiet => '앞줄 볼륨을 올려 ✓ 준비에 맞춰요',
        CrowdStatus.loud => '앞줄 볼륨을 내려 ✓ 준비에 맞춰요',
        _ => _rearStatusHint ?? '두 줄 ✓ 준비 · 노란 신호를 기다려요',
      };
      return (instruction, null);
    }
    if (signalQueued) return ('신호 예약 · 박자에 맞춰 떼창이 시작돼요', null);
    if (chorus != null && _reserved == null && _isOpen(chorus)) {
      return (
        recommendedSignalZone == null
            ? '목표 범위에 볼륨을 맞춰요'
            : '노란 ‘라우럴!’ 버튼으로 신호를 보내요',
        null,
      );
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

  bool get _marketNoise =>
      venue == FestivalVenue.nightMarket && seconds >= 24 && seconds < 28;

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

  ({int minimum, int maximum}) readyVolumeRange(FestivalZone zone) {
    final modifier = _mixModifier(zone);
    return (
      minimum: _readyMinimum - modifier,
      maximum: _readyMaximum - modifier,
    );
  }

  FestivalZone? get recommendedSignalZone {
    const front = FestivalZone.front;
    const back = FestivalZone.back;
    if (signal(front) != SignalState.available) return null;
    if (startsBothRows(back) || _levels[front.index] != CrowdStatus.ready) {
      return _levels[back.index] == CrowdStatus.ready ? back : null;
    }
    return front;
  }

  SignalState get sharedSignal =>
      signal(_reserved ?? recommendedSignalZone ?? FestivalZone.front);

  bool get bothRowsReady =>
      _levels.every((level) => level == CrowdStatus.ready);

  bool startsBothRows(FestivalZone zone) =>
      zone == FestivalZone.back &&
      _chorusAt(_tick)?.number == 3 &&
      _tick >= _generatorEnd &&
      bothRowsReady;

  double get beatPhase => (_tick % _ticksPerBeat) / _ticksPerBeat;
  bool get hasLiveRhythm => !finished && seconds < _choruses.last.end;

  int get volumeWarningMask {
    if (!hasLiveRhythm) return 0;
    return (_mixLevel(FestivalZone.front) == CrowdStatus.ready ? 0 : 1) |
        (_mixLevel(FestivalZone.back) == CrowdStatus.ready ? 0 : 2);
  }

  MixCue cueFor(FestivalZone zone) {
    if (finished || seconds >= _choruses.last.end) return MixCue.none;
    if (_mixLevel(zone) != CrowdStatus.ready) return MixCue.adjust;
    final signalZone = recommendedSignalZone;
    return signalZone == zone ||
            (signalZone == FestivalZone.back &&
                startsBothRows(FestivalZone.back))
        ? MixCue.signal
        : MixCue.none;
  }

  CrowdStatus status(FestivalZone zone) {
    final level = _mixLevel(zone);
    return _singing[zone.index] && level == CrowdStatus.ready
        ? CrowdStatus.singing
        : level;
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
    final previousWarnings = volumeWarningMask;
    _volumes[zone.index] = value.clamp(0, 100);
    _refreshLevels();
    if (previousWarnings & ~volumeWarningMask != 0) {
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
      if (practiceChorus == null && current != null && current.number > 0) {
        _rememberMix();
      }
    }
  }

  void _saveCheckpoint(int chorus) {
    _checkpoints[chorus - 1] = ChorusCheckpoint._(
      chorus,
      _tick,
      _volumes,
      _levels,
      _signalEarlierBeats[chorus - 1],
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
      _clearRescue();
      _combo++;
      if (_combo == 10 || _combo == 25 || _combo == 40) {
        _comboMilestone = (count: _combo, tick: _tick);
      }
      if (_combo > _bestCombo) _bestCombo = _combo;
      _togetherStreak++;
      if (_togetherStreak > _bestTogetherStreak) {
        _bestTogetherStreak = _togetherStreak;
      }
      if (beatStart >= _generatorEnd &&
          beatStart < _generatorEnd + 4 * _ticksPerBeat) {
        _marketMissionDone = true;
      }
      final drill = recovery;
      if (drill != null &&
          beatStart >= drill.missedTick &&
          beatStart <= drill.missedTick + _rescueBeats * _ticksPerBeat) {
        _recoverySucceeded = true;
      }
    } else if (_joinedTogetherThisChorus ||
        beatStart >= chorus.start * _ticksPerSecond + _joinGrace) {
      _togetherStreak = 0;
      if (_combo > 0) _handleMiss(chorus, beatStart);
    }
  }

  void _handleMiss(_Chorus chorus, int beatStart) {
    final missing = (_singing[0] ? 0 : 1) | (_singing[1] ? 0 : 2);
    final mix = _recentMixes[beatStart - _rewindTicks];
    if (_rescueUntil == null && mix != null) {
      final firstBeat = chorus.start * _ticksPerSecond;
      _pendingBreak = ComboBreak._(
        chorus.number,
        (beatStart - firstBeat) ~/ _ticksPerBeat + 1,
        beatStart,
        _combo,
        missing,
        mix,
        _signalEarlierBeats[chorus.number - 1],
      );
    }
    final end = chorus.end * _ticksPerSecond;
    if (_rescueUntil != null && _tick < _rescueUntil!) {
      _missingMask = missing;
      return;
    }
    if (!_rescueUsed && _joinedTogetherThisChorus && _tick < end) {
      _rescueUsed = true;
      _rescueUntil = (_tick + _rescueBeats * _ticksPerBeat).clamp(_tick, end);
      _missingMask = missing;
      return;
    }
    final lost = _pendingBreak;
    if (lost != null &&
        (_comboBreak == null || lost.combo > _comboBreak!.combo)) {
      _comboBreak = lost;
    }
    _combo = 0;
    _clearRescue();
  }

  void _clearRescue() {
    _rescueUntil = null;
    _missingMask = 0;
    _pendingBreak = null;
  }

  void _rememberMix() {
    _recentMixes[_tick] = (
      tick: _tick,
      volumes: List.of(_volumes),
      levels: List.of(_levels),
      singing: List.of(_singing),
      reserved: _reserved,
      reservedTick: _reservedTick,
      signalSucceeded: _signalSucceeded,
      leadBeats: _leadBeats,
      transferReady: _transferReady,
      combo: _combo,
      joinedTogether: _joinedTogetherThisChorus,
      rescueUsed: _rescueUsed,
    );
    _recentMixes.removeWhere(
      (tick, _) => tick < _tick - _rewindTicks - _ticksPerBeat,
    );
  }

  void _refreshLevels() {
    for (final zone in FestivalZone.values) {
      _levels[zone.index] = _levelFor(zone.index, _volumeModifier(zone));
    }
  }

  int _volumeModifier(FestivalZone zone) => zone == FestivalZone.front
      ? (seconds >= 48 ? _frontProximityBoost : 0)
      : generatorRunning
      ? -16
      : _marketNoise
      ? -10
      : 0;

  int _mixModifier(FestivalZone zone) =>
      zone == FestivalZone.front && seconds < 48 && _interlude != null
      ? _frontProximityBoost
      : _volumeModifier(zone);

  CrowdStatus _mixLevel(FestivalZone zone) {
    final modifier = _mixModifier(zone);
    return modifier == _volumeModifier(zone)
        ? _levels[zone.index]
        : _levelFor(zone.index, modifier);
  }

  CrowdStatus _levelFor(int index, int modifier) {
    final heard = _volumes[index] + modifier;
    final margin =
        _levels[index] == CrowdStatus.ready &&
            (!preserveRehearsalMix || concertStarted)
        ? 2
        : 0;
    return heard < _readyMinimum - margin
        ? CrowdStatus.quiet
        : heard > _readyMaximum + margin
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
    _togetherStreak = 0;
    _rescueUsed = false;
    _clearRescue();
    _transferReady = false;
    _waveTick = null;
  }

  void _applyBeat(_Chorus chorus) {
    if (_tick < chorus.start * _ticksPerSecond) return;
    if (_tick == _reservedTick) {
      _signalSucceeded = _levels[_reserved!.index] == CrowdStatus.ready;
      if (startsBothRows(_reserved!)) {
        _transferReady = true;
      }
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
