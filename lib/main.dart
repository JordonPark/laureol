import 'dart:async';

// Retain the SDK widgets while this prototype has no external UI dependencies.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chorus_summary.dart';
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
const _stage = 'docs/art/festival/stage.png';

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
  const _Screen({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title, style: const TextStyle(color: _paper)),
        previousPageTitle: '뒤로',
        trailing: trailing,
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF24203A),
        border: Border.all(color: const Color(0xFF514866)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Image.asset(
        _stage,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        semanticLabel: '해 질 녘 동네 축제 도트 무대',
      ),
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '라우럴!',
      children: [
        const _StageArt(height: 220),
        const Text(
          '라우럴! 볼륨 좀 올려',
          style: TextStyle(
            color: _paper,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        _Action(
          '공연 시작',
          () => _open(context, _SelectionScreen(records: records)),
          primary: true,
        ),
        _Action('설정', () => _open(context, _SettingsScreen(records: records))),
      ],
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
      children: [
        const _StageArt(height: 200),
        const Text(
          '동네 축제',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const Text('약 100초 · 후렴 3개', style: TextStyle(color: _muted)),
        if (best != null) Text('일반 공연 최고 기록 ${best.score}/90'),
        _Action('동네 축제 시작', () => _play(), primary: true),
        if (best != null) ...[
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

enum _PauseAction { resume, restart, exit }

class _PerformanceScreenState extends State<_PerformanceScreen>
    with WidgetsBindingObserver {
  late FestivalPerformance _performance;
  Timer? _clock;
  bool _pauseOpen = false;
  bool _openingResults = false;
  Future<bool>? _savingResult;

  FestivalPerformance _newPerformance() {
    final checkpoint = widget.checkpoint;
    return checkpoint == null
        ? FestivalPerformance()
        : FestivalPerformance.replay(checkpoint, mastery: widget.mastery);
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
      checkpoint == null
          ? _ResultsScreen(
              records: widget.records,
              score: _performance.score,
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
      replace: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _performance = _newPerformance();
    WidgetsBinding.instance.addObserver(this);
    _resumeScene();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_pauseOpen) _resumeScene();
    } else {
      _clock?.cancel();
      _clock = null;
    }
  }

  void _resumeScene() {
    if (_clock != null || _performance.finished) return;
    var previousTick = 0;
    _clock = Timer.periodic(festivalTick, (timer) {
      setState(() => _performance.advanceTicks(timer.tick - previousTick));
      previousTick = timer.tick;
      if (_performance.finished) {
        timer.cancel();
        _clock = null;
        _savingResult = _saveResult();
      }
    });
  }

  Future<void> _pause() async {
    _pauseOpen = true;
    _clock?.cancel();
    _clock = null;
    final action = await showCupertinoDialog<_PauseAction>(
      context: context,
      builder: (dialog) => CupertinoAlertDialog(
        title: const Text('일시정지'),
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
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) {
      _resumeScene();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chorus = widget.checkpoint?.chorus;
    final performance = _performance;
    final notice = performance.eventNotice;
    ZoneControlCard card(FestivalZone zone, String label) => ZoneControlCard(
      zone: label,
      status: performance.status(zone),
      volume: performance.volume(zone),
      onVolumeChanged: (value) =>
          setState(() => performance.setVolume(zone, value)),
      signalState: performance.signal(zone),
      onSignal: () {
        if (performance.signal(zone) != SignalState.available) return;
        setState(() => performance.queue(zone));
        if (widget.records.vibration) {
          unawaited(HapticFeedback.selectionClick());
        }
      },
    );
    final front = card(FestivalZone.front, '앞줄');
    final back = card(FestivalZone.back, '뒷줄');

    return _Screen(
      title: chorus == null
          ? '동네 축제 공연'
          : widget.mastery
          ? '숙련 후렴 도전'
          : '후렴 $chorus 연습',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 40),
        onPressed: _pause,
        child: Semantics(label: '일시정지', child: Icon(CupertinoIcons.pause_fill)),
      ),
      children: [
        FestivalScene(
          tick: performance.tick,
          front: performance.status(FestivalZone.front),
          back: performance.status(FestivalZone.back),
          generatorRunning: performance.generatorRunning,
          signalQueued: performance.signalQueued,
          waveFrame: performance.waveFrame,
          waveTowardBack: performance.waveTowardBack,
        ),
        PerformanceScore(
          score: performance.score,
          maximum: performance.maximum,
        ),
        EventNotice(message: notice.$1, remainingBeats: notice.$2),
        BeatStrip(remaining: performance.remainingBeats, total: 6),
        LayoutBuilder(
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
        ),
        if (performance.finished) _Action('결과 보기', _showResults, primary: true),
      ],
    );
  }
}

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({
    required this.records,
    required this.score,
    required this.results,
    required this.saved,
  });

  final FestivalRecords records;
  final int score;
  final List<ChorusResult> results;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '전체 결과',
      children: [
        PerformanceScore(score: score),
        if (!saved) const Text('최고 기록을 저장하지 못했어요.'),
        for (final result in results) ...[
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
          ),
          ChorusSummary(result: result),
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
