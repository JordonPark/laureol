import 'dart:async';

// Retain the SDK widgets while this prototype has no external UI dependencies.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';

import 'festival_performance.dart';
import 'festival_scene.dart';
import 'performance_controls.dart';

void main() => runApp(const LaureolApp());

const _night = Color(0xFF171329);
const _paper = Color(0xFFF7F2FF);
const _muted = Color(0xFFBDB8CD);
const _gold = Color(0xFFFFC46A);
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
  const LaureolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: '라우럴! 볼륨 좀 올려',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: _gold,
        scaffoldBackgroundColor: _night,
        barBackgroundColor: _night,
        textTheme: CupertinoTextThemeData(
          primaryColor: _gold,
          textStyle: TextStyle(color: _paper, fontSize: 16),
        ),
      ),
      home: _StartScreen(),
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

class _StartScreen extends StatefulWidget {
  const _StartScreen();

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  double _volume = 70;
  bool _vibration = true;

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
          () => _open(context, const _SelectionScreen()),
          primary: true,
        ),
        _Action(
          '설정',
          () => _open(
            context,
            _SettingsScreen(
              volume: _volume,
              vibration: _vibration,
              onVolumeChanged: (value) => _volume = value,
              onVibrationChanged: (value) => _vibration = value,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionScreen extends StatelessWidget {
  const _SelectionScreen();

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '공연 선택',
      children: [
        const _StageArt(height: 200),
        const Text(
          '동네 축제',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const Text('약 100초 · 후렴 3개', style: TextStyle(color: _muted)),
        _Action(
          '동네 축제 시작',
          () => _open(context, const _PerformanceScreen()),
          primary: true,
        ),
      ],
    );
  }
}

class _PerformanceScreen extends StatefulWidget {
  const _PerformanceScreen({this.chorus, this.previousScore});

  final int? chorus;
  final int? previousScore;

  @override
  State<_PerformanceScreen> createState() => _PerformanceScreenState();
}

enum _PauseAction { resume, restart, exit }

class _PerformanceScreenState extends State<_PerformanceScreen>
    with WidgetsBindingObserver {
  late FestivalPerformance _performance;
  Timer? _clock;
  bool _pauseOpen = false;

  @override
  void initState() {
    super.initState();
    _performance = FestivalPerformance(practiceChorus: widget.chorus);
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
            child: Text(widget.chorus == null ? '공연 선택으로' : '전체 결과로'),
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
        _performance = FestivalPerformance(practiceChorus: widget.chorus);
      });
    }
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) {
      _resumeScene();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chorus = widget.chorus;
    final performance = _performance;
    final notice = performance.eventNotice;
    ZoneControlCard card(FestivalZone zone, String label) => ZoneControlCard(
      zone: label,
      status: performance.status(zone),
      volume: performance.volume(zone),
      onVolumeChanged: (value) =>
          setState(() => performance.setVolume(zone, value)),
      signalState: performance.signal(zone),
      onSignal: () => setState(() => performance.queue(zone)),
    );
    final front = card(FestivalZone.front, '앞줄');
    final back = card(FestivalZone.back, '뒷줄');

    return _Screen(
      title: chorus == null ? '동네 축제 공연' : '후렴 $chorus 연습',
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
        if (performance.finished)
          _Action(
            '결과 보기',
            () => _open(
              context,
              chorus == null
                  ? _ResultsScreen(
                      score: performance.score,
                      chorusScores: performance.chorusScores,
                    )
                  : _PracticeResultsScreen(
                      chorus: chorus,
                      score: performance.score,
                      previous: widget.previousScore,
                    ),
              replace: true,
            ),
            primary: true,
          ),
      ],
    );
  }
}

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({required this.score, required this.chorusScores});

  final int score;
  final List<int> chorusScores;

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '전체 결과',
      children: [
        PerformanceScore(score: score),
        for (var i = 0; i < chorusScores.length; i++)
          _Action(
            '후렴 ${i + 1} 연습 · ${chorusScores[i]}/30',
            () => _open(
              context,
              _PerformanceScreen(chorus: i + 1, previousScore: chorusScores[i]),
            ),
          ),
        _Action(
          '공연 다시 하기',
          () => _open(context, const _PerformanceScreen(), replace: true),
          primary: true,
        ),
        _Action('공연 선택으로', () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _PracticeResultsScreen extends StatelessWidget {
  const _PracticeResultsScreen({
    required this.chorus,
    required this.score,
    this.previous,
  });

  final int score;
  final int? previous;

  final int chorus;

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '후렴 연습 결과',
      children: [
        Text(
          '후렴 $chorus',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        PerformanceScore(score: score, maximum: 30),
        if (previous != null)
          Text(
            '이전 $previous점 → $score점',
            style: const TextStyle(color: _muted),
          ),
        _Action(
          '이 후렴 다시 연습',
          () => _open(
            context,
            _PerformanceScreen(chorus: chorus, previousScore: score),
            replace: true,
          ),
          primary: true,
        ),
        _Action('전체 결과로', () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen({
    required this.volume,
    required this.vibration,
    required this.onVolumeChanged,
    required this.onVibrationChanged,
  });

  final double volume;
  final bool vibration;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onVibrationChanged;

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late int _volume = widget.volume.round();
  late bool _vibration = widget.vibration;

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
            widget.onVolumeChanged(value.toDouble());
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
                  widget.onVibrationChanged(value);
                },
              ),
            ),
          ],
        ),
        const Text('공연은 소리를 꺼도 플레이할 수 있어요.', style: TextStyle(color: _muted)),
      ],
    );
  }
}
