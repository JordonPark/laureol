import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'festival_venues.dart';

enum StageSet {
  alley(TourRegion.alley, '골목과 광장', ['기와 정자', '벽돌 계단', '달문 정자', '골목 차양']),
  coast(TourRegion.coast, '항구와 해안', ['목재 부두', '파란 보트 창고', '컨테이너', '돛 그늘막']),
  forest(TourRegion.forest, '숲과 캠핑', ['통나무 오두막', '반원 데크', '삼각 보 구조', '숲속 천막']),
  metro(TourRegion.metro, '도심의 밤', ['네온 포털', '톱니 지붕', '도심 트러스', '지하철 캐노피']),
  hall(TourRegion.hall, '실내 라이브', ['붉은 커튼', '호두나무 스튜디오', '곡면 흡음벽', '공장 라이브홀']),
  festival(TourRegion.festival, '야시장과 축제', ['물결 천막', '쌍등탑', '붉은 누각', '팔각 광장']),
  river(TourRegion.river, '강변과 공원', [
    '강가 녹색 정자',
    '수변 산책로',
    '돌 계단 극장',
    '흰 곡선 지붕',
  ]),
  winter(TourRegion.winter, '겨울과 산길', [
    '눈 덮인 산장',
    '얼음 기둥',
    '겨울 원형 정자',
    '설원 트러스',
  ]),
  workshop(TourRegion.hall, '개조 공연장', [
    '옛 전차 차고',
    '노출 콘크리트 갤러리',
    '라디오 스튜디오',
    '검은 소극장',
  ]),
  landmark(TourRegion.alley, '랜드마크', [
    '고가 아래 아치',
    '언덕 전망대',
    '돌담 안마당',
    '바람 언덕 차양',
  ]);

  const StageSet(this.backdrop, this.title, this.structures);

  final TourRegion backdrop;
  final String title;
  final List<String> structures;

  String get asset => 'assets/stage-catalog/$name.png';

  Iterable<ConcertStageArt> get stages sync* {
    for (final (structure, _) in structures.indexed) {
      for (final setup in StageSetup.values) {
        yield ConcertStageArt(this, structure, setup);
      }
    }
  }
}

enum StageSetup {
  original('기본'),
  liveRig('라이브 리그'),
  neon('네온'),
  lanterns('등불'),
  finale('피날레');

  const StageSetup(this.title);

  final String title;
}

class ConcertStageArt {
  const ConcertStageArt(this.set, this.structure, this.setup);

  static const tile = Size(360, 180);

  final StageSet set;
  final int structure;
  final StageSetup setup;

  String get title => '${set.structures[structure]} · ${setup.title}';
  String get id => '${set.name}-${structure + 1}-${setup.name}';

  Rect get source => Rect.fromLTWH(
    tile.width * structure,
    tile.height * setup.index,
    tile.width,
    tile.height,
  );

  static ConcertStageArt? forVenue(FestivalVenue venue) {
    final region = venue.region;
    if (region == null) return null;
    final (structure, setup) = _venueArtwork[region.index][venue.slot];
    return ConcertStageArt(StageSet.values[region.index], structure, setup);
  }
}

// Each row follows the existing six places in its tour region.
const _venueArtwork = [
  [
    (1, StageSetup.original),
    (3, StageSetup.lanterns),
    (2, StageSetup.lanterns),
    (3, StageSetup.neon),
    (0, StageSetup.original),
    (1, StageSetup.finale),
  ],
  [
    (0, StageSetup.original),
    (1, StageSetup.liveRig),
    (3, StageSetup.original),
    (2, StageSetup.lanterns),
    (0, StageSetup.lanterns),
    (3, StageSetup.finale),
  ],
  [
    (1, StageSetup.lanterns),
    (0, StageSetup.original),
    (2, StageSetup.original),
    (3, StageSetup.lanterns),
    (1, StageSetup.original),
    (2, StageSetup.finale),
  ],
  [
    (0, StageSetup.neon),
    (2, StageSetup.liveRig),
    (3, StageSetup.original),
    (1, StageSetup.neon),
    (2, StageSetup.neon),
    (1, StageSetup.finale),
  ],
  [
    (0, StageSetup.original),
    (1, StageSetup.original),
    (2, StageSetup.neon),
    (3, StageSetup.liveRig),
    (1, StageSetup.lanterns),
    (0, StageSetup.finale),
  ],
  [
    (0, StageSetup.lanterns),
    (1, StageSetup.lanterns),
    (2, StageSetup.original),
    (3, StageSetup.liveRig),
    (0, StageSetup.neon),
    (3, StageSetup.finale),
  ],
  [
    (1, StageSetup.original),
    (0, StageSetup.lanterns),
    (2, StageSetup.original),
    (3, StageSetup.lanterns),
    (2, StageSetup.neon),
    (3, StageSetup.finale),
  ],
  [
    (0, StageSetup.original),
    (1, StageSetup.neon),
    (2, StageSetup.lanterns),
    (3, StageSetup.liveRig),
    (0, StageSetup.lanterns),
    (1, StageSetup.finale),
  ],
];

Future<ui.Image> decodeStageAtlas(StageSet set) async {
  final bytes = await rootBundle.load(set.asset);
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

class ConcertStagePreview extends StatelessWidget {
  const ConcertStagePreview(this.art, {super.key});

  final ConcertStageArt art;

  @override
  Widget build(BuildContext context) => FittedBox(
    child: SizedBox(
      width: ConcertStageArt.tile.width,
      height: ConcertStageArt.tile.height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(
            2 * art.structure / (art.set.structures.length - 1) - 1,
            2 * art.setup.index / (StageSetup.values.length - 1) - 1,
          ),
          minWidth: ConcertStageArt.tile.width * art.set.structures.length,
          maxWidth: ConcertStageArt.tile.width * art.set.structures.length,
          minHeight: ConcertStageArt.tile.height * StageSetup.values.length,
          maxHeight: ConcertStageArt.tile.height * StageSetup.values.length,
          child: Image.asset(
            art.set.asset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
