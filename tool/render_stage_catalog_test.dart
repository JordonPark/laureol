import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/concert_stage_art.dart';

const _sourceFolder = 'docs/art/stage-sources';
const _exportFolder = 'build/stage-catalog';
final _paint = ui.Paint()..filterQuality = ui.FilterQuality.none;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Render the bundled stage sheets and individual transparent PNGs',
    () async {
      final export = await Directory(_exportFolder).create(recursive: true);
      await Directory('assets/stage-catalog').create(recursive: true);
      final sourceRects = jsonDecode(
        await File('$_sourceFolder/crops.json').readAsString(),
      ) as Map<String, dynamic>;
      final sources = <String, _Atlas>{};
      final entries = <Map<String, String>>[];
      try {
        for (final entry in sourceRects.entries) {
          sources[entry.key] = await _Atlas.load(
            entry.key,
            entry.value as List,
          );
        }
        for (final set in StageSet.values) {
          final sheet = ui.PictureRecorder();
          final canvas = ui.Canvas(sheet);
          for (final art in set.stages) {
            final tile = ui.PictureRecorder();
            _compose(ui.Canvas(tile), art, sources);
            final picture = tile.endRecording();
            try {
              canvas.save();
              canvas.translate(art.source.left, art.source.top);
              canvas.drawPicture(picture);
              canvas.restore();
              final fullSize = ui.PictureRecorder();
              ui.Canvas(fullSize)
                ..scale(2)
                ..drawPicture(picture);
              await _writePicture(
                fullSize.endRecording(),
                '${export.path}/${art.id}.png',
                ConcertStageArt.tile * 2,
              );
            } finally {
              picture.dispose();
            }
            entries.add({
              'file': '${art.id}.png',
              'region': set.title,
              'title': art.title,
            });
          }
          final imageSize = ui.Size(
            ConcertStageArt.tile.width * set.structures.length,
            ConcertStageArt.tile.height * StageSetup.values.length,
          );
          await _writePicture(sheet.endRecording(), set.asset, imageSize);
        }
        await File('${export.path}/manifest.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(entries));
        expect(entries, hasLength(200));
      } finally {
        for (final atlas in sources.values) {
          atlas.image.dispose();
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

class _Atlas {
  _Atlas(this.image, this.crops);

  final ui.Image image;
  final List<ui.Rect> crops;

  static Future<_Atlas> load(String name, List<dynamic> cells) async {
    final codec = await ui.instantiateImageCodec(
      await File('$_sourceFolder/$name.png').readAsBytes(),
    );
    try {
      final image = (await codec.getNextFrame()).image;
      final crops = [
        for (final item in cells)
          ui.Rect.fromLTRB(
            item[0].toDouble(),
            item[1].toDouble(),
            item[2].toDouble(),
            item[3].toDouble(),
          ),
      ];
      return _Atlas(image, crops);
    } finally {
      codec.dispose();
    }
  }

  void draw(
    ui.Canvas canvas,
    int index,
    double x,
    double y,
    double maxWidth,
    double maxHeight, {
    bool mirror = false,
  }) {
    final source = crops[index];
    final scale = math.min(maxHeight / source.height, maxWidth / source.width);
    final width = (source.width * scale).roundToDouble();
    final height = (source.height * scale).roundToDouble();
    canvas.save();
    canvas.translate(x, y);
    if (mirror) canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      source,
      ui.Rect.fromLTWH((-width / 2).floorToDouble(), -height, width, height),
      _paint,
    );
    canvas.restore();
  }
}

void _compose(
  ui.Canvas canvas,
  ConcertStageArt art,
  Map<String, _Atlas> sources,
) {
  final base = sources[art.set.name]!;
  final frames = sources['rig']!;
  final wings = sources['wing']!;
  final banners = sources['banner']!;
  final scenic = sources['scenic']!;
  final variant = (art.set.index + art.structure) % 4;
  const center = 172.0;

  switch (art.setup) {
    case StageSetup.original:
      break;
    case StageSetup.liveRig:
      frames.draw(canvas, 0, center, 167, 316, 153);
      wings.draw(canvas, 1, 27, 172, 48, 46);
      wings.draw(canvas, 3, 321, 169, 42, 59, mirror: true);
    case StageSetup.neon:
      frames.draw(canvas, 1 + variant % 2, center, 168, 302, 153);
      scenic.draw(canvas, 3, 30, 174, 48, 88);
      scenic.draw(canvas, 3, 319, 172, 46, 84, mirror: true);
    case StageSetup.lanterns:
      frames.draw(canvas, 3, center, 168, 310, 145);
      wings.draw(canvas, 2, 28, 174, 48, 85);
      wings.draw(canvas, 0, 322, 171, 55, 63, mirror: true);
    case StageSetup.finale:
      frames.draw(canvas, variant, center, 170, 330, 162);
      scenic.draw(canvas, variant, 28, 174, 52, 95);
      scenic.draw(canvas, variant, 320, 172, 50, 90, mirror: true);
  }

  base.draw(canvas, art.structure, center, 178, 247, 168);

  switch (art.setup) {
    case StageSetup.original:
      break;
    case StageSetup.liveRig:
      banners.draw(canvas, 2, center, 161, 150, 10);
    case StageSetup.neon:
      banners.draw(canvas, 3, center, 168, 177, 10);
    case StageSetup.lanterns:
      banners.draw(canvas, variant % 2, center, 64, 191, 28);
    case StageSetup.finale:
      banners.draw(canvas, variant % 2, center, 58, 206, 31);
      banners.draw(canvas, 3, center, 169, 193, 13);
  }
}

Future<void> _writePicture(
  ui.Picture picture,
  String path,
  ui.Size size,
) async {
  try {
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
