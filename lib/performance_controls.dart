import 'package:flutter/widgets.dart';

const _ink = Color(0xFFF6F0E7);
const _muted = Color(0xFFBDB8CD);
const _panel = Color(0xFF24203A);
const _line = Color(0xFF514866);
const _amber = Color(0xFFFFC46A);
const _mint = Color(0xFF7CE0C2);
const _coral = Color(0xFFFFA18B);
const _blue = Color(0xFF9CCEFF);

enum CrowdStatus {
  quiet('작음', '귀 기울이기', '↓', _amber),
  ready('준비', '박수', '✓', _mint),
  loud('큼', '귀 막기', '↑', _coral),
  singing('떼창', '함께 노래하기', '♪', _blue);

  const CrowdStatus(this.label, this.description, this.symbol, this.color);

  final String label;
  final String description;
  final String symbol;
  final Color color;
}

enum SignalState {
  waiting('신호 대기'),
  available('라우럴!'),
  queued('신호 예약'),
  responding('받아 부를 차례');

  const SignalState(this.label);

  final String label;
}

enum MixCue { none, adjust, signal }

class CrowdStatusBadge extends StatelessWidget {
  const CrowdStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final CrowdStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${status.label}, ${status.description}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: status.color.withAlpha(28),
          border: Border.all(color: status.color.withAlpha(125)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 2 : 4,
          ),
          child: Text(
            '${status.symbol}  ${status.label}',
            style: TextStyle(
              color: status.color,
              fontSize: compact ? 11 : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ZoneVolumeSlider extends StatelessWidget {
  const ZoneVolumeSlider({
    super.key,
    required this.zone,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.highlighted = false,
    this.vertical = false,
    this.target,
    this.onInteractionEnd,
  }) : assert(value >= 0 && value <= 100);

  final String zone;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool highlighted;
  final bool vertical;
  final ({int minimum, int maximum})? target;
  final VoidCallback? onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final band = target;
    void adjustBy(int delta) {
      onChanged((value + delta).clamp(0, 100));
      onInteractionEnd?.call();
    }

    return Semantics(
      label: '$zone 볼륨',
      value: band == null
          ? '$value%'
          : '$value%, 준비 구간 ${band.minimum}%에서 ${band.maximum}%',
      enabled: enabled,
      increasedValue: enabled && value < 100
          ? '${(value + 5).clamp(0, 100)}%'
          : null,
      decreasedValue: enabled && value > 0
          ? '${(value - 5).clamp(0, 100)}%'
          : null,
      slider: true,
      onIncrease: enabled && value < 100 ? () => adjustBy(5) : null,
      onDecrease: enabled && value > 0 ? () => adjustBy(-5) : null,
      child: ExcludeSemantics(
        child: Column(
          children: [
            if (!vertical)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '볼륨',
                    style: TextStyle(color: highlighted ? _amber : _muted),
                  ),
                  Text('$value%', style: const TextStyle(color: _ink)),
                ],
              ),
            SizedBox(
              height: vertical ? 88 : 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const thumb = 20.0;
                  final length = vertical
                      ? constraints.maxHeight
                      : constraints.maxWidth;
                  final track = length - thumb;
                  if (track <= 0) return const SizedBox.shrink();
                  final filled = track * value / 100;

                  void update(double x) {
                    onChanged(
                      ((x - thumb / 2) / track * 100).round().clamp(0, 100),
                    );
                  }

                  double position(Offset point) =>
                      vertical ? length - point.dy : point.dx;
                  void dragStart(DragStartDetails details) =>
                      update(position(details.localPosition));
                  void dragUpdate(DragUpdateDetails details) =>
                      update(position(details.localPosition));
                  final end = enabled && onInteractionEnd != null
                      ? (DragEndDetails _) => onInteractionEnd!()
                      : null;
                  final graphics = SizedBox(
                    width: length,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: thumb / 2,
                          width: track,
                          height: 8,
                          child: const ColoredBox(color: _line),
                        ),
                        Positioned(
                          left: thumb / 2,
                          width: filled,
                          height: 8,
                          child: ColoredBox(
                            color: highlighted
                                ? _amber
                                : enabled
                                ? _mint
                                : _muted,
                          ),
                        ),
                        if (band != null)
                          Positioned(
                            left: thumb / 2 + track * band.minimum / 100,
                            width: track * (band.maximum - band.minimum) / 100,
                            height: 16,
                            child: const ColoredBox(color: _mint),
                          ),
                        if (highlighted &&
                            band != null &&
                            (value < band.minimum || value > band.maximum))
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _VolumeCuePainter(
                                from: filled + thumb / 2,
                                toward:
                                    (band.minimum + band.maximum) /
                                        2 *
                                        track /
                                        100 +
                                    thumb / 2,
                              ),
                            ),
                          ),
                        Positioned(
                          left: filled,
                          width: thumb,
                          height: thumb,
                          child: ColoredBox(
                            color: highlighted
                                ? _amber
                                : enabled
                                ? _ink
                                : _muted,
                          ),
                        ),
                      ],
                    ),
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: enabled
                        ? (details) => update(position(details.localPosition))
                        : null,
                    onTapUp: enabled && onInteractionEnd != null
                        ? (_) => onInteractionEnd!()
                        : null,
                    onHorizontalDragStart: enabled && !vertical
                        ? dragStart
                        : null,
                    onHorizontalDragUpdate: enabled && !vertical
                        ? dragUpdate
                        : null,
                    onHorizontalDragEnd: vertical ? null : end,
                    onVerticalDragStart: enabled && vertical ? dragStart : null,
                    onVerticalDragUpdate: enabled && vertical
                        ? dragUpdate
                        : null,
                    onVerticalDragEnd: vertical ? end : null,
                    child: vertical
                        ? RotatedBox(quarterTurns: 3, child: graphics)
                        : graphics,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeCuePainter extends CustomPainter {
  const _VolumeCuePainter({required this.from, required this.toward});

  final double from;
  final double toward;

  @override
  void paint(Canvas canvas, Size size) {
    final direction = toward > from ? 1 : -1;
    final center = (from + toward) / 2;
    final paint = Paint()
      ..color = _mint
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final shift in [-4, 4]) {
      final x = (center + shift).clamp(5.0, size.width - 5);
      final mark = Path()
        ..moveTo(x - 2 * direction, 2)
        ..lineTo(x + 2 * direction, 6)
        ..lineTo(x - 2 * direction, 10);
      canvas.drawPath(mark, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeCuePainter oldDelegate) =>
      from != oldDelegate.from || toward != oldDelegate.toward;
}

class SignalButton extends StatelessWidget {
  const SignalButton({
    super.key,
    required this.state,
    this.onPressed,
    this.label,
    this.destination,
    this.beatPhase = 0,
  });

  final SignalState state;
  final VoidCallback? onPressed;
  final String? label;
  final String? destination;
  final double beatPhase;

  @override
  Widget build(BuildContext context) {
    final action = state == SignalState.available ? onPressed : null;
    final text = label ?? state.label;
    final phase = MediaQuery.disableAnimationsOf(context) ? 0.0 : beatPhase;
    return Semantics(
      button: true,
      enabled: action != null,
      label: destination == null ? text : '$text $destination',
      onTap: action,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: action,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: action == null ? _line : _amber,
              borderRadius: BorderRadius.circular(8),
              border: action == null
                  ? null
                  : Border.all(
                      width: 2,
                      color: Color.lerp(
                        const Color(0xFFFFF1C4),
                        _amber,
                        phase,
                      )!,
                    ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (action != null)
                  const CustomPaint(size: Size(12, 12), painter: _SignalMark()),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: action == null ? _ink : _panel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (destination case final zone?)
                  Text(
                    zone,
                    style: const TextStyle(color: _panel, fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalMark extends CustomPainter {
  const _SignalMark();

  @override
  void paint(Canvas canvas, Size size) {
    final mark = Path()
      ..moveTo(2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(2, size.height)
      ..close();
    canvas.drawPath(mark, Paint()..color = _panel);
  }

  @override
  bool shouldRepaint(covariant _SignalMark oldDelegate) => false;
}

class BeatStrip extends StatelessWidget {
  const BeatStrip({
    super.key,
    required this.remaining,
    this.total = 4,
    this.label,
    this.combo = 0,
    this.holdingCombo = false,
    this.beatPhase,
    this.signalReady = false,
  }) : assert(total > 0 && remaining >= 0 && remaining <= total);

  final int remaining;
  final int total;
  final String? label;
  final int combo;
  final bool holdingCombo;
  final double? beatPhase;
  final bool signalReady;

  @override
  Widget build(BuildContext context) {
    final text = label ?? '남은 박 $remaining';
    final comboText = _comboLabel(combo, holdingCombo);
    return Semantics(
      label: combo == 0 ? text : '$text, $comboText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Text(text, style: const TextStyle(color: _ink)),
                _ComboBadge(count: combo, holding: holdingCombo),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: CustomPaint(
              painter: _RhythmTrack(
                phase: beatPhase,
                signalReady: signalReady,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmTrack extends CustomPainter {
  const _RhythmTrack({
    required this.phase,
    required this.signalReady,
    required this.reducedMotion,
  });

  final double? phase;
  final bool signalReady;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final lane = RRect.fromRectAndRadius(bounds, const Radius.circular(7));
    canvas.drawRRect(lane, Paint()..color = const Color(0xFF24203A));
    canvas.save();
    canvas.clipRRect(lane);
    final targetX = size.width * .82;
    final centerY = size.height / 2;
    final paint = Paint()..color = _line;
    canvas.drawLine(Offset(8, centerY), Offset(size.width - 8, centerY), paint);
    final beat = phase;
    final accent = signalReady ? _amber : _mint;
    if (beat != null) {
      final spacing = size.width * .19;
      final progress = reducedMotion ? 0.0 : beat;
      for (var index = 0; index <= 4; index++) {
        final x = targetX + (progress - index) * spacing;
        final emphasis = index == 0 && (reducedMotion || beat == 0);
        final side = emphasis ? 6.0 : 4.0;
        final note = Path()
          ..moveTo(x, centerY - side)
          ..lineTo(x + side, centerY)
          ..lineTo(x, centerY + side)
          ..lineTo(x - side, centerY)
          ..close();
        canvas.drawPath(
          note,
          paint..color = accent.withAlpha(emphasis ? 255 : 160),
        );
      }
    }
    canvas.drawLine(
      Offset(targetX, 3),
      Offset(targetX, size.height - 3),
      paint
        ..strokeWidth = 2
        ..color = beat == null ? _muted : accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RhythmTrack oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.signalReady != signalReady ||
      oldDelegate.reducedMotion != reducedMotion;
}

String _comboLabel(int count, bool holding) =>
    '$count 콤보${holding ? ' 유지' : ''}';

class _ComboBadge extends StatefulWidget {
  const _ComboBadge({required this.count, required this.holding});

  final int count;
  final bool holding;

  @override
  State<_ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<_ComboBadge>
    with SingleTickerProviderStateMixin {
  static final _punch = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 75),
  ]);

  late final AnimationController _pulse;
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _ComboBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holding ||
        widget.count == 0 ||
        MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
    } else if (widget.count > oldWidget.count) {
      _continued = oldWidget.holding;
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      child: Text(
        _comboLabel(widget.count, widget.holding),
        style: TextStyle(
          color: widget.holding ? _muted : _mint,
          fontWeight: FontWeight.w800,
        ),
      ),
      builder: (context, child) {
        final progress = reduceMotion ? 1.0 : _pulse.value;
        final amplitude = _continued ? .23 : .12;
        return CustomPaint(
          foregroundPainter: _ComboPixels(progress, _continued),
          child: Transform.scale(
            scale: 1 + amplitude * _punch.transform(progress),
            transformHitTests: false,
            child: child,
          ),
        );
      },
    );
  }
}

class _ComboPixels extends CustomPainter {
  const _ComboPixels(this.progress, this.continued);

  final double progress;
  final bool continued;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = (continued ? _amber : _mint).withAlpha(
        ((1 - progress) * 220).round(),
      );
    final spread = (progress * (continued ? 16 : 8)).roundToDouble();
    void pixel(double x, double y, double side) {
      canvas.drawRect(Rect.fromLTWH(x, y, side, side), paint);
    }

    pixel(4 - spread, 9 - spread / 2, 3);
    pixel(size.width - 8 + spread / 3, 13 + spread / 3, 3);
    if (continued) {
      pixel(size.width / 2 + spread, 5 - spread / 2, 4);
      pixel(size.width / 2 - spread, size.height - 4 + spread / 3, 3);
    }
  }

  @override
  bool shouldRepaint(covariant _ComboPixels oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.continued != continued;
}

class EventNotice extends StatelessWidget {
  const EventNotice({
    super.key,
    required this.message,
    this.remainingBeats,
    this.compact = false,
  });

  final String message;
  final int? remainingBeats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? 52 : null,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF382A33),
        border: Border.all(color: _amber.withAlpha(140)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        remainingBeats == null ? message : '$message · $remainingBeats박 후',
        style: TextStyle(color: _amber, fontSize: compact ? 13 : null),
      ),
    );
  }
}

class PerformanceScore extends StatelessWidget {
  const PerformanceScore({
    super.key,
    required this.score,
    this.maximum = 90,
    this.compact = false,
  }) : assert(maximum > 0 && score >= 0 && score <= maximum);

  final int score;
  final int maximum;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '공연 점수 $score점, $maximum점 만점',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: _muted),
          children: [
            if (!compact) const TextSpan(text: '공연 점수  '),
            TextSpan(
              text: '$score',
              style: TextStyle(
                color: _ink,
                fontSize: compact ? 16 : 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: ' / $maximum'),
          ],
        ),
      ),
    );
  }
}

class ZoneControlCard extends StatelessWidget {
  const ZoneControlCard({
    super.key,
    required this.zone,
    required this.status,
    required this.volume,
    required this.onVolumeChanged,
    required this.target,
    required this.cue,
    this.enabled = true,
    this.onInteractionEnd,
    this.selected = false,
    this.needsRescue = false,
  });

  final String zone;
  final CrowdStatus status;
  final int volume;
  final ValueChanged<int> onVolumeChanged;
  final ({int minimum, int maximum}) target;
  final MixCue cue;
  final bool enabled;
  final VoidCallback? onInteractionEnd;
  final bool selected;
  final bool needsRescue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xED24203A),
        borderRadius: BorderRadius.circular(10),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: status.color.withAlpha(selected || needsRescue ? 255 : 180),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            zone,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text('$volume%', style: const TextStyle(color: _ink, fontSize: 12)),
          ZoneVolumeSlider(
            zone: zone,
            value: volume,
            onChanged: onVolumeChanged,
            highlighted: cue == MixCue.adjust,
            target: target,
            vertical: true,
            enabled: enabled,
            onInteractionEnd: onInteractionEnd,
          ),
          CrowdStatusBadge(status: status, compact: true),
        ],
      ),
    );
  }
}
