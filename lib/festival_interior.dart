part of 'festival_scene.dart';

TourRegion _interiorRegion(FestivalVenue venue) =>
    venue.region ??
    switch (venue) {
      FestivalVenue.nightMarket => TourRegion.festival,
      FestivalVenue.liveClub => TourRegion.hall,
      FestivalVenue.rooftop => TourRegion.metro,
      _ => TourRegion.alley,
    };

class _InteriorProp {
  const _InteriorProp(this.sprite, this.base, this.height, this.widthLimit);

  final int sprite;
  final Offset base;
  final double height;
  final double widthLimit;
}

typedef _InteriorLayout = ({
  List<_InteriorProp> wings,
  List<_InteriorProp> floor,
});

// Tight, normalized bounds in top-left, top-right, bottom-left, bottom-right order.
const _interiorCrops = <TourRegion, List<Rect>>{
  TourRegion.alley: [
    Rect.fromLTRB(.08453, .02711, .39793, .46411),
    Rect.fromLTRB(.57018, .02313, .96172, .4673),
    Rect.fromLTRB(.02791, .68102, .47289, .92504),
    Rect.fromLTRB(.55901, .58373, .96172, .94976),
  ],
  TourRegion.coast: [
    Rect.fromLTRB(.14833, .00797, .31978, .47608),
    Rect.fromLTRB(.55502, .11005, .95774, .42424),
    Rect.fromLTRB(.04147, .66587, .42743, .89234),
    Rect.fromLTRB(.62041, .53828, .91148, .97687),
  ],
  TourRegion.festival: [
    Rect.fromLTRB(.11085, .01834, .38517, .47687),
    Rect.fromLTRB(.57576, .06778, .95136, .45136),
    Rect.fromLTRB(.04226, .62839, .4378, .92823),
    Rect.fromLTRB(.54067, .64514, .95694, .91547),
  ],
  TourRegion.forest: [
    Rect.fromLTRB(.10925, .03748, .38596, .48565),
    Rect.fromLTRB(.60766, .03349, .89155, .48884),
    Rect.fromLTRB(.03589, .60367, .44976, .95614),
    Rect.fromLTRB(.53349, .61962, .95694, .9362),
  ],
  TourRegion.hall: [
    Rect.fromLTRB(.1252, .02233, .37081, .47927),
    Rect.fromLTRB(.65152, .06061, .86762, .45853),
    Rect.fromLTRB(.0638, .65231, .44099, .9067),
    Rect.fromLTRB(.55104, .61882, .94817, .89713),
  ],
  TourRegion.metro: [
    Rect.fromLTRB(.16587, .03668, .3134, .47129),
    Rect.fromLTRB(.53589, .11563, .97608, .43301),
    Rect.fromLTRB(.02871, .61643, .47209, .91946),
    Rect.fromLTRB(.57257, .55821, .92584, .95056),
  ],
  TourRegion.river: [
    Rect.fromLTRB(.14115, .02632, .37321, .45774),
    Rect.fromLTRB(.53429, .16188, .9689, .44179),
    Rect.fromLTRB(.13317, .55742, .37002, .96411),
    Rect.fromLTRB(.51834, .65072, .96411, .94338),
  ],
  TourRegion.winter: [
    Rect.fromLTRB(.07576, .05183, .43222, .47049),
    Rect.fromLTRB(.6563, .04147, .84609, .48246),
    Rect.fromLTRB(.04226, .62281, .45215, .9378),
    Rect.fromLTRB(.54306, .626, .96651, .93939),
  ],
};

const _originalOutdoorInterior = (
  wings: [
    _InteriorProp(0, Offset(26, 170), 69, 52),
    _InteriorProp(1, Offset(320, 161), 55, 63),
  ],
  floor: [_InteriorProp(3, Offset(38, 305), 36, 65)],
);

const _originalClubInterior = (
  wings: [
    _InteriorProp(0, Offset(37, 167), 90, 59),
    _InteriorProp(1, Offset(320, 173), 72, 58),
  ],
  floor: [
    _InteriorProp(2, Offset(301, 215), 38, 65),
    _InteriorProp(3, Offset(309, 273), 46, 86),
  ],
);

const _interiorLayouts = <_InteriorLayout>[
  (
    wings: [
      _InteriorProp(0, Offset(41, 170), 72, 56),
      _InteriorProp(1, Offset(312, 176), 61, 69),
    ],
    floor: [
      _InteriorProp(2, Offset(323, 227), 51, 70),
      _InteriorProp(3, Offset(303, 289), 58, 75),
    ],
  ),
  (
    wings: [
      _InteriorProp(1, Offset(38, 178), 62, 62),
      _InteriorProp(0, Offset(320, 160), 73, 64),
    ],
    floor: [
      _InteriorProp(3, Offset(285, 217), 54, 60),
      _InteriorProp(2, Offset(323, 276), 55, 71),
    ],
  ),
  (
    wings: [
      _InteriorProp(0, Offset(318, 160), 88, 59),
      _InteriorProp(1, Offset(42, 161), 82, 68),
    ],
    floor: [
      _InteriorProp(2, Offset(281, 215), 53, 65),
      _InteriorProp(3, Offset(319, 295), 55, 75),
    ],
  ),
  (
    wings: [
      _InteriorProp(0, Offset(33, 163), 82, 58),
      _InteriorProp(1, Offset(316, 166), 71, 63),
    ],
    floor: [
      _InteriorProp(3, Offset(307, 223), 57, 64),
      _InteriorProp(2, Offset(282, 299), 45, 70),
    ],
  ),
  (
    wings: [
      _InteriorProp(0, Offset(315, 179), 82, 62),
      _InteriorProp(1, Offset(43, 173), 72, 64),
    ],
    floor: [
      _InteriorProp(2, Offset(313, 238), 49, 70),
      _InteriorProp(3, Offset(42, 306), 53, 67),
    ],
  ),
  (
    wings: [
      _InteriorProp(0, Offset(24, 178), 73, 46),
      _InteriorProp(1, Offset(335, 173), 70, 46),
    ],
    floor: [
      _InteriorProp(2, Offset(297, 239), 53, 72),
      _InteriorProp(3, Offset(331, 300), 48, 52),
    ],
  ),
];

extension _VenueInteriorPainting on _FestivalPainter {
  void _drawInteriorProps(Canvas canvas, {required bool floor}) {
    final atlas = interior;
    if (atlas == null) return;
    final layout = switch (venue) {
      FestivalVenue.neighborhood ||
      FestivalVenue.nightMarket => _originalOutdoorInterior,
      FestivalVenue.liveClub => _originalClubInterior,
      FestivalVenue.rooftop => _interiorLayouts[1],
      _ => _interiorLayouts[venue.slot],
    };
    final crops = _interiorCrops[interiorRegion]!;
    final pieces = floor ? layout.floor : layout.wings;
    final shadow = Paint()..color = const Color(0x66151127);
    for (final prop in pieces) {
      final crop = crops[prop.sprite];
      final source = Rect.fromLTRB(
        crop.left * atlas.width,
        crop.top * atlas.height,
        crop.right * atlas.width,
        crop.bottom * atlas.height,
      );
      final maxHeight = compact && prop.base.dy <= 178
          ? prop.height * .77
          : prop.height;
      final aspect = source.width / source.height;
      final width = (maxHeight * aspect).clamp(0, prop.widthLimit).toDouble();
      final height = width / aspect;
      final y = _y(prop.base.dy);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(prop.base.dx + 2, y),
          width: width * .81,
          height: 4 + height * .11,
        ),
        shadow,
      );
      canvas.drawImageRect(
        atlas,
        source,
        Rect.fromLTWH(prop.base.dx - width / 2, y - height, width, height),
        _nearest,
      );
    }
  }

  void _drawInteriorFloor(Canvas canvas) {
    final region = interiorRegion;
    final paint = Paint()..color = Color(region.accent).withAlpha(90);
    switch (region) {
      case TourRegion.metro || TourRegion.hall:
        for (var stripe = 0; stripe < 7; stripe++) {
          final x = 265.0 + stripe * 10;
          final y = _y(257.0 + (stripe % 2) * 2);
          canvas.drawPath(
            Path()
              ..moveTo(x, y)
              ..lineTo(x + 7, y)
              ..lineTo(x + 3, y + 4)
              ..lineTo(x - 3, y + 4)
              ..close(),
            paint,
          );
        }
      case TourRegion.coast || TourRegion.river:
        for (var board = 0; board < 5; board++) {
          final top = _y(220.0 + board * 15);
          paint.color = Color(region.ground).withAlpha(board.isEven ? 62 : 34);
          final x = 318.0 - board * 5;
          canvas.drawRect(Rect.fromLTWH(x, top, 40, 3), paint);
        }
      case TourRegion.forest || TourRegion.winter:
        for (var group = 0; group < 6; group++) {
          final x = 258.0 + (group * 29) % 90;
          final y = _y(223.0 + group * 15);
          canvas.drawRect(Rect.fromLTWH(x, y, 5, 2), paint);
          canvas.drawRect(Rect.fromLTWH(x + 4, y + 2, 7, 2), paint);
          canvas.drawRect(Rect.fromLTWH(x - 2, y + 4, 4, 2), paint);
        }
      case TourRegion.alley || TourRegion.festival:
        paint.color = Color(region.accent).withAlpha(80);
        for (var tile = 0; tile < 6; tile++) {
          final x = 263.0 + (tile * 19) % 88;
          final y = _y(231.0 + tile * 11);
          canvas.drawRect(Rect.fromLTWH(x, y, 6, 3), paint);
          canvas.drawRect(Rect.fromLTWH(x + 4, y + 3, 3, 3), paint);
        }
    }
  }
}
