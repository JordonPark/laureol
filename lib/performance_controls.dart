import 'package:flutter/widgets.dart';

const _ink = Color(0xFFF6F0E7);
const _muted = Color(0xFFBDB8CD);
const _panel = Color(0xFF24203A);
const _line = Color(0xFF514866);
const _amber = Color(0xFFFFC46A);
const _mint = Color(0xFF7CE0C2);
const _coral = Color(0xFFFFA18B);

enum CrowdStatus {
  quiet('작음', '귀 기울이기', '↓', _amber),
  ready('준비', '박수', '✓', _mint),
  loud('큼', '귀 막기', '↑', _coral),
  singing('떼창', '함께 노래하기', '♪', _mint);

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

class CrowdStatusBadge extends StatelessWidget {
  const CrowdStatusBadge({super.key, required this.status});

  final CrowdStatus status;

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '${status.symbol}  ${status.label}',
            style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
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
    this.target,
    this.onInteractionEnd,
  }) : assert(value >= 0 && value <= 100);

  final String zone;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool highlighted;
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
              height: 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const thumb = 20.0;
                  final track = constraints.maxWidth - thumb;
                  if (track <= 0) return const SizedBox.shrink();
                  final filled = track * value / 100;

                  void update(double x) {
                    onChanged(
                      ((x - thumb / 2) / track * 100).round().clamp(0, 100),
                    );
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: enabled
                        ? (details) => update(details.localPosition.dx)
                        : null,
                    onTapUp: enabled && onInteractionEnd != null
                        ? (_) => onInteractionEnd!()
                        : null,
                    onHorizontalDragStart: enabled
                        ? (details) => update(details.localPosition.dx)
                        : null,
                    onHorizontalDragUpdate: enabled
                        ? (details) => update(details.localPosition.dx)
                        : null,
                    onHorizontalDragEnd: enabled && onInteractionEnd != null
                        ? (_) => onInteractionEnd!()
                        : null,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignalButton extends StatelessWidget {
  const SignalButton({
    super.key,
    required this.state,
    this.onPressed,
    this.label,
  });

  final SignalState state;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final action = state == SignalState.available ? onPressed : null;
    final text = label ?? state.label;
    return Semantics(
      button: true,
      enabled: action != null,
      label: text,
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
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: action == null ? _ink : _panel,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeatStrip extends StatelessWidget {
  const BeatStrip({
    super.key,
    required this.remaining,
    this.total = 4,
    this.label,
    this.combo = 0,
    this.holdingCombo = false,
  }) : assert(total > 0 && remaining >= 0 && remaining <= total);

  final int remaining;
  final int total;
  final String? label;
  final int combo;
  final bool holdingCombo;

  @override
  Widget build(BuildContext context) {
    final text = label ?? '남은 박 $remaining';
    final segments = total > 6 ? 6 : total;
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
          Row(
            children: List.generate(
              segments,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ColoredBox(
                    color: index * total < remaining * segments
                        ? _amber
                        : _line,
                    child: const SizedBox(height: 5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    required this.signalState,
    this.onSignal,
    this.compact = false,
    this.selected = false,
    this.needsRescue = false,
  });

  final String zone;
  final CrowdStatus status;
  final int volume;
  final ValueChanged<int> onVolumeChanged;
  final SignalState signalState;
  final VoidCallback? onSignal;
  final bool compact;
  final bool selected;
  final bool needsRescue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(
          color: needsRescue
              ? _amber
              : selected
              ? status.color
              : _line,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zone,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 2 : 6),
          CrowdStatusBadge(status: status),
          SizedBox(height: compact ? 4 : 12),
          ZoneVolumeSlider(
            zone: zone,
            value: volume,
            onChanged: onVolumeChanged,
          ),
          SignalButton(state: signalState, onPressed: onSignal),
        ],
      ),
    );
  }
}
