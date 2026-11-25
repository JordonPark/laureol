import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'festival_performance.dart';
import 'performance_controls.dart';

double _sceneY(double y, bool compact) {
  if (!compact) return y;
  if (y <= 178) return y * (135 / 178);
  return 135 + (y - 178) * (130 / 146);
}

enum _Sprite {
  ground('festival/ground', 1774, 887, Rect.fromLTRB(30, 179, 1741, 707)),
  stage('festival/stage', 1536, 1024, Rect.fromLTRB(122, 21, 1408, 987)),
  backdrop('festival/backdrop', 1774, 887, Rect.fromLTRB(241, 39, 1532, 879)),
  speaker('festival/speaker', 1774, 887, Rect.fromLTRB(619, 11, 1148, 876)),
  lighting('festival/lighting', 1774, 887, Rect.fromLTRB(625, 18, 1128, 882)),
  truck('festival/food-truck', 1774, 887, Rect.fromLTRB(273, 13, 1485, 876)),
  generator('festival/generator', 1774, 887, Rect.fromLTRB(502, 28, 1267, 870)),
  vocal(
    'stage-characters/vocal-sing',
    543,
    724,
    Rect.fromLTRB(116, 12, 448, 712),
    animated: true,
  ),
  offer(
    'stage-characters/vocal-offer',
    543,
    724,
    Rect.fromLTRB(110, 12, 520, 712),
    animated: true,
  ),
  musician(
    'stage-characters/musician-play',
    543,
    724,
    Rect.fromLTRB(75, 21, 516, 702),
    animated: true,
  ),
  vendor(
    'stage-characters/vendor-clap',
    543,
    724,
    Rect.fromLTRB(47, 23, 509, 702),
    animated: true,
  ),
  jacket('crowd/body-jacket', 1024, 1536, Rect.fromLTRB(288, 300, 722, 1296)),
  sweater('crowd/body-sweater', 1199, 1312, Rect.fromLTRB(394, 225, 761, 1137)),
  cap('crowd/head-cap', 1536, 1024, Rect.fromLTRB(349, 154, 1167, 875)),
  beanie('crowd/head-beanie', 1312, 1199, Rect.fromLTRB(226, 207, 1089, 1000)),
  sweaterCovering(
    'crowd/sweater-cover-ears',
    543,
    724,
    Rect.fromLTRB(118, 39, 394, 687),
    animated: true,
  ),
  sweaterSinging(
    'crowd/sweater-sing',
    543,
    724,
    Rect.fromLTRB(82, 55, 455, 686),
    animated: true,
  ),
  jacketCovering(
    'crowd/jacket-cover-ears',
    543,
    724,
    Rect.fromLTRB(118, 34, 400, 688),
    animated: true,
  ),
  jacketSinging(
    'crowd/jacket-sing',
    543,
    724,
    Rect.fromLTRB(88, 57, 407, 683),
    animated: true,
  ),
  listening(
    'crowd/listen',
    543,
    724,
    Rect.fromLTRB(80, 31, 440, 691),
    animated: true,
  ),
  clapping(
    'crowd/clap',
    543,
    724,
    Rect.fromLTRB(110, 23, 398, 698),
    animated: true,
  ),
  covering(
    'crowd/cover-ears',
    543,
    724,
    Rect.fromLTRB(106, 40, 406, 682),
    animated: true,
  ),
  singing(
    'crowd/sing',
    543,
    724,
    Rect.fromLTRB(94, 63, 448, 673),
    animated: true,
  ),
  rumble(
    'effects/generator-rumble',
    543,
    724,
    Rect.fromLTRB(60, 226, 481, 481),
    animated: true,
  ),
  wave(
    'effects/singalong-wave',
    543,
    724,
    Rect.fromLTRB(32, 224, 495, 535),
    animated: true,
  );

  const _Sprite(
    this.path,
    this.width,
    this.height,
    this.crop, {
    this.animated = false,
  });

  final String path;
  final int width;
  final int height;
  final Rect crop;
  final bool animated;
}

class FestivalScene extends StatefulWidget {
  const FestivalScene({
    super.key,
    required this.tick,
    required this.front,
    required this.back,
    required this.generatorRunning,
    required this.signalQueued,
    this.waveFrame,
    this.waveTowardBack = true,
    this.compact = false,
    this.focusedZone,
    this.focusedVolume,
    this.onZoneSelected,
    this.venue = FestivalVenue.neighborhood,
    this.lightingTier = 0,
    this.comboEffect,
    this.frontCue = MixCue.none,
    this.backCue = MixCue.none,
    this.readyPulse = 0,
    this.readyZones = 0,
  });

  final int tick;
  final CrowdStatus front;
  final CrowdStatus back;
  final bool generatorRunning;
  final bool signalQueued;
  final int? waveFrame;
  final bool waveTowardBack;
  final bool compact;
  final FestivalZone? focusedZone;
  final int? focusedVolume;
  final ValueChanged<FestivalZone>? onZoneSelected;
  final FestivalVenue venue;
  final int lightingTier;
  final ({int count, int elapsedTicks})? comboEffect;
  final MixCue frontCue;
  final MixCue backCue;
  final int readyPulse;
  final int readyZones;

  @override
  State<FestivalScene> createState() => _FestivalSceneState();
}

class _FestivalSceneState extends State<FestivalScene> {
  final _images = <_Sprite, ui.Image>{};
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadSprites();
  }

  Future<void> _loadSprite(_Sprite sprite) async {
    final bytes = await rootBundle.load('docs/art/${sprite.path}.png');
    if (!mounted) return;
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: sprite.animated ? 864 : 480,
    );
    try {
      final image = (await codec.getNextFrame()).image;
      if (!mounted) {
        image.dispose();
        return;
      }
      _images[sprite] = image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _loadSprites() async {
    try {
      await Future.wait(_Sprite.values.map(_loadSprite));
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'festival scene',
        ),
      );
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description =
        '${widget.venue.title}. 앞줄 ${widget.front.label}, '
        '뒷줄 ${widget.back.label}. '
        '발전기 ${widget.generatorRunning ? '작동 중' : '정지'}.';
    return Semantics(
      label: description,
      image: true,
      explicitChildNodes: true,
      child: AspectRatio(
        aspectRatio: 360 / (widget.compact ? 265 : 324),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _failed
              ? const Center(child: Text('공연 장면을 불러오지 못했어요.'))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey(widget.readyPulse),
                      tween: Tween(begin: 0, end: 1),
                      duration:
                          widget.readyZones == 0 ||
                              MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 480),
                      builder: (context, progress, _) => CustomPaint(
                        painter: _FestivalPainter(
                          images: _images,
                          tick: widget.tick,
                          front: widget.front,
                          back: widget.back,
                          generatorRunning: widget.generatorRunning,
                          signalQueued: widget.signalQueued,
                          waveFrame: widget.waveFrame,
                          waveTowardBack: widget.waveTowardBack,
                          compact: widget.compact,
                          focusedZone: widget.focusedZone,
                          focusedVolume: widget.focusedVolume,
                          canSelectAudience: widget.onZoneSelected != null,
                          venue: widget.venue,
                          lightingTier: widget.lightingTier,
                          frontCue: widget.frontCue,
                          backCue: widget.backCue,
                          readyZones: widget.readyZones,
                          pulseProgress: progress,
                        ),
                      ),
                    ),
                    if (widget.onZoneSelected != null)
                      LayoutBuilder(builder: _audienceTargets),
                    if (widget.comboEffect case final celebration?)
                      _ComboCelebration(
                        count: celebration.count,
                        progress: celebration.elapsedTicks / comboEffectTicks,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _audienceTargets(BuildContext context, BoxConstraints bounds) {
    final scale = bounds.maxHeight / (widget.compact ? 265.0 : 324.0);
    double canvasY(double y) => _sceneY(y, widget.compact) * scale;

    Widget target(FestivalZone zone, String label, double top, double bottom) {
      return Positioned(
        left: 0,
        top: canvasY(top),
        width: bounds.maxWidth * .70,
        height: canvasY(bottom) - canvasY(top),
        child: Semantics(
          button: true,
          label: '$label 볼륨 조작으로 이동',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onZoneSelected!(zone),
          ),
        ),
      );
    }

    return Stack(
      children: [
        target(FestivalZone.front, '앞줄', 181, 240),
        target(FestivalZone.back, '뒷줄', 240, 324),
      ],
    );
  }
}

class _ComboCelebration extends StatelessWidget {
  const _ComboCelebration({required this.count, required this.progress});

  final int count;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final accent = switch (count) {
      10 => const Color(0xFF7CE0C2),
      25 => const Color(0xFFFFC46A),
      _ => const Color(0xFFFF9EDA),
    };
    final fade = (1 - (progress - .7) / .3).clamp(0.0, 1.0);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!reducedMotion)
              CustomPaint(
                painter: _ComboWavePainter(color: accent, progress: progress),
              ),
            Align(
              alignment: const Alignment(0, -.84),
              child: Opacity(
                opacity: reducedMotion ? 1 : fade,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF21B1529),
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    child: Text(
                      '$count 콤보!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboWavePainter extends CustomPainter {
  const _ComboWavePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * .49);
    final range = size.width * (.19 + progress * .31);
    final paint = Paint()
      ..color = color.withAlpha(((1 - progress) * 216).round());
    for (var i = 0; i < 9; i++) {
      final x = (i - 4) / 4;
      final rise = (i.isEven ? .16 : .09) + (1 - x.abs()) * .13;
      final point = origin + Offset(x * range, -size.height * rise * progress);
      final spark = i.isEven ? 4.0 : 3.0;
      canvas.drawRect(
        Rect.fromCenter(center: point, width: spark, height: spark),
        paint,
      );
    }
    final spread = size.height * progress;
    final wave = Path()
      ..moveTo(origin.dx - range, origin.dy + spread * .11)
      ..quadraticBezierTo(
        origin.dx,
        origin.dy + size.height * .13 + spread * .36,
        origin.dx + range,
        origin.dy + spread * .11,
      );
    canvas.drawPath(
      wave,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ComboWavePainter oldDelegate) =>
      color != oldDelegate.color || progress != oldDelegate.progress;
}

class _FestivalPainter extends CustomPainter {
  _FestivalPainter({
    required Map<_Sprite, ui.Image> images,
    required this.tick,
    required this.front,
    required this.back,
    required this.generatorRunning,
    required this.signalQueued,
    required this.waveFrame,
    required this.waveTowardBack,
    required this.compact,
    required this.focusedZone,
    required this.focusedVolume,
    required this.canSelectAudience,
    required this.venue,
    required this.lightingTier,
    required this.frontCue,
    required this.backCue,
    required this.readyZones,
    required this.pulseProgress,
  }) : images = Map.of(images);

  final Map<_Sprite, ui.Image> images;
  final int tick;
  final CrowdStatus front;
  final CrowdStatus back;
  final bool generatorRunning;
  final bool signalQueued;
  final int? waveFrame;
  final bool waveTowardBack;
  final bool compact;
  final FestivalZone? focusedZone;
  final int? focusedVolume;
  final bool canSelectAudience;
  final FestivalVenue venue;
  final int lightingTier;
  final MixCue frontCue;
  final MixCue backCue;
  final int readyZones;
  final double pulseProgress;

  final _nearest = Paint()..filterQuality = FilterQuality.none;

  double _y(double y) => _sceneY(y, compact);

  void _draw(
    Canvas canvas,
    _Sprite sprite,
    Offset base,
    double height, {
    int frame = 0,
    bool mirror = false,
  }) {
    final image = images[sprite];
    if (image == null) return;
    final sx = image.width / (sprite.width * (sprite.animated ? 4 : 1));
    final sy = image.height / sprite.height;
    final crop = sprite.crop.shift(Offset(sprite.width * frame.toDouble(), 0));
    final source = Rect.fromLTRB(
      crop.left * sx,
      crop.top * sy,
      crop.right * sx,
      crop.bottom * sy,
    );
    final size = compact && base.dy <= 178 ? height * .77 : height;
    final width = size * crop.width / crop.height;
    canvas.save();
    canvas.translate(base.dx, _y(base.dy));
    if (mirror) canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(-width / 2, -size, width, size),
      _nearest,
    );
    canvas.restore();
  }

  void _crowd(
    Canvas canvas,
    CrowdStatus status,
    List<Offset> positions,
    double height, {
    required bool frontRow,
    required Color zoneColor,
  }) {
    final sprite = switch (status) {
      CrowdStatus.quiet => _Sprite.listening,
      CrowdStatus.ready => _Sprite.clapping,
      CrowdStatus.loud => _Sprite.covering,
      CrowdStatus.singing => _Sprite.singing,
    };
    for (var i = 0; i < positions.length; i++) {
      final position = positions[i];
      final phase = (tick + (status == CrowdStatus.singing ? 0 : i)) % 4;
      if (i == 1 || i == 2) {
        final sweater = (i == 1) == frontRow;
        final reaction = switch (status) {
          CrowdStatus.loud =>
            sweater ? _Sprite.sweaterCovering : _Sprite.jacketCovering,
          CrowdStatus.singing =>
            sweater ? _Sprite.sweaterSinging : _Sprite.jacketSinging,
          CrowdStatus.quiet || CrowdStatus.ready => null,
        };
        if (reaction != null) {
          _draw(
            canvas,
            reaction,
            position,
            height,
            frame: phase,
            mirror: !frontRow,
          );
          continue;
        }
        final bodyHeight = height * .68;
        final bounce = phase == 1 || phase == 2 ? 2.0 : 0.0;
        // Keep the neck and feet anchored as the two sprite layers move together.
        _draw(
          canvas,
          sweater ? _Sprite.sweater : _Sprite.jacket,
          position.translate(0, -bounce),
          bodyHeight,
        );
        _draw(
          canvas,
          sweater ? _Sprite.cap : _Sprite.beanie,
          position.translate(1, 3 - bodyHeight - bounce),
          height * .34,
        );
        continue;
      }
      if (i == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(position.dx, _y(position.dy) + 1),
            width: 30,
            height: 8,
          ),
          Paint()..color = zoneColor.withAlpha(175),
        );
      }
      _draw(
        canvas,
        sprite,
        position,
        i == 0 ? height * 1.12 : height,
        frame: phase,
        mirror: i.isOdd,
      );
    }
  }

  void _zoneLabel(
    Canvas canvas,
    String label,
    Color color,
    Offset offset, {
    required bool focused,
    required Color statusColor,
  }) {
    offset = Offset(offset.dx, _y(offset.dy));
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontFamily: 'Laureol Sans',
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx, offset.dy, text.width + 14, text.height + 8),
      const Radius.circular(5),
    );
    canvas.drawRRect(box, Paint()..color = const Color(0xFF211D32));
    canvas.drawRRect(
      box,
      Paint()
        ..color = statusColor
        ..strokeWidth = focused ? 2 : 1
        ..style = PaintingStyle.stroke,
    );
    text.paint(canvas, offset + const Offset(7, 4));
    text.dispose();
  }

  void _highlightAudience(Canvas canvas, bool frontRow, Color color) {
    final shift = frontRow ? 0.0 : 64.0;
    final outline = Path()
      ..moveTo(66, _y(204 + shift))
      ..lineTo(163, _y(185 + shift))
      ..lineTo(243, _y(204 + shift))
      ..lineTo(220, _y(229 + shift))
      ..lineTo(128, _y(244 + shift))
      ..lineTo(66, _y(226 + shift))
      ..close();
    canvas.drawPath(outline, Paint()..color = color.withAlpha(55));
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withAlpha(190),
    );
  }

  Color _zoneColor(MixCue cue, Color idle) => switch (cue) {
    MixCue.adjust => const Color(0xFF7CE0C2),
    MixCue.signal => const Color(0xFFFFC46A),
    MixCue.none => idle,
  };

  String _zoneMark(MixCue cue, CrowdStatus status) => switch (cue) {
    MixCue.adjust => status == CrowdStatus.quiet ? '››' : '‹‹',
    MixCue.signal => '▶',
    MixCue.none => status.symbol,
  };

  void _drawReadyPulse(Canvas canvas) {
    if (readyZones == 0 || pulseProgress >= 1) return;
    final fade = (210 * (1 - pulseProgress)).round();
    final radius = 34 + pulseProgress * 94;
    final paint = Paint()
      ..color = const Color(0xFF7CE0C2).withAlpha(fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final zone in FestivalZone.values) {
      if (readyZones & (1 << zone.index) == 0) continue;
      final y = _y(zone == FestivalZone.front ? 215 : 281);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(155, y),
          width: radius * 2,
          height: radius * .50,
        ),
        paint,
      );
    }
  }

  void _drawStageLights(Canvas canvas) {
    if (lightingTier == 0 && venue != FestivalVenue.nightMarket) return;
    const colors = [Color(0xFF7CE0C2), Color(0xFFFFC46A), Color(0xFFFF9EDA)];
    for (
      var i = 0;
      i < lightingTier + (venue == FestivalVenue.nightMarket ? 1 : 0);
      i++
    ) {
      final x = 78.0 + i * 55;
      final color = colors[i % colors.length];
      final beam = Path()
        ..moveTo(x, _y(89))
        ..lineTo(x - 52, _y(177))
        ..lineTo(x + 64, _y(177))
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = ui.Gradient.linear(Offset(x, _y(89)), Offset(x, _y(177)), [
            color.withAlpha(158),
            color.withAlpha(35),
          ]),
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 3, _y(90), 6, 5),
        Paint()..color = color,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final height = compact ? 265.0 : 324.0;
    canvas.scale(size.width / 360, size.height / height);
    final scene = Rect.fromLTWH(0, 0, 360, height);
    canvas.drawRect(
      scene,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, height),
          venue == FestivalVenue.nightMarket
              ? const [Color(0xFF1C3E54), Color(0xFF182633)]
              : const [Color(0xFF3D2F53), Color(0xFF211E34)],
        ),
    );
    _draw(canvas, _Sprite.ground, const Offset(176, 327), 149);
    final frontFocused = focusedZone == FestivalZone.front;
    final backFocused = focusedZone == FestivalZone.back;
    if (frontFocused || frontCue != MixCue.none) {
      _highlightAudience(canvas, true, _zoneColor(frontCue, front.color));
    }
    if (backFocused || backCue != MixCue.none) {
      _highlightAudience(canvas, false, _zoneColor(backCue, back.color));
    }
    _draw(canvas, _Sprite.backdrop, const Offset(70, 123), 65);
    _draw(canvas, _Sprite.backdrop, const Offset(292, 123), 58, mirror: true);
    _draw(canvas, _Sprite.lighting, const Offset(39, 154), 103);
    _draw(canvas, _Sprite.stage, const Offset(167, 178), 170);
    _drawStageLights(canvas);
    _draw(canvas, _Sprite.speaker, const Offset(61, 170), 61);
    _draw(canvas, _Sprite.speaker, const Offset(267, 166), 55, mirror: true);
    _draw(
      canvas,
      signalQueued ? _Sprite.offer : _Sprite.vocal,
      const Offset(142, 145),
      66,
      frame: tick % 4,
    );
    _draw(
      canvas,
      _Sprite.musician,
      const Offset(193, 140),
      60,
      frame: tick % 4,
    );
    _draw(canvas, _Sprite.truck, const Offset(295, 242), 88);

    final wave = waveFrame;
    if (wave != null) {
      canvas.save();
      if (!waveTowardBack) {
        canvas.translate(0, _y(164) + _y(299));
        canvas.scale(1, -1);
      }
      _draw(canvas, _Sprite.wave, const Offset(168, 299), 129, frame: wave);
      canvas.restore();
    }

    _crowd(
      canvas,
      front,
      const [
        Offset(101, 210),
        Offset(141, 203),
        Offset(183, 203),
        Offset(122, 230),
        Offset(166, 230),
        Offset(205, 225),
      ],
      53,
      frontRow: true,
      zoneColor: const Color(0xFF7CE0C2),
    );
    _draw(
      canvas,
      _Sprite.vendor,
      const Offset(292, 262),
      64,
      frame: front == CrowdStatus.singing && back == CrowdStatus.singing
          ? tick % 4
          : 0,
    );
    _draw(canvas, _Sprite.generator, const Offset(310, 298), 46);
    if (generatorRunning) {
      _draw(
        canvas,
        _Sprite.rumble,
        const Offset(310, 289),
        31,
        frame: tick % 4,
      );
    }
    _crowd(
      canvas,
      back,
      const [
        Offset(93, 276),
        Offset(145, 272),
        Offset(191, 269),
        Offset(111, 307),
        Offset(160, 307),
        Offset(213, 302),
      ],
      58,
      frontRow: false,
      zoneColor: const Color(0xFFFFC46A),
    );
    final focusPercent = focusedVolume == null ? '' : ' $focusedVolume%';
    final choose = canSelectAudience ? ' ›' : '';
    _drawReadyPulse(canvas);
    _zoneLabel(
      canvas,
      '앞줄 ${_zoneMark(frontCue, front)}${frontFocused ? focusPercent : choose}',
      _zoneColor(
        frontCue,
        frontFocused ? front.color : const Color(0xFF7CE0C2),
      ),
      const Offset(15, 189),
      focused: frontFocused || frontCue != MixCue.none,
      statusColor: front.color,
    );
    _zoneLabel(
      canvas,
      '뒷줄 ${_zoneMark(backCue, back)}${backFocused ? focusPercent : choose}',
      _zoneColor(backCue, backFocused ? back.color : const Color(0xFFFFC46A)),
      const Offset(15, 253),
      focused: backFocused || backCue != MixCue.none,
      statusColor: back.color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FestivalPainter oldDelegate) =>
      tick != oldDelegate.tick ||
      front != oldDelegate.front ||
      back != oldDelegate.back ||
      signalQueued != oldDelegate.signalQueued ||
      generatorRunning != oldDelegate.generatorRunning ||
      waveFrame != oldDelegate.waveFrame ||
      waveTowardBack != oldDelegate.waveTowardBack ||
      focusedZone != oldDelegate.focusedZone ||
      focusedVolume != oldDelegate.focusedVolume ||
      canSelectAudience != oldDelegate.canSelectAudience ||
      lightingTier != oldDelegate.lightingTier ||
      frontCue != oldDelegate.frontCue ||
      backCue != oldDelegate.backCue ||
      readyZones != oldDelegate.readyZones ||
      pulseProgress != oldDelegate.pulseProgress ||
      venue != oldDelegate.venue ||
      compact != oldDelegate.compact ||
      images.length != oldDelegate.images.length;
}
