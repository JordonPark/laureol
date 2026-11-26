import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show
        DeviceGestureSettings,
        DragStartBehavior,
        PanGestureRecognizer,
        TapGestureRecognizer;
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

enum VolumeDialStyle {
  front(Color(0xFF89D8CB), Color(0xFF3D7A74), Color(0xFF183735), 8),
  back(Color(0xFFEAB681), Color(0xFF98643E), Color(0xFF482D2A), 6);

  const VolumeDialStyle(this.lit, this.finish, this.edge, this.grips);

  final Color lit;
  final Color finish;
  final Color edge;
  final int grips;
}

const _dialStart = 3 * math.pi / 4;
const _dialSweep = 3 * math.pi / 2;
double _dialRadius(Size size) => size.shortestSide / 2 - 12;

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
    this.dialStyle = VolumeDialStyle.front,
    this.target,
    this.onInteractionStart,
    this.onInteractionEnd,
  }) : assert(value >= 0 && value <= 100);

  final String zone;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool highlighted;
  final bool vertical;
  final VolumeDialStyle dialStyle;
  final ({int minimum, int maximum})? target;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final band = target;
    final step = vertical ? 1 : 5;
    void adjustBy(int delta) {
      onInteractionStart?.call();
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
          ? '${(value + step).clamp(0, 100)}%'
          : null,
      decreasedValue: enabled && value > 0
          ? '${(value - step).clamp(0, 100)}%'
          : null,
      slider: true,
      onIncrease: enabled && value < 100 ? () => adjustBy(step) : null,
      onDecrease: enabled && value > 0 ? () => adjustBy(-step) : null,
      child: ExcludeSemantics(
        child: vertical
            ? _VolumeDialGesture(
                value: value,
                enabled: enabled,
                style: dialStyle,
                guide: band,
                onChanged: onChanged,
                onInteractionStart: onInteractionStart,
                onInteractionEnd: onInteractionEnd,
              )
            : Column(
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
                        final length = constraints.maxWidth;
                        final track = length - thumb;
                        if (track <= 0) return const SizedBox.shrink();
                        final filled = track * value / 100;

                        void update(double x) {
                          onChanged(
                            ((x - thumb / 2) / track * 100).round().clamp(
                              0,
                              100,
                            ),
                          );
                        }

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
                                  width:
                                      track *
                                      (band.maximum - band.minimum) /
                                      100,
                                  height: 16,
                                  child: const ColoredBox(color: _mint),
                                ),
                              if (highlighted &&
                                  band != null &&
                                  (value < band.minimum ||
                                      value > band.maximum))
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
                          onHorizontalDragEnd:
                              enabled && onInteractionEnd != null
                              ? (_) => onInteractionEnd!()
                              : null,
                          child: graphics,
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

class _VolumeDialGesture extends StatefulWidget {
  const _VolumeDialGesture({
    required this.value,
    required this.enabled,
    required this.style,
    required this.guide,
    required this.onChanged,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  final int value;
  final bool enabled;
  final VolumeDialStyle style;
  final ({int minimum, int maximum})? guide;
  final ValueChanged<int> onChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  @override
  State<_VolumeDialGesture> createState() => _VolumeDialGestureState();
}

enum _DialMotion { slide, turn }

class _VolumeDialGestureState extends State<_VolumeDialGesture> {
  static const _pixelsPerPoint = 3.0;
  static const _dragSettings = DeviceGestureSettings(touchSlop: 1.5);

  double? _dragValue;
  late int _lastDragVolume;
  _DialMotion? _motion;

  void _startDrag(DragStartDetails _) {
    _dragValue = widget.value.toDouble();
    _lastDragVolume = widget.value;
    _motion = null;
    widget.onInteractionStart?.call();
  }

  void _drag(DragUpdateDetails details, double side) {
    final delta = details.delta;
    if (delta == Offset.zero) return;
    final current = details.localPosition - Offset(side / 2, side / 2);
    final previous = current - delta;

    _motion ??= _recognizeMotion(previous, delta, side);
    if (_motion == _DialMotion.slide) {
      _adjust(-delta.dy / _pixelsPerPoint);
      return;
    }
    if (_motion != _DialMotion.turn) return;

    // Angle estimates become noisy near the center. Reduce their influence
    // gradually so a thumb that drifts inward can keep turning.
    final projection =
        -(previous.dx * delta.dx + previous.dy * delta.dy) /
        delta.distanceSquared;
    final nearest = previous + delta * projection.clamp(0.0, 1.0);
    final turnWeight = ((nearest.distance - 4) / (side * .21 - 4)).clamp(
      0.0,
      1.0,
    );
    final change =
        (current.direction - previous.direction + math.pi) % (2 * math.pi) -
        math.pi;
    _adjust(change * 100 / _dialSweep * turnWeight);
  }

  _DialMotion? _recognizeMotion(Offset previous, Offset delta, double side) {
    final radius = previous.distance;
    final tangent = (previous.dx * delta.dy - previous.dy * delta.dx).abs();
    if (radius >= side * .11 && tangent >= radius * delta.distance * .58) {
      return _DialMotion.turn;
    }
    return delta.dy.abs() > delta.dx.abs() * 1.2 ? _DialMotion.slide : null;
  }

  void _adjust(double delta) {
    final previous = _dragValue;
    if (previous == null) return;
    final next = (previous + delta).clamp(0.0, 100.0);
    if (previous == next) return;
    setState(() => _dragValue = next);
    final rounded = next.round();
    if (rounded != _lastDragVolume) {
      _lastDragVolume = rounded;
      widget.onChanged(rounded);
    }
  }

  void _clearDrag() {
    if (_dragValue != null) setState(() => _dragValue = null);
  }

  void _finishDrag(DragEndDetails _) {
    _clearDrag();
    widget.onInteractionEnd?.call();
  }

  void _tap(TapUpDetails details, double side) {
    widget.onInteractionStart?.call();
    final point = details.localPosition;
    final offset = point.dy - side / 2;
    if (point.dx < side * .62 || offset.abs() < side * .25) return;
    final value = (widget.value + (offset < 0 ? 1 : -1)).clamp(0, 100);
    if (value != widget.value) widget.onChanged(value);
    widget.onInteractionEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final visibleVolume = _dragValue ?? widget.value.toDouble();
    return LayoutBuilder(
      builder: (context, bounds) {
        final side = math.min(
          128.0,
          math.min(bounds.maxWidth, bounds.maxHeight),
        );
        return Center(
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            gestures: {
              if (widget.enabled) ...{
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                      TapGestureRecognizer.new,
                      (recognizer) =>
                          recognizer.onTapUp = (details) => _tap(details, side),
                    ),
                PanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                      PanGestureRecognizer.new,
                      (recognizer) {
                        recognizer
                          ..gestureSettings = _dragSettings
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = _startDrag
                          ..onEnd = _finishDrag
                          ..onCancel = _clearDrag;
                        recognizer.onUpdate = (details) => _drag(details, side);
                      },
                    ),
              },
            },
            child: SizedBox.square(
              dimension: side,
              child: CustomPaint(
                painter: _VolumeDialPainter(
                  value: visibleVolume,
                  enabled: widget.enabled,
                  style: widget.style,
                ),
                foregroundPainter: widget.guide == null
                    ? null
                    : _VolumeDialGuidePainter(widget.guide!),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolumeDialPainter extends CustomPainter {
  const _VolumeDialPainter({
    required this.value,
    required this.enabled,
    required this.style,
  });

  final double value;
  final bool enabled;
  final VolumeDialStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2);
    final radius = _dialRadius(size);
    if (radius <= 12) return;

    final angle = _dialStart + _dialSweep * value / 100;
    Offset radial(double heading, double distance) =>
        origin + Offset(math.cos(heading), math.sin(heading)) * distance;

    final ring = Rect.fromCircle(center: origin, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF100F1A);
    canvas.drawArc(ring, _dialStart, _dialSweep, false, stroke);
    canvas.drawArc(
      ring,
      _dialStart,
      angle - _dialStart,
      false,
      stroke
        ..strokeWidth = 2.5
        ..color = style.finish,
    );
    for (var index = 0; index <= 16; index++) {
      final tick = _dialStart + _dialSweep * index / 16;
      final major = index % 4 == 0;
      canvas.drawLine(
        radial(tick, radius + 4),
        radial(tick, radius + (major ? 8 : 6)),
        stroke
          ..strokeWidth = major ? 1.75 : 1
          ..color = major ? _muted : _line,
      );
    }
    final pointer = enabled ? _ink : _muted;
    final gripRadius = radius - 7;
    canvas.drawCircle(
      origin.translate(0, 2),
      gripRadius + 1.5,
      Paint()..color = const Color(0xFF0C0D16),
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle + math.pi / 2);
    _paintCap(canvas, gripRadius, pointer);
    canvas.restore();
    canvas.drawCircle(radial(angle, radius), 2.3, Paint()..color = pointer);

    if (enabled) {
      _paintKey(canvas, Offset(size.width - 8, 8), add: true);
      _paintKey(canvas, Offset(size.width - 8, size.height - 8), add: false);
    }
  }

  void _paintCap(Canvas canvas, double radius, Color pointer) {
    final outline = Path();
    final step = 2 * math.pi / style.grips;
    for (var index = 0; index < style.grips; index++) {
      for (final (offset, depth) in [
        (-.5, .86),
        (-.29, 1.0),
        (.29, 1.0),
        (.5, .86),
      ]) {
        final angle = step * (index + offset) - math.pi / 2;
        final point =
            Offset(math.cos(angle), math.sin(angle)) * (radius * depth);
        if (index == 0 && offset == -.5) {
          outline.moveTo(point.dx, point.dy);
        } else {
          outline.lineTo(point.dx, point.dy);
        }
      }
    }
    outline.close();
    final edge = enabled ? style.edge : const Color(0xFF292836);
    final finish = enabled ? style.finish : const Color(0xFF535365);
    final lit = enabled ? style.lit : _muted;
    final bevel = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lit, finish, edge],
    );
    final paint = Paint()
      ..shader = bevel.createShader(
        Rect.fromCircle(center: Offset.zero, radius: radius),
      );
    canvas.drawPath(outline, paint);
    paint.shader = null;
    canvas.drawPath(
      outline,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = edge,
    );
    final face = Rect.fromCircle(center: Offset.zero, radius: radius * .73);
    canvas.drawCircle(
      Offset.zero,
      face.width / 2,
      paint
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [finish, edge],
        ).createShader(face),
    );
    paint.shader = null;
    canvas.drawArc(
      face,
      math.pi,
      math.pi,
      false,
      paint
        ..style = PaintingStyle.stroke
        ..color = lit.withAlpha(165),
    );
    final slot = RRect.fromRectAndRadius(
      Rect.fromLTRB(-2, -radius * .95, 2, -radius * .42),
      const Radius.circular(1),
    );
    canvas.drawRRect(
      slot,
      paint
        ..style = PaintingStyle.fill
        ..color = pointer,
    );
  }

  void _paintKey(Canvas canvas, Offset center, {required bool add}) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 14, height: 14),
      const Radius.circular(3),
    );
    final paint = Paint()..color = const Color(0xFF141520);
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(
      rect,
      paint
        ..style = PaintingStyle.stroke
        ..color = _line,
    );
    paint
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    canvas.drawLine(center.translate(-3, 0), center.translate(3, 0), paint);
    if (add) {
      canvas.drawLine(center.translate(0, -3), center.translate(0, 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeDialPainter oldDelegate) =>
      value != oldDelegate.value ||
      enabled != oldDelegate.enabled ||
      style != oldDelegate.style;
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
    final queued = state == SignalState.queued;
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
              color: action != null
                  ? _amber
                  : queued
                  ? const Color(0xFF493624)
                  : _line,
              borderRadius: BorderRadius.circular(8),
              border: action == null
                  ? (queued ? Border.all(color: _amber) : null)
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
                if (queued) const Text('✓', style: TextStyle(color: _amber)),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: action != null ? _panel : (queued ? _amber : _ink),
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

String _comboLabel(int count, bool holding) =>
    '$count 콤보${holding ? ' 유지' : ''}';

class ComboBadge extends StatefulWidget {
  const ComboBadge({super.key, required this.count, required this.holding});

  final int count;
  final bool holding;

  @override
  State<ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<ComboBadge>
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
  void didUpdateWidget(covariant ComboBadge oldWidget) {
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
    required this.dialStyle,
    required this.status,
    required this.volume,
    required this.onVolumeChanged,
    required this.target,
    required this.cue,
    required this.onInteractionStart,
    this.enabled = true,
    this.onInteractionEnd,
    this.selected = false,
    this.needsRescue = false,
  });

  final String zone;
  final VolumeDialStyle dialStyle;
  final CrowdStatus status;
  final int volume;
  final ValueChanged<int> onVolumeChanged;
  final ({int minimum, int maximum}) target;
  final MixCue cue;
  final VoidCallback onInteractionStart;
  final bool enabled;
  final VoidCallback? onInteractionEnd;
  final bool selected;
  final bool needsRescue;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final footerLineHeight = textScaler.scale(11) * 1.5 + 6;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          children: [
            SizedBox(
              height: textScaler.scale(13) * 1.5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Text(
                      zone,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$volume%',
                      style: const TextStyle(color: _ink, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ZoneVolumeSlider(
                zone: zone,
                value: volume,
                onChanged: onVolumeChanged,
                highlighted: cue == MixCue.adjust,
                target: target,
                vertical: true,
                dialStyle: dialStyle,
                enabled: enabled,
                onInteractionStart: onInteractionStart,
                onInteractionEnd: onInteractionEnd,
              ),
            ),
            SizedBox(
              height: footerLineHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CrowdStatusBadge(status: status, compact: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeDialGuidePainter extends CustomPainter {
  const _VolumeDialGuidePainter(this.target);

  final ({int minimum, int maximum}) target;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2);
    final radius = _dialRadius(size);
    if (radius <= 12) return;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _mint;
    for (
      var mark = (target.minimum + 1) ~/ 2 * 2;
      mark <= target.maximum;
      mark += 2
    ) {
      final angle = _dialStart + _dialSweep * mark / 100;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        origin + direction * (radius + 3),
        origin + direction * (radius + 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeDialGuidePainter oldDelegate) =>
      target != oldDelegate.target;
}
