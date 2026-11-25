import 'package:flutter/widgets.dart';

import 'festival_performance.dart';

ChorusResult? recommendedChorusPractice(List<ChorusResult> results) {
  ChorusResult? selected;
  var bestPriority = 0;
  var bestTieBreak = 0;
  for (final result in results) {
    final front = result.firstBeat(FestivalZone.front);
    final back = result.firstBeat(FestivalZone.back);
    final missing = front == null || back == null;
    final priority = missing
        ? 2
        : front == back
        ? 0
        : 1;
    if (priority == 0) continue;
    final tieBreak = missing ? -result.score : (front - back).abs();
    if (selected == null ||
        priority > bestPriority ||
        (priority == bestPriority && tieBreak > bestTieBreak)) {
      selected = result;
      bestPriority = priority;
      bestTieBreak = tieBreak;
    }
  }
  return selected;
}

class ChorusSummary extends StatelessWidget {
  const ChorusSummary({
    super.key,
    required this.result,
    this.recommended = false,
  });

  final ChorusResult result;
  final bool recommended;

  String get _practiceHint {
    final front = result.firstBeat(FestivalZone.front);
    final back = result.firstBeat(FestivalZone.back);
    if (front == null && back == null) return '두 구역 미합류';
    if (front == null) return '앞줄 미합류';
    if (back == null) return '뒷줄 미합류';
    final later = front < back ? '뒷줄' : '앞줄';
    return '$later이 ${(front - back).abs()}박 뒤에 합류';
  }

  String get _start {
    final front = result.firstBeat(FestivalZone.front);
    final back = result.firstBeat(FestivalZone.back);
    if (front == null && back == null) return '떼창 합류 없음';
    if (front == back) return '동시 시작 · $front박';
    if (back == null) return '앞줄 시작 · $front박 / 뒷줄 미합류';
    if (front == null) return '뒷줄 시작 · $back박 / 앞줄 미합류';
    return front < back
        ? '앞줄 시작 $front박 · 뒷줄 합류 $back박'
        : '뒷줄 시작 $back박 · 앞줄 합류 $front박';
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF7F2FF);
    const amber = Color(0xFFFFC46A);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF24203A),
        border: recommended ? Border.all(color: amber) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recommended) ...[
            Text(
              '추천 연습 · 후렴 ${result.chorus} · $_practiceHint',
              style: const TextStyle(color: amber, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
          ],
          Text(_start, style: const TextStyle(color: ink)),
          const SizedBox(height: 6),
          Text(
            '동시 떼창 ${(result.togetherBeats / 2).toStringAsFixed(1)}초',
            style: const TextStyle(color: Color(0xFFBDB8CD)),
          ),
          for (final (zone, label, color) in const [
            (FestivalZone.front, '앞줄', Color(0xFF7CE0C2)),
            (FestivalZone.back, '뒷줄', Color(0xFFFFC46A)),
          ])
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Text(label, style: TextStyle(color: color, fontSize: 12)),
                    const SizedBox(width: 6),
                    for (var beat = 0; beat < result.beatCount; beat++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: result.sangAt(zone, beat)
                                  ? color
                                  : const Color(0xFF514866),
                              border: beat + 1 == result.firstBeat(zone)
                                  ? Border.all(color: ink)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
