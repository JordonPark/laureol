import 'dart:async';
import 'dart:math' as math;

// Retain the SDK widgets while this prototype has no external UI dependencies.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chorus_summary.dart';
import 'concert_stage_art.dart';
import 'festival_ads.dart';
import 'festival_audio.dart';
import 'festival_performance.dart';
import 'festival_records.dart';
import 'festival_scene.dart';
import 'performance_controls.dart';
import 'venue_card.dart';

part 'rehearsal_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    LaureolApp(records: FestivalRecords(await SharedPreferences.getInstance())),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FestivalAds.instance.refreshConsent());
  });
}

const _night = Color(0xFF171329);
const _paper = Color(0xFFF7F2FF);
const _muted = Color(0xFFBDB8CD);
const _gold = Color(0xFFFFC46A);
const _mint = Color(0xFF7CE0C2);
const _uiFont = 'Laureol Sans';
const _titleArt = 'docs/art/festival/title-festival.png';
const _playGuide =
    '노브를 돌리거나 가운데를 위아래로 밀어요.\n'
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
    this.header,
    this.footer,
    this.previousPageTitle = '뒤로',
    this.compact = false,
    this.maxWidth = 520,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? middle;
  final Widget? header;
  final Widget? footer;
  final String previousPageTitle;
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
        previousPageTitle: previousPageTitle,
        trailing: trailing,
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: footer == null && header == null
                ? content
                : Column(
                    children: [
                      ?header,
                      Expanded(child: content),
                      ?footer,
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
    final cards = [
      for (final venue in FestivalVenue.originals)
        VenueCard(
          venue: venue,
          artHeight: compact ? 144 : 158,
          best: widget.records.bestFor(venue)?.score,
          missionCompleted: widget.records.missionCompleted(venue),
          onPlay: widget.records.isUnlocked(venue)
              ? () => _play(venue: venue)
              : null,
        ),
    ];
    return _Screen(
      title: '공연 선택',
      compact: compact,
      maxWidth: sideBySide ? 900 : 520,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _open(context, _TourScreen(records: widget.records)),
        child: Text('투어 ${FestivalVenue.tourVenues.length}곳'),
      ),
      children: [
        ..._cardRows(cards, paired: sideBySide),
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

List<Widget> _cardRows(List<Widget> cards, {required bool paired}) {
  if (!paired) return cards;
  return [
    for (var index = 0; index < cards.length; index += 2)
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[index]),
          const SizedBox(width: 12),
          Expanded(
            child: index + 1 < cards.length
                ? cards[index + 1]
                : const SizedBox.shrink(),
          ),
        ],
      ),
  ];
}

class _TourScreen extends StatelessWidget {
  const _TourScreen({required this.records});

  final FestivalRecords records;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: records,
    builder: (context, _) => LayoutBuilder(builder: _build),
  );

  Widget _build(BuildContext context, BoxConstraints bounds) {
    final wide = bounds.maxWidth >= 620;
    final grid =
        bounds.maxWidth - MediaQuery.paddingOf(context).horizontal >= 360 &&
        MediaQuery.textScalerOf(context).scale(20) <= 23;
    final cards = [
      for (final region in TourRegion.values)
        _regionCard(context, region, grid),
    ];
    return _Screen(
      title: '공연 투어',
      compact: bounds.maxHeight < 480,
      maxWidth: wide ? 880 : 520,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _open(context, const _StageCatalogScreen()),
        child: const Text('무대 도감'),
      ),
      children: _cardRows(cards, paired: grid),
    );
  }

  Widget _regionCard(BuildContext context, TourRegion region, bool grid) {
    final completed = region.venues
        .where((venue) => records.bestFor(venue) != null)
        .length;
    final total = region.venues.length;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () =>
          _open(context, _TourRegionScreen(records: records, region: region)),
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(minHeight: grid ? 116 : 82),
        decoration: BoxDecoration(
          color: const Color(0xFF252037),
          border: Border.all(color: Color(region.accent).withAlpha(115)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: Image.asset(
                region.backdrop,
                fit: BoxFit.cover,
                cacheWidth: 768,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: grid ? Alignment.topCenter : Alignment.centerLeft,
                    end: grid ? Alignment.bottomCenter : Alignment.centerRight,
                    colors: grid
                        ? const [Color(0x12171329), Color(0xF2171329)]
                        : const [Color(0xF2171329), Color(0x60171329)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.title,
                          style: const TextStyle(
                            color: _paper,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completed / $total 공연 완료',
                          style: TextStyle(
                            color: Color(region.accent),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: _paper,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCatalogScreen extends StatelessWidget {
  const _StageCatalogScreen();

  @override
  Widget build(BuildContext context) => _Screen(
    title: '무대 도감',
    maxWidth: 740,
    children: _cardRows([
      for (final set in StageSet.values)
        CupertinoButton(
          onPressed: () => _open(context, _StageSetScreen(set: set)),
          padding: EdgeInsets.zero,
          child: _StageTile(art: set.stages.first, label: set.title),
        ),
    ], paired: _stageCatalogUsesColumns(context)),
  );
}

class _StageSetScreen extends StatelessWidget {
  const _StageSetScreen({required this.set});

  final StageSet set;

  @override
  Widget build(BuildContext context) => _Screen(
    title: set.title,
    maxWidth: 740,
    children: _cardRows([
      for (final art in set.stages) _StageTile(art: art, label: art.title),
    ], paired: _stageCatalogUsesColumns(context)),
  );
}

bool _stageCatalogUsesColumns(BuildContext context) =>
    MediaQuery.sizeOf(context).width -
            MediaQuery.paddingOf(context).horizontal >=
        350 &&
    MediaQuery.textScalerOf(context).scale(15) < 21;

class _StageTile extends StatelessWidget {
  const _StageTile({required this.art, required this.label});

  final ConcertStageArt art;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF252037),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(art.set.backdrop.accent).withAlpha(90)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  art.set.backdrop.backdrop,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  color: const Color(0xFFA9A1C0),
                  colorBlendMode: BlendMode.modulate,
                  excludeFromSemantics: true,
                ),
                ConcertStagePreview(art),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Text(
              label,
              style: const TextStyle(
                color: _paper,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TourRegionScreen extends StatelessWidget {
  const _TourRegionScreen({required this.records, required this.region});

  final FestivalRecords records;
  final TourRegion region;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: records,
    builder: (context, _) => LayoutBuilder(builder: _build),
  );

  Widget _build(BuildContext context, BoxConstraints bounds) {
    final wide = bounds.maxWidth >= 620;
    final compact = bounds.maxHeight < 480;
    final cards = [
      for (final venue in region.venues)
        VenueCard(
          venue: venue,
          artHeight: compact ? 112 : 141,
          best: records.bestFor(venue)?.score,
          missionCompleted: records.missionCompleted(venue),
          onPlay: () => _open(
            context,
            _PerformanceScreen(records: records, venue: venue),
          ),
        ),
    ];
    return _Screen(
      title: region.title,
      previousPageTitle: '투어',
      compact: compact,
      maxWidth: wide ? 880 : 520,
      children: _cardRows(cards, paired: wide),
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
  bool _preparingConcert = false;
  _RehearsalStep? _rehearsalStep;
  FestivalZone? _focusedZone;
  int _readyPulse = 0;
  int _readyZones = 0;
  ({int serial, int rows})? _signalPulse;

  bool get _waitingForRehearsalInput =>
      _rehearsalStep == _RehearsalStep.volume ||
      _rehearsalStep == _RehearsalStep.signal;

  FestivalPerformance _newPerformance() {
    _readyZones = 0;
    _signalPulse = null;
    _preparingConcert = false;
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
      signalTiming: math.Random(),
    );
    if (!guided) {
      performance.startMainConcert();
      _preparingConcert = true;
    }
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
    final rows = _performance.startsBothRows(zone) ? 3 : 1 << zone.index;
    setState(() {
      _focusedZone = zone;
      _performance.queue(zone);
      _signalPulse = (serial: (_signalPulse?.serial ?? 0) + 1, rows: rows);
      if (rehearsing) _rehearsalStep = _RehearsalStep.response;
    });
    if (widget.records.vibration) unawaited(HapticFeedback.selectionClick());
    if (rehearsing) _resumeScene();
  }

  void _beginConcert() {
    if (!_preparingConcert || !_performance.bothRowsReady) return;
    setState(() {
      _performance.startMainConcert();
      _preparingConcert = false;
    });
    _resumeScene();
  }

  void _selectZone(FestivalZone zone) {
    if (_focusedZone == zone) return;
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
      _audio = FestivalAudio(widget.records.volume / 100, widget.venue);
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
        _preparingConcert ||
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
        final elapsed = timer.tick - previousTick;
        _performance.advanceTicks(
          _rehearsalStep == _RehearsalStep.response
              ? math.min(elapsed, _performance.ticksUntilMainConcert)
              : elapsed,
        );
        rehearsalFinished =
            _rehearsalStep == _RehearsalStep.response &&
            _performance.concertStarted;
        if (rehearsalFinished) {
          _rehearsalStep = null;
          _preparingConcert = true;
        }
        skipped = _performance.advancePastInterlude();
      });
      previousTick = timer.tick;
      if (rehearsalFinished) {
        _freezeScene();
        unawaited(_rememberRehearsal());
      } else if (_performance.finished) {
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
        _preparingConcert = true;
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
    final selected = _focusedZone == zone;
    final cue = _mixCue(zone);
    return ZoneControlCard(
      zone: zone == FestivalZone.front ? '앞줄' : '뒷줄',
      dialStyle: zone == FestivalZone.front
          ? VolumeDialStyle.front
          : VolumeDialStyle.back,
      status: performance.status(zone),
      volume: performance.volume(zone),
      selected: selected,
      needsRescue: performance.needsRescue(zone),
      targetCountdown: _preparingConcert
          ? null
          : performance.mixTargetCountdown(zone),
      onInteractionStart: () => _selectZone(zone),
      onVolumeChanged: (value) => _changeVolume(zone, value),
      target: performance.readyVolumeRange(zone),
      cue: cue,
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
      combo: performance.combo,
      holdingCombo: performance.holdingCombo,
      comboEffect: performance.comboEffect,
      frontCue: _mixCue(FestivalZone.front),
      backCue: _mixCue(FestivalZone.back),
      readyPulse: _readyPulse,
      readyZones: _readyZones,
      signalPulse: _signalPulse,
      activeMixZone: performance.activeMixZone,
      rehearsalGuide: _rehearsalStep != null,
    );
  }

  Widget _buildRehearsal(BuildContext context, BoxConstraints viewport) {
    final step = _rehearsalStep!;
    const zone = FestivalZone.back;
    final status = _performance.status(zone);
    final media = MediaQuery.of(context);
    final safeWidth = viewport.maxWidth - media.padding.horizontal;
    final bodyHeight =
        viewport.maxHeight -
        media.padding.vertical -
        kMinInteractiveDimensionCupertino;
    final wide =
        safeWidth >= 600 &&
        viewport.maxWidth > viewport.maxHeight &&
        media.textScaler.scale(15) <= 20;
    final dialSize = safeWidth >= 350 ? 172.0 : 148.0;
    final accent = switch (step) {
      _RehearsalStep.volume => status.color,
      _RehearsalStep.signal => _gold,
      _RehearsalStep.response =>
        status == CrowdStatus.singing ? status.color : _mint,
    };
    final scene = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: math.max(105, math.min(350, bodyHeight - (wide ? 78 : 260))),
      ),
      child: _scene(compact: true),
    );
    final deck = _RehearsalDeck(
      step: step,
      status: status,
      accent: accent,
      volume: _performance.volume(zone),
      dialSize: dialSize,
      wide: wide,
      feedbackBeat: _performance.beatInMeasure,
      control: switch (step) {
        _RehearsalStep.volume => ZoneVolumeSlider(
          zone: '뒷줄',
          value: _performance.volume(zone),
          onChanged: (value) => _changeVolume(zone, value),
          highlighted: _mixCue(zone) == MixCue.adjust,
          target: _performance.readyVolumeRange(zone),
          vertical: true,
          dialStyle: VolumeDialStyle.back,
          maxDialSize: dialSize,
          onInteractionEnd: _finishVolumePractice,
        ),
        _RehearsalStep.signal => SignalButton(
          state: _performance.signal(zone),
          onPressed: () => _sendSignal(zone),
        ),
        _RehearsalStep.response => null,
      },
    );
    return _Screen(
      title: '리허설',
      compact: true,
      maxWidth: wide ? 900 : 520,
      trailing: _pauseButton(),
      children: [
        _RehearsalProgress(step: step, accent: accent),
        _RehearsalBoard(wide: wide, accent: accent, scene: scene, deck: deck),
      ],
    );
  }

  Widget _buildPerformance(BuildContext context, BoxConstraints viewport) {
    const beatBarGap = 4.0;
    const beatBarSpace = BeatProgress.height + beatBarGap;
    final chorus = widget.checkpoint?.chorus;
    final performance = _performance;
    final readyToStart = performance.bothRowsReady;
    final notice = _preparingConcert
        ? (readyToStart ? '두 줄 준비 완료' : '두 노브를 민트색 눈금에 맞춰요', null)
        : widget.recovery != null && performance.rescueBeats == 0
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
    final mixerHeight = (math.min(safeWidth, 520.0) - 32) / 2 + beatBarSpace;
    // Leave room for the score, knobs, and shared signal button.
    final compact =
        standardText &&
        (sideBySide ||
            safeWidth <= 380 ||
            bodyHeight < fullSceneHeight + mixerHeight + 225);
    final venueName = widget.venue.title;
    final title = widget.recovery != null
        ? '콤보 복구 연습'
        : chorus == null
        ? (venueName.endsWith('공연') ? venueName : '$venueName 공연')
        : widget.mastery
        ? '숙련 후렴 도전'
        : '후렴 $chorus 연습';
    final score = PerformanceScore(
      score: performance.score,
      maximum: performance.maximum,
      compact: compact,
    );
    final signalState = performance.sharedSignal;
    final signalZone =
        performance.recommendedSignalZone ??
        (signalState == SignalState.available
            ? _focusedZone ?? FestivalZone.front
            : null);
    final signal = _preparingConcert
        ? SignalButton(
            state: readyToStart ? SignalState.available : SignalState.waiting,
            label: readyToStart ? '시작' : '준비',
            onPressed: readyToStart ? _beginConcert : null,
          )
        : SignalButton(
            state: signalState,
            label: signalState == SignalState.queued ? null : '라우럴!',
            destination: switch (signalZone) {
              FestivalZone.front => '앞줄',
              FestivalZone.back =>
                performance.startsBothRows(FestivalZone.back) ? '두 줄' : '뒷줄',
              null => null,
            },
            beatPhase: performance.beatPhase,
            onPressed: signalZone == null
                ? null
                : () => _sendSignal(signalZone),
          );

    final scene = _scene(compact: compact);
    final stage = compact
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(
                  132,
                  bodyHeight - (sideBySide ? 14 : mixerHeight + 156),
                ),
              ),
              child: scene,
            ),
          )
        : scene;
    final cue = EventNotice(
      message: notice.$1,
      remainingBeats:
          FestivalZone.values.any(
            (zone) => performance.mixTargetCountdown(zone) != null,
          )
          ? null
          : notice.$2,
      compact: compact,
    );
    final mixer = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: sideBySide
              ? math.max(176, (bodyHeight - 190 - beatBarSpace) * 2 + 8)
              : 520,
        ),
        child: Column(
          children: [
            BeatProgress(
              beat: performance.beatInMeasure,
              phase: performance.beatPhase,
              active: !_preparingConcert && performance.hasLiveRhythm,
              signalReady: signalState == SignalState.available,
            ),
            const SizedBox(height: beatBarGap),
            Row(
              children: [
                Expanded(child: _volumeControl(FestivalZone.front)),
                const SizedBox(width: 8),
                Expanded(child: _volumeControl(FestivalZone.back)),
              ],
            ),
          ],
        ),
      ),
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

  void _play(FestivalVenue venue) {
    _open(
      context,
      _PerformanceScreen(
        records: widget.records,
        returnHome: widget.returnHome,
        venue: venue,
      ),
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);

  Widget _build(BuildContext context, BoxConstraints viewport) {
    final lost = widget.comboBreak;
    final venue = widget.venue;
    final nextVenue = venue.next;
    final canContinue =
        nextVenue != null && widget.records.isUnlocked(nextVenue);
    final safeWidth =
        viewport.maxWidth - MediaQuery.paddingOf(context).horizontal;
    final compact = viewport.maxHeight < 480;
    final wide = compact && safeWidth >= 550;
    final hero = _ResultsHero(
      venue: venue,
      score: widget.score,
      combo: widget.bestCombo,
      missionAchieved: widget.missionAchieved,
      compact: compact,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              const Text(
                '후렴별 기록',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: _mint),
                  const SizedBox(width: 5),
                  const Text(
                    '두 줄 떼창',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF211B34),
            border: Border.all(color: const Color(0xFF3D334E)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, result) in widget.results.indexed) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 1,
                      child: ColoredBox(color: Color(0xFF393049)),
                    ),
                  ),
                _ChorusResultRow(
                  result: result,
                  expanded: _expandedChorus == result.chorus,
                  onToggle: () => setState(() {
                    _expandedChorus = _expandedChorus == result.chorus
                        ? null
                        : result.chorus;
                  }),
                ),
              ],
            ],
          ),
        ),
        if (lost != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
            child: Text(
              '${lost.combo}콤보 끊김 · 후렴 ${lost.chorus} ${lost.beat}박 · ${lost.zoneLabel}',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
      ],
    );
    return _Screen(
      title: '전체 결과',
      previousPageTitle: widget.returnHome
          ? '시작 화면'
          : venue.region == null
          ? '공연 선택'
          : '공연장',
      compact: compact,
      maxWidth: wide ? 880 : 520,
      header: !compact && FestivalAds.instance.enabled
          ? const FestivalResultBanner()
          : null,
      footer: _ResultActions(
        nextVenue: canContinue ? nextVenue : null,
        onNext: canContinue ? () => _play(nextVenue) : null,
        onReplay: () => _play(venue),
        compact: compact,
      ),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: hero),
              const SizedBox(width: 14),
              Expanded(child: details),
            ],
          )
        else ...[
          hero,
          details,
        ],
        if (!widget.saved)
          const Text('최고 기록을 저장하지 못했어요.', style: TextStyle(color: _muted)),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.nextVenue,
    required this.onNext,
    required this.onReplay,
    required this.compact,
  });

  final FestivalVenue? nextVenue;
  final VoidCallback? onNext;
  final VoidCallback onReplay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final next = nextVenue;
    final primary = CupertinoButton(
      color: _gold,
      foregroundColor: _night,
      borderRadius: BorderRadius.circular(10),
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 7 : 9),
      onPressed: next == null ? onReplay : onNext,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (next == null)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(CupertinoIcons.arrow_clockwise, size: 18),
            ),
          Flexible(
            child: next == null
                ? const Text(
                    '공연 다시 하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  )
                : Semantics(
                    label: '다음 무대 · ${next.title}',
                    excludeSemantics: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '다음 무대',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          next.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (next != null) ...[
            const SizedBox(width: 9),
            const Icon(CupertinoIcons.arrow_right, size: 18),
          ],
        ],
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _night,
        border: Border(top: BorderSide(color: Color(0xFF3D334E))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          8,
          compact ? 12 : 16,
          8,
        ),
        child: Row(
          children: [
            if (next != null) ...[
              CupertinoButton(
                color: const Color(0xFF302746),
                foregroundColor: _paper,
                minimumSize: const Size(48, 48),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onPressed: onReplay,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_clockwise, size: 17),
                    SizedBox(height: 2),
                    Text('다시 하기', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: primary),
          ],
        ),
      ),
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
    final scores = Row(
      children: [
        Expanded(
          flex: 3,
          child: Semantics(
            label: '공연 점수 $score점, 90점 만점',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '공연 점수',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    text: '$score',
                    style: TextStyle(
                      color: _gold,
                      fontSize: compact ? 42 : 52,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: ' / 90',
                        style: TextStyle(
                          color: _muted,
                          fontSize: compact ? 14 : 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 1,
          height: 48,
          child: ColoredBox(color: Color(0xFF51405A)),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Semantics(
            label: '최고 $combo콤보',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최고 콤보',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  '$combo',
                  style: TextStyle(
                    color: _mint,
                    fontSize: compact ? 34 : 40,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF211B34),
        border: Border.all(color: const Color(0xFF504050)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, bounds) => SizedBox(
              height: compact
                  ? 98
                  : (bounds.maxWidth * .42).clamp(108, 185).toDouble(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VenueArtwork(
                    venue: venue,
                    alignment: const Alignment(0, .12),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00171329),
                          Color(0x00171329),
                          Color(0xE5171329),
                        ],
                        stops: [0, .45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 14,
                    right: 14,
                    child: Text(
                      '${venue.title} 완료',
                      style: const TextStyle(
                        color: _paper,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0xFF7C5E4E)),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF322741), Color(0xFF231E35)],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                compact ? 8 : 12,
                14,
                compact ? 8 : 12,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 270),
                curve: Curves.easeOutCubic,
                child: scores,
                builder: (context, progress, child) => Opacity(
                  opacity: .65 + .35 * progress,
                  child: Transform.translate(
                    offset: Offset(0, 5 * (1 - progress)),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              children: [
                Icon(
                  missionAchieved
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.flag,
                  color: missionAchieved ? _mint : _muted,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    missionAchieved ? '목표 달성' : venue.mission,
                    style: TextStyle(
                      fontSize: 12,
                      color: missionAchieved ? _mint : _muted,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ChorusResultRow extends StatelessWidget {
  const _ChorusResultRow({
    required this.result,
    required this.expanded,
    required this.onToggle,
  });

  final ChorusResult result;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final title = '후렴 ${result.chorus}';
    final seconds = (result.togetherBeats / 2).toStringAsFixed(1);
    final nameWidth = MediaQuery.textScalerOf(context).scale(45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label: '$title, ${result.score}점, 두 줄 떼창 $seconds초',
          onTap: onToggle,
          child: ExcludeSemantics(
            child: CupertinoButton(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              foregroundColor: _paper,
              onPressed: onToggle,
              child: Row(
                children: [
                  SizedBox(
                    width: nameWidth,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPaint(
                      size: const Size.fromHeight(17),
                      painter: _ChorusBeatPainter(result),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      text: '${result.score}',
                      style: const TextStyle(
                        color: _paper,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: '/30',
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: _muted,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ChorusSummary(result: result),
          ),
      ],
    );
  }
}

class _ChorusBeatPainter extends CustomPainter {
  const _ChorusBeatPainter(this.result);

  final ChorusResult result;

  @override
  void paint(Canvas canvas, Size size) {
    if (result.beatCount == 0 || size.width < 32) return;
    final paint = Paint();
    final step = size.width / result.beatCount;
    final barWidth = step * .67;
    for (var beat = 0; beat < result.beatCount; beat++) {
      final front = result.sangAt(FestivalZone.front, beat);
      final back = result.sangAt(FestivalZone.back, beat);
      final together = front && back;
      final solo = front || back;
      final height = together ? size.height : (solo ? size.height * .58 : 3.0);
      paint.color = together
          ? _mint
          : (solo ? const Color(0xFFBC9ECE) : const Color(0xFF4A405F));
      canvas.drawRect(
        Rect.fromLTWH(beat * step, size.height - height, barWidth, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChorusBeatPainter oldDelegate) =>
      result != oldDelegate.result;
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

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  static final _webPolicy = Uri.https(
    'jordonpark.github.io',
    '/laureol/privacy.txt',
  );

  @override
  Widget build(BuildContext context) {
    return _Screen(
      title: '개인정보 처리방침',
      children: [
        FutureBuilder<String>(
          future: DefaultAssetBundle.of(context).loadString('site/privacy.txt'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('방침을 불러오지 못했어요. 웹에서 열어 주세요.');
            }
            final policy = snapshot.data;
            if (policy == null) return const CupertinoActivityIndicator();
            return Text(policy.trim(), style: const TextStyle(height: 1.5));
          },
        ),
        _Action('웹에서 처리방침 열기', () => _openWebPolicy(context)),
      ],
    );
  }

  Future<void> _openWebPolicy(BuildContext context) async {
    try {
      if (await launchUrl(_webPolicy, mode: LaunchMode.externalApplication)) {
        return;
      }
    } on Exception {
      // The bundled policy remains available when a browser cannot be opened.
    }
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('웹 페이지를 열지 못했어요.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
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
        _Action(
          '개인정보 처리방침',
          () => _open(context, const _PrivacyPolicyScreen()),
        ),
        if (FestivalAds.instance.live)
          ListenableBuilder(
            listenable: FestivalAds.instance,
            builder: (context, _) {
              if (!FestivalAds.instance.privacyOptionsRequired) {
                return const SizedBox.shrink();
              }
              return _Action('광고 개인정보 설정', _showAdPrivacy);
            },
          ),
        if (_saveFailed) const Text('설정을 저장하지 못했어요.'),
      ],
    );
  }

  Future<void> _showAdPrivacy() async {
    if (await FestivalAds.instance.showPrivacyOptions() || !mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('광고 개인정보 설정'),
        content: const Text('지금 설정을 불러올 수 없어요.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
