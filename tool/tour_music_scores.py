"""Original melodies and arrangements for the playable tour venues."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Song:
    slug: str
    title: str
    key: int
    mode: str
    chords: tuple[int, ...]
    hook: tuple[int, ...]
    lead: str
    groove: int


SCORES = {
    "alley": (
        Song("post-office", "우체국 앞 첫 박", 60, "major", (1, 4, 2, 5), (0, 2, 4, 6, 4, 2, 1, 0), "marimba", 0),
        Song("ginkgo", "은행잎 턴테이블", 57, "major", (1, 6, 4, 5), (4, 2, 0, 1, 2, 4, 2, 0), "keys", 1),
        Song("book-lane", "책갈피의 쉼표", 58, "dorian", (1, 4, 7, 1), (2, 4, 5, 3, 2, 0, -1, 0), "guitar", 2),
        Song("retro-arcade", "백 원짜리 코러스", 62, "mixolydian", (1, 7, 4, 1), (0, 4, 2, 4, 7, 6, 4, 2), "chip", 1),
        Song("tile-courtyard", "기와 위 달그림자", 55, "dorian", (1, 3, 4, 5), (0, 1, 2, 4, 3, 4, 2, 0), "reed", 0),
        Song("station-square", "역전광장 앙코르", 59, "major", (1, 3, 4, 5), (2, 4, 7, 4, 6, 5, 4, 2), "brass", 2),
    ),
    "coast": (
        Song("lighthouse", "등대가 켜질 때", 57, "major", (1, 4, 6, 5), (0, 2, 4, 3, 2, 4, 6, 4), "guitar", 2),
        Song("fishing-pier", "낚싯줄과 반박", 60, "mixolydian", (1, 7, 2, 4), (4, 3, 2, 0, 1, 2, 4, 2), "marimba", 0),
        Song("sea-wall", "방파제를 넘는 파도", 55, "minor", (1, 6, 3, 7), (0, 2, 5, 4, 2, 1, 0, -1), "reed", 1),
        Song("fish-market", "새벽 경매 박자", 58, "major", (1, 4, 2, 5), (2, 0, 2, 4, 1, 2, 4, 6), "marimba", 1),
        Song("tide-dock", "썰물의 발자국", 61, "dorian", (1, 4, 3, 7), (2, 5, 4, 2, 0, 1, -1, 0), "keys", 2),
        Song("sunset-beach", "마지막 노을 위로", 56, "major", (4, 1, 6, 5), (4, 6, 7, 6, 4, 2, 3, 0), "guitar", 0),
    ),
    "forest": (
        Song("pine-camp", "솔잎 모닥불", 60, "major", (1, 6, 2, 5), (0, 2, 4, 2, 0, 1, 2, 0), "guitar", 0),
        Song("rest-deck", "나무 의자 옆", 57, "mixolydian", (1, 4, 7, 4), (2, 3, 4, 6, 4, 3, 2, 0), "marimba", 2),
        Song("valley-table", "돌 사이 물길", 58, "dorian", (1, 3, 4, 1), (4, 2, 1, 2, 3, 5, 4, 2), "reed", 1),
        Song("firefly-bank", "반딧불 세기", 61, "minor", (1, 3, 6, 4), (0, 4, 6, 7, 4, 3, 2, 0), "bell", 0),
        Song("wood-hall", "목조홀 나뭇결", 55, "dorian", (1, 4, 1, 7), (2, 0, 3, 4, 2, 0, 1, -1), "guitar", 1),
        Song("forest-stage", "숲길 끝에서 만나", 59, "major", (1, 4, 6, 2), (0, 2, 4, 7, 6, 4, 3, 2), "reed", 2),
    ),
    "metro": (
        Song("underpass", "고가 아래 저음", 56, "minor", (1, 6, 7, 1), (0, 0, 3, 2, 4, 2, 6, 4), "synth", 0),
        Song("glass-tower", "유리 외벽 반사광", 61, "dorian", (1, 4, 6, 7), (4, 6, 5, 2, 3, 4, 2, 0), "keys", 1),
        Song("station-steps", "환승 30초 전", 59, "minor", (1, 7, 6, 7), (0, 1, 2, 5, 4, 3, 2, 4), "chip", 2),
        Song("neon-laundry", "네온 세탁소 스핀", 58, "mixolydian", (1, 4, 1, 7), (4, 2, 0, 2, 6, 4, 5, 2), "synth", 1),
        Song("parking-top", "주차타워 야경", 55, "minor", (1, 4, 6, 5), (2, 4, 5, 3, 1, 2, 4, 6), "brass", 0),
        Song("last-train", "막차 문이 닫히고", 60, "dorian", (1, 7, 4, 1), (4, 7, 6, 4, 2, 4, 3, 0), "bell", 2),
    ),
    "hall": (
        Song("brick-club", "붉은 벽돌 백비트", 57, "minor", (1, 4, 6, 7), (0, 3, 2, 4, 0, 3, 6, 4), "guitar", 0),
        Song("factory", "철제 보 위의 리프", 55, "dorian", (1, 7, 4, 3), (0, 4, 0, 3, 2, 4, 6, 5), "brass", 2),
        Song("cinema", "커튼이 올라오면", 60, "major", (1, 6, 2, 4), (2, 4, 7, 6, 5, 4, 2, 1), "keys", 2),
        Song("record-store", "바늘 아래 45회전", 58, "mixolydian", (1, 4, 3, 7), (4, 2, 3, 2, 0, 2, 1, 0), "keys", 1),
        Song("rehearsal-hall", "첫 합주의 마디", 62, "major", (1, 4, 6, 5), (0, 4, 2, 4, 6, 2, 4, 0), "guitar", 1),
        Song("warehouse", "창고 벽을 타고", 56, "minor", (1, 6, 4, 5), (2, 4, 7, 6, 4, 2, 3, 0), "synth", 0),
    ),
    "festival": (
        Song("lantern-row", "등불 행렬의 시작", 60, "major", (1, 4, 2, 5), (0, 2, 4, 5, 4, 2, 3, 4), "reed", 0),
        Song("food-court", "첫 모금에 한 박", 57, "mixolydian", (1, 7, 4, 1), (2, 0, 2, 4, 2, 4, 1, 2), "marimba", 1),
        Song("carousel", "목마의 마지막 한 바퀴", 59, "major", (1, 3, 4, 5), (4, 6, 7, 6, 5, 4, 2, 0), "bell", 2),
        Song("street-float", "수레 지나가는 길", 58, "mixolydian", (1, 4, 7, 5), (0, 4, 2, 4, 0, 2, 4, 7), "brass", 0),
        Song("midway", "밤 놀이터 점프", 61, "dorian", (1, 3, 4, 7), (2, 5, 4, 6, 3, 4, 2, 1), "chip", 1),
        Song("main-fair", "메인광장이 하나로", 56, "major", (1, 6, 4, 5), (0, 2, 5, 4, 7, 6, 4, 2), "brass", 2),
    ),
    "river": (
        Song("reed-park", "갈대가 방향을 틀 때", 59, "dorian", (1, 4, 7, 1), (0, 2, 4, 1, 2, 4, 3, 0), "reed", 2),
        Song("water-stairs", "물가의 반걸음", 56, "major", (4, 1, 2, 5), (4, 2, 1, 0, 2, 3, 4, 1), "keys", 0),
        Song("bike-bridge", "자전거 다리 아래", 60, "mixolydian", (1, 7, 2, 4), (0, 3, 4, 6, 4, 3, 2, 4), "marimba", 1),
        Song("fountain-park", "분수의 여덟 박", 61, "major", (1, 6, 4, 2), (2, 4, 7, 4, 2, 5, 4, 2), "bell", 1),
        Song("boat-stage", "갑판에 선 밤", 57, "minor", (1, 3, 6, 7), (4, 2, 0, 2, 3, 5, 4, 0), "guitar", 2),
        Song("night-park", "잔디 위 달빛", 58, "major", (1, 4, 6, 5), (0, 2, 4, 7, 5, 2, 4, 6), "keys", 0),
    ),
    "winter": (
        Song("snow-square", "눈꽃 카운트", 60, "major", (1, 4, 2, 5), (0, 4, 6, 7, 4, 2, 3, 0), "bell", 2),
        Song("ski-lift", "리프트가 올라가", 57, "mixolydian", (1, 7, 4, 1), (2, 4, 5, 6, 4, 2, 4, 7), "chip", 1),
        Song("cabin", "벽난로 옆 세 의자", 55, "major", (1, 6, 2, 5), (4, 2, 0, 2, 1, 2, 4, 0), "guitar", 0),
        Song("frozen-lake", "얼음 밑 긴 음", 58, "minor", (1, 6, 3, 4), (0, 2, 5, 4, 6, 4, 2, 1), "bell", 0),
        Song("pass-station", "고갯길 종소리", 59, "dorian", (1, 4, 3, 7), (2, 0, 1, 4, 2, 3, 5, 4), "reed", 2),
        Song("summit", "정상에서 부르는 빛", 61, "major", (1, 3, 4, 5), (0, 3, 4, 7, 6, 4, 2, 4), "bell", 1),
    ),
}
