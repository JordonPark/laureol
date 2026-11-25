import 'dart:async';
import 'dart:math' as math;

// Retain the SDK widgets while this prototype has no external UI dependencies.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chorus_summary.dart';
import 'festival_audio.dart';
import 'festival_performance.dart';
import 'festival_records.dart';
import 'festival_scene.dart';
import 'performance_controls.dart';
import 'venue_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    LaureolApp(records: FestivalRecords(await SharedPreferences.getInstance())),
  );
}

const _night = Color(0xFF171329);
const _paper = Color(0xFFF7F2FF);
const _muted = Color(0xFFBDB8CD);
const _gold = Color(0xFFFFC46A);
const _mint = Color(0xFF7CE0C2);
const _uiFont = 'Laureol Sans';
const _titleArt = 'docs/art/festival/title-festival.png';
const _playGuide =
    '무대 아래 볼륨 노브를 위아래로 밀어요.\n'
    '노란 ‘라우럴!’ 버튼이 켜지면 신호를 보내요.\n'
    '두 줄이 함께 부르면 콤보가 이어져요.';

Future<void> _open(
  BuildContext context,
  Widget screen, {
  bool replace = false,
}) async {
  final route = CupertinoPageRoute<void>(builder: (_) => screen);
  final navigator = Navigator.of(context);
  if (replace) {
    await navigator.pushReplacement<void, void>(route);
  } else {
    await navigator.push(route);
  }
}

class LaureolApp extends StatelessWidget {
  const LaureolApp({super.key, required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '라우럴! 볼륨 좀 올려',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: _gold,
        scaffoldBackgroundColor: _night,
        barBackgroundColor: _night,
        textTheme: CupertinoTextThemeData(
          primaryColor: _gold,
          textStyle: TextStyle(
            color: _paper,
            fontSize: 16,
            fontFamily: _uiFont,
          ),
          actionTextStyle: TextStyle(
            color: _gold,
            fontSize: 16,
            fontFamily: _uiFont,
          ),
          navTitleTextStyle: TextStyle(
            color: _paper,
            fontSize: 17,
            fontFamily: _uiFont,
            fontWeight: FontWeight.w700,
          ),
          navActionTextStyle: TextStyle(
            color: _gold,
            fontSize: 16,
            fontFamily: _uiFont,
          ),
        ),
      ),
      home: _StartScreen(records: records),
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen({
    required this.title,
    required this.children,
    this.trailing,
    this.middle,
    this.compact = false,
    this.maxWidth = 520,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? middle;
  final bool compact;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 12.0 : 16.0;
    final content = ListView(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        compact ? 6 : 12,
        horizontal,
        compact ? 8 : 24,
      ),
      children: [
        for (final child in children)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 6 : 12),
            child: child,
          ),
      ],
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: middle ?? Text(title, style: const TextStyle(color: _paper)),
        previousPageTitle: '뒤로',
        trailing: trailing,
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed, {this.primary = false});

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: primary ? _gold : const Color(0xFF302746),
      foregroundColor: primary ? _night : _paper,
      minimumSize: const Size(48, 48),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _night,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final wide =
              viewport.maxWidth >= 570 &&
              viewport.maxWidth > viewport.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                left: wide ? viewport.maxWidth * .36 : 0,
                child: Image.asset(
                  _titleArt,
                  fit: BoxFit.cover,
                  alignment: wide ? const Alignment(0, .12) : Alignment.center,
                  excludeFromSemantics: true,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: wide
                      ? const LinearGradient(
                          colors: [_night, _night, Color(0x00171329)],
                          stops: [0, .31, .62],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xA0161329),
                            Color(0x00171329),
                            Color(0xD9171329),
                          ],
                          stops: [0, .38, 1],
                        ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, safe) {
                    final width = wide
                        ? safe.maxWidth * .51
                        : math.min(safe.maxWidth, 480.0);
                    final inset = (width * .065).clamp(16.0, 28.0);
                    final headline = ((width - inset * 2) * .20).clamp(
                      42.0,
                      74.0,
                    );
                    const top = 12.0;
                    const bottom = 18.0;
                    return Align(
                      alignment: wide
                          ? Alignment.centerLeft
                          : Alignment.topCenter,
                      child: SizedBox(
                        width: width,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            top,
                            inset,
                            bottom,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                safe.maxHeight - top - bottom,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: CupertinoButton(
                                        color: const Color(0xA0171329),
                                        borderRadius: BorderRadius.circular(6),
                                        minimumSize: const Size(44, 44),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        onPressed: () => _open(
                                          context,
                                          _SettingsScreen(records: records),
                                        ),
                                        child: const Text(
                                          '설정',
                                          style: TextStyle(color: _paper),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: wide ? 16 : 20),
                                    Text.rich(
                                      TextSpan(
                                        text: '라우럴!\n',
                                        style: TextStyle(
                                          color: _paper,
                                          fontSize: headline,
                                          height: 1,
                                          fontWeight: FontWeight.w800,
                                          shadows: const [
                                            Shadow(
                                              color: _night,
                                              offset: Offset(3, 4),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '볼륨 좀 올려',
                                            style: TextStyle(
                                              color: _gold,
                                              fontSize: headline * .46,
                                              height: 1.24,
                                            ),
                                          ),
                                        ],
                                      ),
                                      semanticsLabel: '라우럴! 볼륨 좀 올려',
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: wide ? 32 : 110,
                                  ),
                                  child: CupertinoButton(
                                    color: _gold,
                                    foregroundColor: _night,
                                    minimumSize: const Size(48, 58),
                                    borderRadius: BorderRadius.circular(8),
                                    onPressed: () => _open(
                                      context,
                                      records.rehearsalCompleted
                                          ? _SelectionScreen(records: records)
                                          : _PerformanceScreen(
                                              records: records,
                                              returnHome: true,
                                            ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.play_fill,
                                          size: 16,
                                        ),
                                        SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            '공연 시작',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectionScreen extends StatefulWidget {
  const _SelectionScreen({required this.records});

  final FestivalRecords records;

  @override
  State<_SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<_SelectionScreen> {
  Future<void> _play({
    ChorusCheckpoint? checkpoint,
    bool rehearse = false,
    FestivalVenue venue = FestivalVenue.neighborhood,
  }) async {
    await _open(
      context,
      _PerformanceScreen(
        records: widget.records,
        checkpoint: checkpoint,
        rehearse: rehearse,
        venue: venue,
        mastery: checkpoint != null,
        previousScore: checkpoint == null ? null : widget.records.masteryBest,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeWidth = MediaQuery.paddingOf(context).deflateSize(size).width;
    final sideBySide = safeWidth >= 620 && size.width > size.height;
    final compact = size.height < 480;
    final best = widget.records.concertBest;
    final masteryBest = widget.records.masteryBest;
    final neighborhood = VenueCard(
      venue: FestivalVenue.neighborhood,
      artHeight: compact ? 144 : 190,
      best: best?.score,
      onPlay: () => _play(),
    );
    final market = VenueCard(
      venue: FestivalVenue.nightMarket,
      artHeight: compact ? 144 : 158,
      best: widget.records.bestFor(FestivalVenue.nightMarket)?.score,
      onPlay: widget.records.nightMarketUnlocked
          ? () => _play(venue: FestivalVenue.nightMarket)
          : null,
    );
    return _Screen(
      title: '공연 선택',
      compact: compact,
      maxWidth: sideBySide ? 900 : 520,
      children: [
        if (sideBySide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: neighborhood),
              const SizedBox(width: 12),
              Expanded(child: market),
            ],
          )
        else ...[
          neighborhood,
          market,
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _SelectionShortcut(
              icon: CupertinoIcons.slider_horizontal_3,
              label: '조작 다시 연습',
              onPressed: () => _play(rehearse: true),
            ),
            if (best != null)
              _SelectionShortcut(
                icon: CupertinoIcons.bolt_fill,
                label: '숙련 후렴 도전',
                detail: masteryBest == null ? null : '최고 $masteryBest/30',
                onPressed: () => _play(checkpoint: best.checkpoint),
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectionShortcut extends StatelessWidget {
  const _SelectionShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.detail,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: const Color(0xFF252037),
      foregroundColor: _paper,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                if (detail case final record?)
                  Text(
                    record,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceScreen extends StatefulWidget {
  const _PerformanceScreen({
    required this.records,
    this.checkpoint,
    this.previousScore,
    this.previousResult,
    this.mastery = false,
    this.rehearse = false,
    this.returnHome = false,
    this.venue = FestivalVenue.neighborhood,
    this.recovery,
  });

  final FestivalRecords records;
  final ChorusCheckpoint? checkpoint;
  final int? previousScore;
  final ChorusResult? previousResult;
  final bool mastery;
  final bool rehearse;
  final bool returnHome;
  final FestivalVenue venue;
  final ComboBreak? recovery;

  @override
  State<_PerformanceScreen> createState() => _PerformanceScreenState();
}

enum _PauseAction { resume, restart, skipRehearsal, exit }

enum _RehearsalStep { volume, signal, response }

class _PerformanceScreenState extends State<_PerformanceScreen>
    with WidgetsBindingObserver {
  late FestivalPerformance _performance;
  FestivalAudio? _audio;
  Timer? _clock;
  int _clockGeneration = 0;
  bool _starting = false;
  bool _pauseOpen = false;
  bool _openingResults = false;
  _RehearsalStep? _rehearsalStep;
  FestivalZone? _focusedZone;
  int _readyPulse = 0;
  int _readyZones = 0;

  bool get _waitingForRehearsalInput =>
      _rehearsalStep == _RehearsalStep.volume ||
      _rehearsalStep == _RehearsalStep.signal;

  FestivalPerformance _newPerformance() {
    _readyZones = 0;
    final recovery = widget.recovery;
    if (recovery != null) {
      return FestivalPerformance.rewind(recovery, venue: widget.venue);
    }
    final checkpoint = widget.checkpoint;
    if (checkpoint != null) {
      return FestivalPerformance.replay(
        checkpoint,
        mastery: widget.mastery,
        venue: widget.venue,
      );
    }
    final guided = widget.rehearse || !widget.records.rehearsalCompleted;
    _rehearsalStep = guided ? _RehearsalStep.volume : null;
    _focusedZone = guided ? FestivalZone.back : null;
    final performance = FestivalPerformance(
      preserveRehearsalMix: guided,
      venue: widget.venue,
    );
    if (!guided) performance.startMainConcert();
    return performance;
  }

  Future<void> _rememberRehearsal() async {
    try {
      await widget.records.completeRehearsal();
    } on Exception {
      // A storage failure shouldn't interrupt the performance.
    }
  }

  void _changeVolume(FestivalZone zone, int value) {
    setState(() {
      _focusedZone = zone;
      final previous = FestivalZone.values.map(_performance.status).toList();
      _performance.setVolume(zone, value);
      var readyZones = 0;
      for (final audience in FestivalZone.values) {
        final before = previous[audience.index];
        final after = _performance.status(audience);
        if ((before == CrowdStatus.quiet || before == CrowdStatus.loud) &&
            (after == CrowdStatus.ready || after == CrowdStatus.singing)) {
          readyZones |= 1 << audience.index;
        }
      }
      if (readyZones != 0) {
        _readyZones = readyZones;
        _readyPulse++;
      }
    });
    _updateAudio();
  }

  void _finishVolumePractice() {
    if (_rehearsalStep != _RehearsalStep.volume ||
        _performance.status(FestivalZone.back) != CrowdStatus.ready) {
      return;
    }
    setState(() {
      _performance.openRehearsalSignal();
      _rehearsalStep = _RehearsalStep.signal;
    });
    if (widget.records.vibration) unawaited(HapticFeedback.selectionClick());
  }

  void _sendSignal(FestivalZone zone) {
    if (_performance.signal(zone) != SignalState.available) return;
    final rehearsing = _rehearsalStep == _RehearsalStep.signal;
    setState(() {
      _focusedZone = zone;
      _performance.queue(zone);
      if (rehearsing) _rehearsalStep = _RehearsalStep.response;
    });
    if (widget.records.vibration) unawaited(HapticFeedback.selectionClick());
    if (rehearsing) _resumeScene();
  }

  void _selectZone(FestivalZone zone) {
    setState(() => _focusedZone = zone);
  }

  Future<bool> _saveResult() async {
    try {
      return await widget.records.record(_performance);
    } on Exception {
      return false;
    }
  }

  Future<void> _showResults() async {
    if (_openingResults) return;
    _openingResults = true;
    final saved = await _saveResult();
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final checkpoint = widget.checkpoint;
    final recovery = widget.recovery;
    await _open(
      context,
      _ResultSound(
        volume: widget.records.volume / 100,
        child: recovery != null
            ? _RecoveryResults(
                records: widget.records,
                moment: recovery,
                venue: widget.venue,
                succeeded: _performance.recoverySucceeded,
              )
            : checkpoint == null
            ? _ResultsScreen(
                records: widget.records,
                score: _performance.score,
                bestCombo: _performance.bestCombo,
                returnHome: widget.returnHome,
                venue: widget.venue,
                missionAchieved: _performance.missionAchieved,
                comboBreak: _performance.comboBreak,
                results: [
                  for (var chorus = 1; chorus <= 3; chorus++)
                    _performance.chorusResult(chorus),
                ],
                saved: saved,
              )
            : _PracticeResultsScreen(
                records: widget.records,
                result: _performance.chorusResult(checkpoint.chorus),
                previous: widget.previousScore,
                previousResult: widget.previousResult,
                mastery: widget.mastery,
                venue: widget.venue,
                saved: saved,
              ),
      ),
      replace: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _performance = _newPerformance();
    if (widget.records.volume > 0) {
      _audio = FestivalAudio(widget.records.volume / 100);
    }
    WidgetsBinding.instance.addObserver(this);
    _resumeScene();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _clockGeneration++;
    final audio = _audio;
    if (audio != null) unawaited(audio.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_pauseOpen) _resumeScene();
    } else {
      _freezeScene();
    }
  }

  void _resumeScene() {
    if (_clock != null ||
        _starting ||
        _performance.finished ||
        _waitingForRehearsalInput) {
      return;
    }
    final audio = _audio;
    if (audio == null) {
      _startClock();
    } else {
      _starting = true;
      unawaited(_startAfterAudio(audio, ++_clockGeneration));
    }
  }

  Future<void> _startAfterAudio(FestivalAudio audio, int generation) async {
    await audio.start(_performance);
    if (!mounted || generation != _clockGeneration) return;
    _starting = false;
    _startClock();
  }

  void _freezeScene() {
    _clockGeneration++;
    _starting = false;
    _clock?.cancel();
    _clock = null;
    _audio?.pause();
  }

  void _updateAudio() {
    final audio = _audio;
    if (audio == null) {
      _performance.takeRecentCues();
    } else {
      audio.update(_performance);
    }
  }

  void _startClock() {
    var previousTick = 0;
    _clock = Timer.periodic(festivalTick, (timer) {
      late final bool skipped;
      late final bool rehearsalFinished;
      setState(() {
        _performance.advanceTicks(timer.tick - previousTick);
        rehearsalFinished =
            _rehearsalStep == _RehearsalStep.response &&
            _performance.concertStarted;
        if (rehearsalFinished) _rehearsalStep = null;
        skipped = _performance.advancePastInterlude();
      });
      if (rehearsalFinished) unawaited(_rememberRehearsal());
      previousTick = timer.tick;
      if (_performance.finished) {
        _freezeScene();
        unawaited(_showResults());
      } else if (skipped && _audio != null) {
        _freezeScene();
        _resumeScene();
      } else {
        _updateAudio();
      }
    });
  }

  Future<void> _pause() async {
    _pauseOpen = true;
    _freezeScene();
    final action = await showCupertinoDialog<_PauseAction>(
      context: context,
      builder: (dialog) => CupertinoAlertDialog(
        title: const Text('일시정지'),
        content: const Text(_playGuide),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialog, _PauseAction.resume),
            child: const Text('이어 하기'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialog, _PauseAction.restart),
            child: const Text('처음부터 다시'),
          ),
          if (_rehearsalStep != null)
            CupertinoDialogAction(
              onPressed: () =>
                  Navigator.pop(dialog, _PauseAction.skipRehearsal),
              child: const Text('연습 건너뛰기'),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialog, _PauseAction.exit),
            child: Text(
              widget.recovery != null
                  ? '전체 결과로'
                  : widget.returnHome
                  ? '시작 화면으로'
                  : widget.checkpoint == null || widget.mastery
                  ? '공연 선택으로'
                  : '전체 결과로',
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _pauseOpen = false;
    if (action == _PauseAction.exit) {
      Navigator.of(context).pop();
      return;
    }
    if (action == _PauseAction.restart) {
      setState(() {
        _performance = _newPerformance();
      });
    }
    if (action == _PauseAction.skipRehearsal) {
      setState(() {
        _rehearsalStep = null;
        _performance.startMainConcert();
      });
      unawaited(_rememberRehearsal());
    }
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) {
      _resumeScene();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _rehearsalStep == null
          ? _buildPerformance(context, constraints)
          : _buildRehearsal(context, constraints),
    );
  }

  Widget _pauseButton() => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(48, 40),
    onPressed: _performance.finished ? null : _pause,
    child: Semantics(label: '일시정지', child: Icon(CupertinoIcons.pause_fill)),
  );

  MixCue _mixCue(FestivalZone zone) {
    final rehearsal = _rehearsalStep;
    if (rehearsal == null) return _performance.cueFor(zone);
    if (zone == FestivalZone.front) return MixCue.none;
    return switch (rehearsal) {
      _RehearsalStep.volume =>
        _performance.status(zone) == CrowdStatus.ready
            ? MixCue.none
            : MixCue.adjust,
      _RehearsalStep.signal => MixCue.signal,
      _RehearsalStep.response => MixCue.none,
    };
  }

  ZoneControlCard _volumeControl(FestivalZone zone) {
    final performance = _performance;
    final rehearsal = _rehearsalStep;
    return ZoneControlCard(
      zone: zone == FestivalZone.front ? '앞줄' : '뒷줄',
      status: performance.status(zone),
      volume: performance.volume(zone),
      selected: _focusedZone == zone,
      needsRescue: performance.needsRescue(zone),
      onVolumeChanged: (value) => _changeVolume(zone, value),
      target: performance.readyVolumeRange(zone),
      cue: _mixCue(zone),
      enabled: rehearsal == null || rehearsal == _RehearsalStep.volume,
      onInteractionEnd: rehearsal == _RehearsalStep.volume
          ? _finishVolumePractice
          : null,
    );
  }

  FestivalScene _scene({required bool compact}) {
    final performance = _performance;
    final zone = _focusedZone;
    return FestivalScene(
      compact: compact,
      tick: performance.tick,
      front: performance.status(FestivalZone.front),
      back: performance.status(FestivalZone.back),
      generatorRunning: performance.generatorRunning,
      signalQueued: performance.signalQueued,
      waveFrame: performance.waveFrame,
      waveTowardBack: performance.waveTowardBack,
      focusedZone: zone,
      focusedVolume: zone == null ? null : performance.volume(zone),
      onZoneSelected: _rehearsalStep == null ? _selectZone : null,
      venue: performance.venue,
      lightingTier: performance.lightingTier,
      comboEffect: performance.comboEffect,
      frontCue: _mixCue(FestivalZone.front),
      backCue: _mixCue(FestivalZone.back),
      readyPulse: _readyPulse,
      readyZones: _readyZones,
    );
  }

  Widget _buildRehearsal(BuildContext context, BoxConstraints viewport) {
    final step = _rehearsalStep!;
    final status = _performance.status(FestivalZone.back);
    final (title, instruction) = switch (step) {
      _RehearsalStep.volume => (
        '뒷줄 볼륨을 맞춰요',
        switch (status) {
          CrowdStatus.loud => '오른쪽 노브를 아래로 밀어 민트색 구간에 맞춰요.',
          CrowdStatus.ready => '✓ 준비! 여기서 손을 떼세요.',
          _ => '오른쪽 노브를 위로 밀어요. 짧게 여러 번 밀어도 돼요.',
        },
      ),
      _RehearsalStep.signal => ('이제 관객에게 신호를 보내요', '아래 노란 라우럴!을 누르고 뒷줄을 보세요.'),
      _RehearsalStep.response => (
        status == CrowdStatus.singing ? '관객이 따라 불러요!' : '신호를 보냈어요',
        '본 공연에서 두 줄이 함께 부르면 콤보가 쌓여요.',
      ),
    };
    final media = MediaQuery.of(context);
    final safeWidth = viewport.maxWidth - media.padding.horizontal;
    final bodyHeight =
        viewport.maxHeight -
        media.padding.vertical -
        kMinInteractiveDimensionCupertino;
    final wide = safeWidth >= 600 && viewport.maxWidth > viewport.maxHeight;
    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        Text(instruction, style: const TextStyle(color: _paper)),
      ],
    );
    final signal = SignalButton(
      state: _performance.signal(FestivalZone.back),
      label: step == _RehearsalStep.response ? '본 공연 준비 중' : null,
      onPressed: () => _sendSignal(FestivalZone.back),
    );
    final visual = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.max(
            175,
            math.min(285, bodyHeight - (wide ? 14 : 334)),
          ),
        ),
        child: _scene(compact: true),
      ),
    );
    final knob = Align(
      alignment: Alignment.centerRight,
      child: _volumeControl(FestivalZone.back),
    );
    return _Screen(
      title: '리허설',
      compact: true,
      maxWidth: wide ? 900 : 520,
      trailing: _pauseButton(),
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        panel,
                        const SizedBox(height: 8),
                        knob,
                        if (step != _RehearsalStep.volume) ...[
                          const SizedBox(height: 12),
                          signal,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: visual),
                ],
              ),
            ]
          : [panel, visual, knob, if (step != _RehearsalStep.volume) signal],
    );
  }

  Widget _buildPerformance(BuildContext context, BoxConstraints viewport) {
    final chorus = widget.checkpoint?.chorus;
    final performance = _performance;
    final notice = widget.recovery != null && performance.rescueBeats == 0
        ? ('${widget.recovery!.zoneLabel}을 맞춰 이 박의 떼창을 살려요', null)
        : performance.eventNotice;
    final media = MediaQuery.of(context);
    final safeWidth = viewport.maxWidth - media.padding.horizontal;
    final bodyHeight =
        viewport.maxHeight -
        media.padding.vertical -
        kMinInteractiveDimensionCupertino;
    final standardText = media.textScaler.scale(14) <= 16;
    final sideBySide =
        standardText &&
        safeWidth >= 600 &&
        viewport.maxWidth > viewport.maxHeight;
    final fullSceneHeight = (math.min(safeWidth, 520.0) - 32) * 324 / 360;
    // Leave room for the score, rhythm cues, and shared signal button.
    final compact =
        standardText &&
        (sideBySide || safeWidth <= 380 || bodyHeight < fullSceneHeight + 390);
    final title = widget.recovery != null
        ? '콤보 복구 연습'
        : chorus == null
        ? '${widget.venue.title} 공연'
        : widget.mastery
        ? '숙련 후렴 도전'
        : '후렴 $chorus 연습';
    final score = PerformanceScore(
      score: performance.score,
      maximum: performance.maximum,
      compact: compact,
    );
    final signalZone = performance.recommendedSignalZone;
    final signalState = performance.sharedSignal;
    final signal = SignalButton(
      state: signalState,
      label: signalState == SignalState.available && signalZone == null
          ? '볼륨 맞추기'
          : null,
      destination: switch (signalZone) {
        FestivalZone.front => '앞줄',
        FestivalZone.back =>
          performance.startsBothRows(FestivalZone.back) ? '두 줄' : '뒷줄',
        null => null,
      },
      beatPhase: performance.beatPhase,
      onPressed: signalZone == null ? null : () => _sendSignal(signalZone),
    );

    final scene = _scene(compact: compact);
    final stage = compact
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(132, bodyHeight - (sideBySide ? 14 : 296)),
              ),
              child: scene,
            ),
          )
        : scene;
    final cue = EventNotice(
      message: notice.$1,
      remainingBeats: notice.$2,
      compact: compact,
    );
    final countdown = performance.nextSignalCountdown;
    final beats = BeatStrip(
      remaining: performance.rescueBeats > 0
          ? performance.rescueBeats
          : countdown?.remaining ?? performance.remainingBeats,
      total: countdown?.total ?? 6,
      label: performance.rescueBeats > 0
          ? '콤보 복구 ${performance.rescueBeats}박'
          : countdown == null
          ? null
          : '후렴 ${countdown.chorus} 신호까지 ${countdown.remaining}박',
      combo: performance.combo,
      holdingCombo: performance.holdingCombo,
      beatPhase: performance.hasLiveRhythm ? performance.beatPhase : null,
      signalReady: signalZone != null,
    );
    final frontKnob = _volumeControl(FestivalZone.front);
    final backKnob = _volumeControl(FestivalZone.back);
    final mixer = LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxWidth < 272 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [frontKnob, backKnob],
              ),
              const SizedBox(height: 6),
              beats,
            ],
          );
        }
        return Row(
          children: [
            frontKnob,
            const SizedBox(width: 8),
            Expanded(child: beats),
            const SizedBox(width: 8),
            backKnob,
          ],
        );
      },
    );
    return _Screen(
      title: title,
      compact: compact,
      maxWidth: sideBySide ? 900 : 520,
      middle: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _paper, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                score,
              ],
            )
          : null,
      trailing: _pauseButton(),
      children: sideBySide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        cue,
                        const SizedBox(height: 6),
                        mixer,
                        const SizedBox(height: 6),
                        signal,
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : [stage, if (!compact) score, cue, mixer, signal],
    );
  }
}

class _ResultSound extends StatefulWidget {
  const _ResultSound({required this.volume, required this.child});

  final double volume;
  final Widget child;

  @override
  State<_ResultSound> createState() => _ResultSoundState();
}

class _ResultSoundState extends State<_ResultSound>
    with WidgetsBindingObserver {
  FestivalResultAudio? _audio;

  @override
  void initState() {
    super.initState();
    if (widget.volume == 0) return;
    WidgetsBinding.instance.addObserver(this);
    final audio = FestivalResultAudio(widget.volume);
    _audio = audio;
    unawaited(audio.play());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _audio?.stop();
  }

  @override
  void dispose() {
    final audio = _audio;
    if (audio != null) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(audio.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ResultsScreen extends StatefulWidget {
  const _ResultsScreen({
    required this.records,
    required this.score,
    required this.bestCombo,
    required this.returnHome,
    required this.venue,
    required this.missionAchieved,
    required this.comboBreak,
    required this.results,
    required this.saved,
  });

  final FestivalRecords records;
  final int score;
  final int bestCombo;
  final bool returnHome;
  final FestivalVenue venue;
  final bool missionAchieved;
  final ComboBreak? comboBreak;
  final List<ChorusResult> results;
  final bool saved;

  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen> {
  int? _expandedChorus;

  @override
  Widget build(BuildContext context) {
    final recommended = recommendedChorusPractice(widget.results);
    final lost = widget.comboBreak;
    final venue = widget.venue;
    final nextVenue =
        venue == FestivalVenue.neighborhood &&
        widget.missionAchieved &&
        widget.records.nightMarketUnlocked;
    final compact = MediaQuery.sizeOf(context).height < 480;
    return _Screen(
      title: '전체 결과',
      compact: compact,
      children: [
        _ResultsHero(
          venue: venue,
          score: widget.score,
          combo: widget.bestCombo,
          missionAchieved: widget.missionAchieved,
          compact: compact,
        ),
        if (!widget.saved) const Text('최고 기록을 저장하지 못했어요.'),
        if (nextVenue)
          _Action(
            '다음 무대 · 야외 야시장',
            () => _open(
              context,
              _PerformanceScreen(
                records: widget.records,
                venue: FestivalVenue.nightMarket,
                returnHome: widget.returnHome,
              ),
              replace: true,
            ),
            primary: true,
          ),
        const Text(
          '후렴별 기록',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        for (final result in widget.results)
          _ChorusResultCard(
            result: result,
            recommended: identical(recommended, result),
            expanded: _expandedChorus == result.chorus,
            onToggle: () => setState(() {
              _expandedChorus = _expandedChorus == result.chorus
                  ? null
                  : result.chorus;
            }),
            onPractice: () => _open(
              context,
              _PerformanceScreen(
                records: widget.records,
                checkpoint: result.checkpoint,
                venue: venue,
                previousScore: result.score,
                previousResult: result,
              ),
            ),
          ),
        if (lost != null)
          _Action(
            '끊기기 3초 전부터 연습',
            () => _open(
              context,
              _PerformanceScreen(
                records: widget.records,
                venue: venue,
                recovery: lost,
              ),
            ),
          ),
        if (lost != null)
          Text(
            '${lost.combo}콤보 끊김 · 후렴 ${lost.chorus} ${lost.beat}박 · ${lost.zoneLabel}',
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        _Action(
          '공연 다시 하기',
          () => _open(
            context,
            _PerformanceScreen(
              records: widget.records,
              returnHome: widget.returnHome,
              venue: venue,
            ),
            replace: true,
          ),
          primary: !nextVenue,
        ),
        _Action(
          widget.returnHome ? '시작 화면으로' : '공연 선택으로',
          () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ResultsHero extends StatelessWidget {
  const _ResultsHero({
    required this.venue,
    required this.score,
    required this.combo,
    required this.missionAchieved,
    required this.compact,
  });

  final FestivalVenue venue;
  final int score;
  final int combo;
  final bool missionAchieved;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              venue.posterAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, .18),
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0x70171329), Color(0xEC171329), _night],
                  stops: [0, .59, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${venue.title} 완료',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: compact ? 5 : 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Semantics(
                      label: '공연 점수 $score점, 90점 만점',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          text: '$score',
                          style: TextStyle(
                            color: _gold,
                            fontSize: compact ? 36 : 48,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(
                              text: ' / 90',
                              style: TextStyle(
                                color: _paper,
                                fontSize: compact ? 16 : 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '최고 $combo콤보',
                      style: const TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  missionAchieved ? '✓ 목표 달성' : venue.mission,
                  style: TextStyle(
                    fontSize: 13,
                    color: missionAchieved ? _mint : _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChorusResultCard extends StatelessWidget {
  const _ChorusResultCard({
    required this.result,
    required this.recommended,
    required this.expanded,
    required this.onToggle,
    required this.onPractice,
  });

  final ChorusResult result;
  final bool recommended;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF24203A),
        border: Border.all(
          color: recommended
              ? const Color(0x907A624C)
              : const Color(0xFF403650),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: expanded,
            child: CupertinoButton(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: _paper,
              onPressed: onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '후렴 ${result.chorus}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (recommended)
                          const Text(
                            '추천 연습',
                            style: TextStyle(color: _gold, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${result.score}/30',
                    style: const TextStyle(color: _mint, fontSize: 15),
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: _muted,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            ChorusSummary(result: result),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _Action(
                '후렴 ${result.chorus} 연습',
                onPractice,
                primary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecoveryResults extends StatelessWidget {
  const _RecoveryResults({
    required this.records,
    required this.moment,
    required this.venue,
    required this.succeeded,
  });

  final FestivalRecords records;
  final ComboBreak moment;
  final FestivalVenue venue;
  final bool succeeded;

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '콤보 복구 연습 결과',
      children: [
        Text(
          succeeded
              ? '두 줄이 다시 합류했어요!'
              : '${moment.zoneLabel} 볼륨을 한 박 더 일찍 맞춰봐요.',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          '후렴 ${moment.chorus} · ${moment.beat}박',
          style: const TextStyle(color: _muted),
        ),
        _Action(
          '이 순간 다시 연습',
          () => _open(
            context,
            _PerformanceScreen(
              records: records,
              venue: venue,
              recovery: moment,
            ),
            replace: true,
          ),
          primary: true,
        ),
        _Action('전체 결과로', () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _PracticeResultsScreen extends StatelessWidget {
  const _PracticeResultsScreen({
    required this.records,
    required this.result,
    this.previous,
    this.previousResult,
    required this.mastery,
    required this.venue,
    required this.saved,
  });

  final FestivalRecords records;
  final ChorusResult result;
  final int? previous;
  final ChorusResult? previousResult;
  final bool mastery;
  final FestivalVenue venue;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final difference =
        result.togetherBeats -
        (previousResult?.togetherBeats ?? result.togetherBeats);
    return _Screen(
      title: mastery ? '숙련 후렴 결과' : '후렴 연습 결과',
      children: [
        Text(
          '후렴 ${result.chorus}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        PerformanceScore(score: result.score, maximum: 30),
        if (previous != null)
          Text(
            '이전 $previous점 → ${result.score}점',
            style: const TextStyle(color: _muted),
          ),
        if (!saved) const Text('최고 기록을 저장하지 못했어요.'),
        if (previousResult != null) ...[
          Text(
            difference == 0
                ? '동시 떼창 시간 유지'
                : '동시 떼창 ${(difference.abs() / 2).toStringAsFixed(1)}초 ${difference > 0 ? '증가' : '감소'}',
            style: const TextStyle(color: _muted),
          ),
          const Text('이전 떼창 기록'),
          ChorusSummary(result: previousResult!),
          const Text('이번 떼창 기록'),
        ],
        ChorusSummary(result: result),
        _Action(
          '이 후렴 다시 연습',
          () => _open(
            context,
            _PerformanceScreen(
              records: records,
              checkpoint: result.checkpoint,
              venue: venue,
              previousScore: result.score,
              previousResult: result,
              mastery: mastery,
            ),
            replace: true,
          ),
          primary: true,
        ),
        _Action(
          mastery ? '공연 선택으로' : '전체 결과로',
          () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen({required this.records});

  final FestivalRecords records;

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late int _volume = widget.records.volume;
  late bool _vibration = widget.records.vibration;
  bool _saveFailed = false;

  Future<void> _save(Future<bool> operation) async {
    try {
      if (await operation) return;
    } on Exception {
      // Keep the setting usable for this session and surface the write failure.
    }
    if (mounted) setState(() => _saveFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '설정',
      children: [
        ZoneVolumeSlider(
          zone: '게임',
          value: _volume,
          onChanged: (value) {
            setState(() => _volume = value);
            unawaited(_save(widget.records.setVolume(value)));
          },
        ),
        Row(
          children: [
            const Expanded(child: Text('진동')),
            Semantics(
              label: '진동',
              child: CupertinoSwitch(
                value: _vibration,
                onChanged: (value) {
                  setState(() => _vibration = value);
                  unawaited(_save(widget.records.setVibration(value)));
                },
              ),
            ),
          ],
        ),
        const Text('공연은 소리를 꺼도 플레이할 수 있어요.', style: TextStyle(color: _muted)),
        if (_saveFailed) const Text('설정을 저장하지 못했어요.'),
      ],
    );
  }
}
