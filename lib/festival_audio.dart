import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'festival_performance.dart';

final _context = AudioContext(
  android: const AudioContextAndroid(
    audioFocus: AndroidAudioFocus.none,
    usageType: AndroidUsageType.game,
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
);

class FestivalAudio {
  FestivalAudio(double volume)
    : _music = _Clip('festival-first-show.wav', volume * .62),
      _generator = _Clip('sfx/generator-loop.wav', volume * .27, loop: true),
      _effects = {
        FestivalCue.call: _Clip('sfx/laureol-call.wav', volume * .78),
        FestivalCue.applause: _Clip('sfx/crowd-clap.wav', volume * .43),
        FestivalCue.singalong: _Clip('sfx/crowd-singalong.wav', volume * .62),
        FestivalCue.generatorStop: _Clip(
          'sfx/generator-stop.wav',
          volume * .36,
        ),
      },
      _warnings = {
        1: _Clip('sfx/front-mix-warning.wav', volume * .52),
        2: _Clip('sfx/back-mix-warning.wav', volume * .52),
        3: _Clip('sfx/both-mix-warning.wav', volume * .52),
      };

  final _Clip _music;
  final _Clip _generator;
  final Map<FestivalCue, _Clip> _effects;
  final Map<int, _Clip> _warnings;
  bool _running = false;
  bool _generatorPlaying = false;
  int _generation = 0;
  int _lastCheckedTick = 0;
  double _musicGain = 1;
  FestivalPerformance? _warningPerformance;
  int _heardWarnings = 0;
  int _lastWarningTick = -8;

  Future<void> start(FestivalPerformance performance) async {
    final generation = ++_generation;
    _running = true;
    _lastCheckedTick = performance.tick;
    _musicGain = performance.musicGain;
    bool current() => _running && generation == _generation;
    try {
      await _music
          .play(performance.position, current, gain: _musicGain)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Gameplay can proceed if the device has not prepared audio in time.
      if (current()) pause();
    }
    if (!current()) return;
    update(performance);
    for (final effect in _effects.values) {
      unawaited(effect.prepare());
    }
    for (final warning in _warnings.values) {
      unawaited(warning.prepare());
    }
    unawaited(_generator.prepare());
  }

  void update(FestivalPerformance performance) {
    final cues = performance.takeRecentCues();
    if (!_running) return;
    final generation = _generation;
    bool current() => _running && generation == _generation;

    final gain = performance.musicGain;
    if (gain != _musicGain) {
      _musicGain = gain;
      unawaited(_music.setGain(gain, current));
    }
    if (performance.generatorRunning != _generatorPlaying) {
      _generatorPlaying = performance.generatorRunning;
      if (_generatorPlaying) {
        unawaited(
          _generator.play(
            performance.generatorLoopPosition,
            () => current() && _generatorPlaying,
          ),
        );
      } else {
        unawaited(_generator.stop());
      }
    }
    for (final cue in cues) {
      unawaited(_effects[cue]!.play(Duration.zero, current));
    }
    _updateMixWarnings(performance, current);
    if (performance.tick - _lastCheckedTick >= 16) {
      _lastCheckedTick = performance.tick;
      unawaited(_music.correctDrift(() => performance.position, current));
    }
  }

  void _updateMixWarnings(
    FestivalPerformance performance,
    bool Function() current,
  ) {
    if (!identical(performance, _warningPerformance)) {
      _warningPerformance = performance;
      _heardWarnings = 0;
      _lastWarningTick = performance.tick - 8;
    }
    final mask = performance.volumeWarningMask;
    _heardWarnings &= mask;
    final unheard = mask & ~_heardWarnings;
    if (unheard == 0 ||
        performance.beatPhase != 0 ||
        performance.tick - _lastWarningTick < 8) {
      return;
    }
    _heardWarnings |= unheard;
    _lastWarningTick = performance.tick;
    unawaited(_warnings[unheard]!.play(Duration.zero, current));
  }

  void pause() {
    _running = false;
    _generation++;
    _generatorPlaying = false;
    unawaited(_music.pause());
    unawaited(_generator.stop());
    for (final clip in _effects.values) {
      unawaited(clip.stop());
    }
    for (final clip in _warnings.values) {
      unawaited(clip.stop());
    }
  }

  Future<void> dispose() {
    _running = false;
    _generation++;
    return Future.wait([
      _music.dispose(),
      _generator.dispose(),
      for (final clip in _effects.values) clip.dispose(),
      for (final clip in _warnings.values) clip.dispose(),
    ]);
  }
}

class FestivalResultAudio {
  FestivalResultAudio(double volume)
    : _chime = _Clip('sfx/result-chime.wav', volume * .58);

  final _Clip _chime;
  bool _active = true;

  Future<void> play() => _chime.play(Duration.zero, () => _active);

  void stop() {
    _active = false;
    unawaited(_chime.stop());
  }

  Future<void> dispose() {
    _active = false;
    return _chime.dispose();
  }
}

class _Clip {
  _Clip(this.asset, this.volume, {this.loop = false});

  final String asset;
  final double volume;
  final bool loop;
  AudioPlayer? _player;
  Future<void> _pending = Future.value();
  bool _used = false;
  bool _disposed = false;
  bool _checkingDrift = false;

  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } on Exception catch (error) {
        debugPrint('Festival audio ($asset): $error');
      }
    });
    return _pending;
  }

  Future<AudioPlayer> _load() async {
    if (_player case final player?) return player;
    final player = AudioPlayer()..positionUpdater = null;
    try {
      await player.setAudioContext(_context);
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await player.setVolume(volume);
      await player.setSource(AssetSource('audio/$asset'));
      _player = player;
      return player;
    } on Exception {
      await player.dispose();
      rethrow;
    }
  }

  Future<void> prepare() => _enqueue(() async {
    if (!_disposed) await _load();
  });

  Future<void> play(
    Duration position,
    bool Function() current, {
    double? gain,
  }) => _enqueue(() async {
    if (_disposed || !current()) return;
    final player = await _load();
    if (_disposed || !current()) return;
    if (gain != null) await player.setVolume(volume * gain);
    if (_disposed || !current()) return;
    if (position != Duration.zero || _used) await player.seek(position);
    if (_disposed || !current()) return;
    await player.resume();
    _used = true;
  });

  Future<void> setGain(double gain, bool Function() current) =>
      _enqueue(() async {
        if (_disposed || !current()) return;
        await _player?.setVolume(volume * gain);
      });

  Future<void> pause() => _enqueue(() async {
    if (_player case final player? when player.state == PlayerState.playing) {
      await player.pause();
    }
  });

  Future<void> stop() => _enqueue(() async {
    if (_player case final player?
        when player.state == PlayerState.playing ||
            player.state == PlayerState.paused) {
      await player.stop();
    }
  });

  Future<void> correctDrift(
    Duration Function() expected,
    bool Function() current,
  ) async {
    if (_checkingDrift) return;
    _checkingDrift = true;
    try {
      await _enqueue(() async {
        if (_disposed || !current()) return;
        final player = _player;
        if (player == null || player.state != PlayerState.playing) return;
        final position = await player.getCurrentPosition();
        if (position == null || _disposed || !current()) return;
        final target = expected();
        if ((position - target).inMilliseconds.abs() > 200) {
          await player.seek(target);
        }
      });
    } finally {
      _checkingDrift = false;
    }
  }

  Future<void> dispose() {
    _disposed = true;
    return _enqueue(() async {
      await _player?.dispose();
      _player = null;
    });
  }
}
