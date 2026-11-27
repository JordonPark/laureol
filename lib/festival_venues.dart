enum FestivalZone { front, back }

enum TourRegion {
  alley('골목과 광장', '골목 웨이브', 0xFFF0AD78, 0xFFD2A3A0, '잔향', '생활 소음'),
  coast('항구와 해안', '조수 리듬', 0xFF80D9DC, 0xFF9FCDD5, '파도 반사', '바닷바람'),
  forest('숲과 캠핑', '솔숲 모닥불', 0xFF9DDB98, 0xFFA4C5B5, '숲길 울림', '나뭇잎 소리'),
  metro('도심의 밤', '심야 환승', 0xFFD7A3FF, 0xFFB0ABDF, '유리벽 반사', '도심 소음'),
  hall('실내 라이브', '벽면의 박자', 0xFFEF9AAD, 0xFFBC96CC, '벽면 저음 반사', '스피커 감쇠'),
  festival('야시장과 축제', '등불 행렬', 0xFFFFAA80, 0xFFDEA5BB, '난장 잔향', '노점 소음'),
  river('강변과 공원', '강 위의 불빛', 0xFF91CDEB, 0xFF8EBDC6, '수면 반사', '강바람'),
  winter('겨울과 산길', '눈꽃 카운트', 0xFFB8DFFF, 0xFFB0BCE9, '눈벽 반사', '찬바람');

  const TourRegion(
    this.title,
    this.track,
    this.accent,
    this.ground,
    this.boost,
    this.cut,
  );

  final String title;
  final String track;
  final int accent;
  final int ground;
  final String boost;
  final String cut;

  String get backdrop => 'docs/art/festival/tour-$name.png';

  Iterable<FestivalVenue> get venues =>
      FestivalVenue.tourVenues.where((venue) => venue.region == this);
}

enum TourStage { canopy, deck, studio, theatre, rig, arena }

enum TourGoal {
  together(target: 8),
  points(target: 65),
  combo(target: 24),
  everyChorus(target: 5),
  finale(target: 12),
  headliner(target: 70);

  const TourGoal({required this.target});
  final int target;

  String get description => switch (this) {
    together => '두 줄이 한 후렴에서 $target박 연속 떼창',
    points => '공연에서 $target점 달성',
    combo => '최고 콤보 $target회 달성',
    everyChorus => '세 후렴에서 두 줄이 각각 $target박 이상 떼창',
    finale => '마지막 후렴에서 두 줄이 함께 $target박 떼창',
    headliner => '공연 $target점과 최고 콤보 20회 달성',
  };
}

class FestivalMixChange {
  const FestivalMixChange(
    this.label,
    this.zone,
    this.start,
    this.end,
    this.gain,
  );

  final String label;
  final FestivalZone zone;
  final int start;
  final int end;
  final int gain;

  bool activeAt(int second) => second >= start && second < end;
}

class FestivalVenue {
  const FestivalVenue._original(
    this.name,
    this.title,
    this._originalMission,
    this._poster,
    this._music,
    this.accent,
  ) : region = null,
      stage = null,
      description = null,
      slot = 0,
      chart = 0;

  const FestivalVenue.tour(
    this.name,
    this.title,
    TourRegion this.region,
    TourStage this.stage,
    String this.description,
    this.accent,
    this.slot,
    this.chart,
  ) : _originalMission = null,
      _poster = null,
      _music = null;

  final String name;
  final String title;
  final String? _originalMission;
  final String? _poster;
  final String? _music;
  final TourRegion? region;
  final TourStage? stage;
  final String? description;
  final int accent;
  final int slot;
  final int chart;

  static const neighborhood = FestivalVenue._original(
    'neighborhood',
    '동네 축제',
    '두 줄이 8박 연속 떼창하기',
    'venue-neighborhood.png',
    'festival-first-show.wav',
    0xFFFFC46A,
  );
  static const nightMarket = FestivalVenue._original(
    'nightMarket',
    '야외 야시장',
    '발전기가 꺼진 뒤 4박 안에 두 줄 합류시키기',
    'venue-market.png',
    'night-market-step.wav',
    0xFF7CE0C2,
  );
  static const liveClub = FestivalVenue._original(
    'liveClub',
    '지하 라이브클럽',
    '마지막 후렴에서 두 줄이 함께 12박 떼창하기',
    'venue-club.png',
    'neon-break.wav',
    0xFFF1A6F3,
  );
  static const rooftop = FestivalVenue._original(
    'rooftop',
    '옥상 공연',
    '세 후렴 모두에서 두 줄이 함께 떼창하기',
    'venue-rooftop.png',
    'rooftop-encore.wav',
    0xFF8FCDFF,
  );

  static const originals = [neighborhood, nightMarket, liveClub, rooftop];
  static const tourVenues = _tourVenues;
  static const values = [...originals, ...tourVenues];

  bool get usesGenerator => this == neighborhood || this == nightMarket;
  String get mission => _originalMission ?? tourGoal.description;
  String get posterAsset => region?.backdrop ?? 'docs/art/festival/$_poster';
  String get musicAsset => _music ?? 'map/$name.mp3';
  TourGoal get tourGoal => TourGoal.values[slot];

  FestivalVenue? get next {
    final nextIndex = values.indexOf(this) + 1;
    if (nextIndex == 0 || nextIndex >= values.length) return null;
    final candidate = values[nextIndex];
    return candidate.region == region ? candidate : null;
  }

  String? get unlockHint => switch (this) {
    nightMarket => '동네 축제에서 두 줄 8박 연속 떼창으로 해금',
    liveClub => '야외 야시장 완주로 해금',
    rooftop => '지하 라이브클럽 완주로 해금',
    _ => null,
  };

  // Each chart assigns a different order, gain, and entry beat to the same
  // three chorus checkpoints used by local replay records.
  List<FestivalMixChange> buildMixChanges() {
    final area = region;
    if (area == null) return const [];
    final first = chart % 2 == 0 ? FestivalZone.front : FestivalZone.back;
    final other = first == FestivalZone.front
        ? FestivalZone.back
        : FestivalZone.front;
    final opening = 23 + (chart ~/ 2 % 5);
    final middle = 48 + (chart ~/ 5 % 5);
    final finalStart = 76 + (chart + chart ~/ 6) % 6;
    final openingGain = 10 + 2 * (chart ~/ 3 % 4);
    final middleGain = 10 + 2 * (chart ~/ 6 % 4);
    final finalGain = 12 + 2 * (chart ~/ 4 % 4);

    FestivalMixChange event(FestivalZone zone, int start, int end, int gain) {
      final row = zone == FestivalZone.front ? '앞줄' : '뒷줄';
      return FestivalMixChange(
        '$row ${gain > 0 ? area.boost : area.cut}',
        zone,
        start,
        end,
        gain,
      );
    }

    return [
      event(
        first,
        opening,
        opening + 5,
        chart % 3 == 0 ? -openingGain : openingGain,
      ),
      event(
        other,
        middle,
        middle + 6 + chart % 3,
        chart % 4 < 2 ? middleGain : -middleGain,
      ),
      event(
        chart % 5 < 2 ? other : first,
        finalStart,
        slot >= 4 ? 85 : finalStart + 5,
        chart % 3 == 1 ? finalGain : -finalGain,
      ),
      if (slot >= 4)
        event(chart % 5 < 2 ? first : other, 85, 89, chart % 3 == 1 ? -12 : 12),
    ];
  }

  FestivalZone preferredTourLead(int chorus) =>
      (chart >> (chorus - 1)) & 1 == 0 ? FestivalZone.front : FestivalZone.back;
}

const _tourVenues = [
  FestivalVenue.tour(
    'post-office',
    '우체국 앞 작은광장',
    TourRegion.alley,
    TourStage.canopy,
    '가로등 아래 합주',
    0xFFF7BB75,
    0,
    0,
  ),
  FestivalVenue.tour(
    'ginkgo',
    '은행나무 삼거리',
    TourRegion.alley,
    TourStage.deck,
    '노란 잎 골목',
    0xFFE8D686,
    1,
    1,
  ),
  FestivalVenue.tour(
    'book-lane',
    '헌책방 골목',
    TourRegion.alley,
    TourStage.studio,
    '낮은 벽의 울림',
    0xFFD2A6DD,
    2,
    2,
  ),
  FestivalVenue.tour(
    'retro-arcade',
    '오락실 지하광장',
    TourRegion.alley,
    TourStage.theatre,
    '아케이드 저음',
    0xFFF68A9A,
    3,
    3,
  ),
  FestivalVenue.tour(
    'tile-courtyard',
    '기와마당',
    TourRegion.alley,
    TourStage.rig,
    '돌담 사이 메아리',
    0xFF8ED5C0,
    4,
    4,
  ),
  FestivalVenue.tour(
    'station-square',
    '옛 역전광장',
    TourRegion.alley,
    TourStage.arena,
    '거리의 마지막 후렴',
    0xFFED9D70,
    5,
    5,
  ),

  FestivalVenue.tour(
    'lighthouse',
    '등대 앞 데크',
    TourRegion.coast,
    TourStage.deck,
    '등대 바람길',
    0xFF78E1E1,
    0,
    6,
  ),
  FestivalVenue.tour(
    'fishing-pier',
    '낚시 부두',
    TourRegion.coast,
    TourStage.rig,
    '선착장 울림',
    0xFF8DC8EF,
    1,
    7,
  ),
  FestivalVenue.tour(
    'sea-wall',
    '해안 방파제',
    TourRegion.coast,
    TourStage.arena,
    '물보라 바람',
    0xFF729FD8,
    2,
    8,
  ),
  FestivalVenue.tour(
    'fish-market',
    '어시장 옆 쉼터',
    TourRegion.coast,
    TourStage.canopy,
    '어항 소음',
    0xFFFFB28C,
    3,
    9,
  ),
  FestivalVenue.tour(
    'tide-dock',
    '썰물 선착장',
    TourRegion.coast,
    TourStage.studio,
    '데크 진동',
    0xFFA8E0B4,
    4,
    10,
  ),
  FestivalVenue.tour(
    'sunset-beach',
    '노을 해변무대',
    TourRegion.coast,
    TourStage.theatre,
    '파도가 가까운 객석',
    0xFFF5A9BD,
    5,
    11,
  ),

  FestivalVenue.tour(
    'pine-camp',
    '솔숲 야영장',
    TourRegion.forest,
    TourStage.canopy,
    '솔숲 스피커',
    0xFFA6D98E,
    0,
    12,
  ),
  FestivalVenue.tour(
    'rest-deck',
    '산책로 쉼터',
    TourRegion.forest,
    TourStage.deck,
    '도랑 쪽 바람',
    0xFFE9CC8C,
    1,
    13,
  ),
  FestivalVenue.tour(
    'valley-table',
    '계곡 나무마당',
    TourRegion.forest,
    TourStage.studio,
    '물소리 믹스',
    0xFF91D5E8,
    2,
    14,
  ),
  FestivalVenue.tour(
    'firefly-bank',
    '반딧불 둔덕',
    TourRegion.forest,
    TourStage.rig,
    '둔덕 위 잔향',
    0xFF94DAB4,
    3,
    15,
  ),
  FestivalVenue.tour(
    'wood-hall',
    '숲속 목조홀',
    TourRegion.forest,
    TourStage.theatre,
    '목조 벽면 반사',
    0xFFF7A472,
    4,
    16,
  ),
  FestivalVenue.tour(
    'forest-stage',
    '숲길 끝 열린무대',
    TourRegion.forest,
    TourStage.arena,
    '숲 속 응답',
    0xFFD7E58F,
    5,
    17,
  ),

  FestivalVenue.tour(
    'underpass',
    '고가 밑 네온마당',
    TourRegion.metro,
    TourStage.rig,
    '고가 아래 저음',
    0xFFDF9BFF,
    0,
    18,
  ),
  FestivalVenue.tour(
    'glass-tower',
    '유리빌딩 테라스',
    TourRegion.metro,
    TourStage.deck,
    '유리 외벽 반사',
    0xFFA5BDFF,
    1,
    19,
  ),
  FestivalVenue.tour(
    'station-steps',
    '환승역 계단무대',
    TourRegion.metro,
    TourStage.arena,
    '정차 소음',
    0xFF68D7D9,
    2,
    20,
  ),
  FestivalVenue.tour(
    'neon-laundry',
    '네온 세탁소 앞',
    TourRegion.metro,
    TourStage.studio,
    '간판 골목 울림',
    0xFFFAA1CB,
    3,
    21,
  ),
  FestivalVenue.tour(
    'parking-top',
    '주차타워 맨 위',
    TourRegion.metro,
    TourStage.canopy,
    '옥상 돌풍',
    0xFFD1D183,
    4,
    22,
  ),
  FestivalVenue.tour(
    'last-train',
    '막차 플랫폼',
    TourRegion.metro,
    TourStage.theatre,
    '막차 떠난 뒤',
    0xFF9AA7F0,
    5,
    23,
  ),

  FestivalVenue.tour(
    'brick-club',
    '붉은 벽돌 클럽',
    TourRegion.hall,
    TourStage.theatre,
    '벽돌 반향',
    0xFFF698AE,
    0,
    24,
  ),
  FestivalVenue.tour(
    'factory',
    '빈 공장 라이브홀',
    TourRegion.hall,
    TourStage.rig,
    '철제 보 잔향',
    0xFFC6A6EE,
    1,
    25,
  ),
  FestivalVenue.tour(
    'cinema',
    '구극장 앞무대',
    TourRegion.hall,
    TourStage.studio,
    '커튼 앞 음향',
    0xFFF8C987,
    2,
    26,
  ),
  FestivalVenue.tour(
    'record-store',
    '레코드숍 스튜디오',
    TourRegion.hall,
    TourStage.deck,
    '좁은 객석 저음',
    0xFF91DCC7,
    3,
    27,
  ),
  FestivalVenue.tour(
    'rehearsal-hall',
    '합주실 메인홀',
    TourRegion.hall,
    TourStage.canopy,
    '모니터 교대',
    0xFFB6BAFF,
    4,
    28,
  ),
  FestivalVenue.tour(
    'warehouse',
    '창고 피날레홀',
    TourRegion.hall,
    TourStage.arena,
    '천장 저음 반사',
    0xFFF0B2DA,
    5,
    29,
  ),

  FestivalVenue.tour(
    'lantern-row',
    '등불 거리',
    TourRegion.festival,
    TourStage.canopy,
    '줄지은 등불',
    0xFFFFBD8A,
    0,
    30,
  ),
  FestivalVenue.tour(
    'food-court',
    '푸드코트 광장',
    TourRegion.festival,
    TourStage.arena,
    '조리 소음',
    0xFFF89CA2,
    1,
    31,
  ),
  FestivalVenue.tour(
    'carousel',
    '회전목마 앞',
    TourRegion.festival,
    TourStage.deck,
    '회전목마 사이 음향',
    0xFF94DAD1,
    2,
    32,
  ),
  FestivalVenue.tour(
    'street-float',
    '퍼레이드 수레무대',
    TourRegion.festival,
    TourStage.rig,
    '수레 옆 저음',
    0xFFDE9CF7,
    3,
    33,
  ),
  FestivalVenue.tour(
    'midway',
    '야간 놀이터',
    TourRegion.festival,
    TourStage.studio,
    '놀이기구 소리',
    0xFFF0D180,
    4,
    34,
  ),
  FestivalVenue.tour(
    'main-fair',
    '야간 축제 메인광장',
    TourRegion.festival,
    TourStage.theatre,
    '광장 전체 응답',
    0xFFFFAD91,
    5,
    35,
  ),

  FestivalVenue.tour(
    'reed-park',
    '갈대밭 입구',
    TourRegion.river,
    TourStage.deck,
    '갈대 사이 강바람',
    0xFF93DEC5,
    0,
    36,
  ),
  FestivalVenue.tour(
    'water-stairs',
    '수변 계단무대',
    TourRegion.river,
    TourStage.arena,
    '계단의 울림',
    0xFF95CDEB,
    1,
    37,
  ),
  FestivalVenue.tour(
    'bike-bridge',
    '자전거다리 아래',
    TourRegion.river,
    TourStage.rig,
    '교각 음향',
    0xFFC2AEF2,
    2,
    38,
  ),
  FestivalVenue.tour(
    'fountain-park',
    '분수 광장',
    TourRegion.river,
    TourStage.canopy,
    '분수 소리',
    0xFF8CE5E1,
    3,
    39,
  ),
  FestivalVenue.tour(
    'boat-stage',
    '유람선 갑판',
    TourRegion.river,
    TourStage.studio,
    '갑판 바람',
    0xFFF4B7A5,
    4,
    40,
  ),
  FestivalVenue.tour(
    'night-park',
    '달빛 잔디공원',
    TourRegion.river,
    TourStage.theatre,
    '넓은 잔디밭 합창',
    0xFF98D0EE,
    5,
    41,
  ),

  FestivalVenue.tour(
    'snow-square',
    '눈꽃 광장',
    TourRegion.winter,
    TourStage.canopy,
    '눈에 잠긴 객석',
    0xFFBADFF3,
    0,
    42,
  ),
  FestivalVenue.tour(
    'ski-lift',
    '리프트 대기장',
    TourRegion.winter,
    TourStage.rig,
    '산비탈 바람',
    0xFFA8C6FD,
    1,
    43,
  ),
  FestivalVenue.tour(
    'cabin',
    '산장 벽난로홀',
    TourRegion.winter,
    TourStage.theatre,
    '목재 벽면 울림',
    0xFFF4B8A8,
    2,
    44,
  ),
  FestivalVenue.tour(
    'frozen-lake',
    '얼음호수 전망대',
    TourRegion.winter,
    TourStage.deck,
    '얼음 위 바람',
    0xFF95D9ED,
    3,
    45,
  ),
  FestivalVenue.tour(
    'pass-station',
    '고갯길 정류장',
    TourRegion.winter,
    TourStage.studio,
    '고갯길 돌풍',
    0xFFBEC1F4,
    4,
    46,
  ),
  FestivalVenue.tour(
    'summit',
    '정상 별빛무대',
    TourRegion.winter,
    TourStage.arena,
    '높은 곳의 앙코르',
    0xFFD4DFFC,
    5,
    47,
  ),
];
