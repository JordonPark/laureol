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
const _uiFont = 'Laureol Sans';
const _titleArt = 'docs/art/festival/title-festival.png';
const _playGuide =
    '볼륨을 밀어 앞줄·뒷줄을 ✓ 준비에 맞춰요.\n'
    '노란 ‘라우럴!’ 버튼이 뜨면 준비된 한쪽을 눌러요.\n'
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
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? middle;
  final bool compact;
  final double maxWidth;
  final Widget? footer;

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
            child: footer == null
                ? content
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: content),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          4,
                          horizontal,
                          8,
                        ),
                        child: footer!,
                      ),
                    ],
                  ),
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

class _StageArt extends StatelessWidget {
  const _StageArt({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        _titleArt,
        width: double.infinity,
        height: math.min(height, MediaQuery.sizeOf(context).height * .25),
        fit: BoxFit.cover,
        alignment: const Alignment(0, .12),
        excludeFromSemantics: true,
      ),
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
                                      _SelectionScreen(records: records),
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
  Future<void> _play({ChorusCheckpoint? checkpoint}) async {
    await _open(
      context,
      _PerformanceScreen(
        records: widget.records,
        checkpoint: checkpoint,
        mastery: checkpoint != null,
        previousScore: checkpoint == null ? null : widget.records.masteryBest,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final best = widget.records.concertBest;
    final masteryBest = widget.records.masteryBest;
    return _Screen(
      title: '공연 선택',
      compact: MediaQuery.sizeOf(context).height < 480,
      children: [
        const _StageArt(height: 200),
        const Text(
          '동네 축제',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const Text('후렴 3개', style: TextStyle(color: _muted)),
        if (!widget.records.rehearsalCompleted)
          const Text('첫 공연 전에 뒷줄 볼륨과 신호를 한 번씩 연습해요.'),
        _Action(
          widget.records.rehearsalCompleted ? '동네 축제 시작' : '리허설 시작',
          () => _play(),
          primary: true,
        ),
        if (best != null) ...[
          Text('일반 공연 최고 기록 ${best.score}/90'),
          if (masteryBest != null) Text('숙련 후렴 최고 기록 $masteryBest/30'),
          _Action('숙련 후렴 도전', () => _play(checkpoint: best.checkpoint)),
        ],
      ],
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
  });

  final FestivalRecords records;
  final ChorusCheckpoint? checkpoint;
  final int? previousScore;
  final ChorusResult? previousResult;
  final bool mastery;

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
  Future<bool>? _savingResult;
  _RehearsalStep? _rehearsalStep;

  bool get _waitingForRehearsalInput =>
      _rehearsalStep == _RehearsalStep.volume ||
      _rehearsalStep == _RehearsalStep.signal;

  FestivalPerformance _newPerformance() {
    final checkpoint = widget.checkpoint;
    if (checkpoint != null) {
      return FestivalPerformance.replay(checkpoint, mastery: widget.mastery);
    }
    final guided = !widget.records.rehearsalCompleted;
    _rehearsalStep = guided ? _RehearsalStep.volume : null;
    final performance = FestivalPerformance(preserveRehearsalMix: guided);
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
      _performance.setVolume(zone, value);
      if (_waitingForRehearsalInput && zone == FestivalZone.back) {
        if (_performance.status(zone) == CrowdStatus.ready) {
          _performance.openRehearsalSignal();
          _rehearsalStep = _RehearsalStep.signal;
        } else {
          _rehearsalStep = _RehearsalStep.volume;
        }
      }
    });
    _updateAudio();
  }

  void _sendSignal(FestivalZone zone) {
    if (_performance.signal(zone) != SignalState.available) return;
    final rehearsing = _rehearsalStep == _RehearsalStep.signal;
    setState(() {
      _performance.queue(zone);
      if (rehearsing) _rehearsalStep = _RehearsalStep.response;
    });
    if (widget.records.vibration) unawaited(HapticFeedback.selectionClick());
    if (rehearsing) _resumeScene();
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
    final saved = await (_savingResult ??= _saveResult());
    if (!mounted) return;
    final checkpoint = widget.checkpoint;
    await _open(
      context,
      _ResultSound(
        volume: widget.records.volume / 100,
        child: checkpoint == null
            ? _ResultsScreen(
                records: widget.records,
                score: _performance.score,
                bestCombo: _performance.bestCombo,
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
        _savingResult = _saveResult();
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
              widget.checkpoint == null || widget.mastery
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
        _savingResult = null;
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
      builder: (context, constraints) =>
          _buildPerformance(context, constraints),
    );
  }

  Widget _buildPerformance(BuildContext context, BoxConstraints viewport) {
    final chorus = widget.checkpoint?.chorus;
    final performance = _performance;
    final notice = switch (_rehearsalStep) {
      _RehearsalStep.volume => (
        performance.status(FestivalZone.back) == CrowdStatus.loud
            ? '뒷줄 소리가 너무 커요. 볼륨을 조금 내려요.'
            : '뒷줄 볼륨을 오른쪽으로 밀어 ✓ 준비에 맞춰요.',
        null,
      ),
      _RehearsalStep.signal => ('좋아요! 뒷줄의 노란 ‘라우럴!’을 눌러요.', null),
      _RehearsalStep.response => (
        performance.status(FestivalZone.front) == CrowdStatus.singing &&
                performance.status(FestivalZone.back) == CrowdStatus.singing
            ? '두 줄이 함께 불러요! 곧 첫 후렴이 시작돼요.'
            : '신호를 보냈어요. 관객 반응을 지켜봐요.',
        null,
      ),
      null => performance.eventNotice,
    };
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
    // Leave room for the score, notices, and both 48-point controls per card.
    final compact =
        standardText &&
        (sideBySide || safeWidth <= 380 || bodyHeight < fullSceneHeight + 390);
    final title = _rehearsalStep != null
        ? '리허설'
        : chorus == null
        ? '동네 축제 공연'
        : widget.mastery
        ? '숙련 후렴 도전'
        : '후렴 $chorus 연습';
    final score = PerformanceScore(
      score: performance.score,
      maximum: performance.maximum,
      compact: compact,
    );
    ZoneControlCard card(FestivalZone zone, String label) {
      final back = zone == FestivalZone.back;
      return ZoneControlCard(
        zone: label,
        compact: compact,
        status: performance.status(zone),
        volume: performance.volume(zone),
        volumeEnabled: !_waitingForRehearsalInput || back,
        highlight: back && _waitingForRehearsalInput
            ? _rehearsalStep == _RehearsalStep.volume
                  ? ControlHighlight.volume
                  : ControlHighlight.signal
            : null,
        onVolumeChanged: (value) => _changeVolume(zone, value),
        signalState:
            !_waitingForRehearsalInput ||
                (back && _rehearsalStep == _RehearsalStep.signal)
            ? performance.signal(zone)
            : SignalState.waiting,
        onSignal: () => _sendSignal(zone),
      );
    }

    final front = card(FestivalZone.front, '앞줄');
    final back = card(FestivalZone.back, '뒷줄');

    final scene = FestivalScene(
      compact: compact,
      tick: performance.tick,
      front: performance.status(FestivalZone.front),
      back: performance.status(FestivalZone.back),
      generatorRunning: performance.generatorRunning,
      signalQueued: performance.signalQueued,
      waveFrame: performance.waveFrame,
      waveTowardBack: performance.waveTowardBack,
    );
    final stage = compact
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(120, bodyHeight - (sideBySide ? 20 : 310)),
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
      remaining: countdown?.remaining ?? performance.remainingBeats,
      total: countdown?.total ?? 6,
      label: switch (_rehearsalStep) {
        _RehearsalStep.volume => '1/2 볼륨 조절',
        _RehearsalStep.signal => '2/2 신호 보내기',
        _RehearsalStep.response => '관객 반응 보기',
        null =>
          countdown == null
              ? null
              : '후렴 ${countdown.chorus} 신호까지 ${countdown.remaining}박',
      },
      combo: performance.combo,
      holdingCombo: performance.holdingCombo,
    );
    final controls = LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
        if (constraints.maxWidth < 280 || largeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [front, const SizedBox(height: 8), back],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: front),
            const SizedBox(width: 8),
            Expanded(child: back),
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
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 40),
        onPressed: _pause,
        child: Semantics(label: '일시정지', child: Icon(CupertinoIcons.pause_fill)),
      ),
      footer: performance.finished
          ? _Action('결과 보기', _showResults, primary: true)
          : null,
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
                        beats,
                        const SizedBox(height: 6),
                        controls,
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : [stage, if (!compact) score, cue, beats, controls],
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

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({
    required this.records,
    required this.score,
    required this.bestCombo,
    required this.results,
    required this.saved,
  });

  final FestivalRecords records;
  final int score;
  final int bestCombo;
  final List<ChorusResult> results;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final recommended = recommendedChorusPractice(results);
    return _Screen(
      title: '전체 결과',
      children: [
        PerformanceScore(score: score),
        Text('이번 공연 최고 콤보 $bestCombo박', style: const TextStyle(color: _muted)),
        if (!saved) const Text('최고 기록을 저장하지 못했어요.'),
        for (final result in results) ...[
          ChorusSummary(
            result: result,
            recommended: identical(recommended, result),
          ),
          _Action(
            '후렴 ${result.chorus} 연습 · ${result.score}/30',
            () => _open(
              context,
              _PerformanceScreen(
                records: records,
                checkpoint: result.checkpoint,
                previousScore: result.score,
                previousResult: result,
              ),
            ),
            primary: identical(recommended, result),
          ),
        ],
        _Action(
          '공연 다시 하기',
          () => _open(
            context,
            _PerformanceScreen(records: records),
            replace: true,
          ),
          primary: true,
        ),
        _Action('공연 선택으로', () => Navigator.of(context).pop()),
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
    required this.saved,
  });

  final FestivalRecords records;
  final ChorusResult result;
  final int? previous;
  final ChorusResult? previousResult;
  final bool mastery;
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
