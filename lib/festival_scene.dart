import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'performance_controls.dart';

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
  });

  final int tick;
  final CrowdStatus front;
  final CrowdStatus back;
  final bool generatorRunning;
  final bool signalQueued;
  final int? waveFrame;
  final bool waveTowardBack;
  final bool compact;

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
        '동네 축제. 앞줄 ${widget.front.label}, '
        '뒷줄 ${widget.back.label}. '
        '발전기 ${widget.generatorRunning ? '작동 중' : '정지'}.';
    return Semantics(
      label: description,
      image: true,
      child: AspectRatio(
        aspectRatio: 360 / (widget.compact ? 265 : 324),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _failed
              ? const Center(child: Text('공연 장면을 불러오지 못했어요.'))
              : CustomPaint(
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
                  ),
                ),
        ),
      ),
    );
  }
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

  final _nearest = Paint()..filterQuality = FilterQuality.none;

  double _y(double y) {
    if (!compact) return y;
    if (y <= 178) return y * (135 / 178);
    return 135 + (y - 178) * (130 / 146);
  }

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

  void _zoneLabel(Canvas canvas, String label, Color color, Offset offset) {
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
        ..color = color
        ..style = PaintingStyle.stroke,
    );
    text.paint(canvas, offset + const Offset(7, 4));
    text.dispose();
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
          const [Color(0xFF3D2F53), Color(0xFF211E34)],
        ),
    );
    _draw(canvas, _Sprite.ground, const Offset(176, 327), 149);
    _draw(canvas, _Sprite.backdrop, const Offset(70, 123), 65);
    _draw(canvas, _Sprite.backdrop, const Offset(292, 123), 58, mirror: true);
    _draw(canvas, _Sprite.lighting, const Offset(39, 154), 103);
    _draw(canvas, _Sprite.stage, const Offset(167, 178), 170);
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
    _zoneLabel(
      canvas,
      '앞줄 ${front.symbol}',
      const Color(0xFF7CE0C2),
      const Offset(15, 189),
    );
    _zoneLabel(
      canvas,
      '뒷줄 ${back.symbol}',
      const Color(0xFFFFC46A),
      const Offset(15, 253),
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
      compact != oldDelegate.compact ||
      images.length != oldDelegate.images.length;
}
