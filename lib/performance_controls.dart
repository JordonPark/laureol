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
  }) : assert(value >= 0 && value <= 100);

  final String zone;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$zone 볼륨',
      value: '$value%',
      increasedValue: value < 100 ? '${(value + 5).clamp(0, 100)}%' : null,
      decreasedValue: value > 0 ? '${(value - 5).clamp(0, 100)}%' : null,
      slider: true,
      onIncrease: value < 100
          ? () => onChanged((value + 5).clamp(0, 100))
          : null,
      onDecrease: value > 0 ? () => onChanged((value - 5).clamp(0, 100)) : null,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('볼륨', style: TextStyle(color: _muted)),
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
                    onTapDown: (details) => update(details.localPosition.dx),
                    onHorizontalDragStart: (details) =>
                        update(details.localPosition.dx),
                    onHorizontalDragUpdate: (details) =>
                        update(details.localPosition.dx),
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
                          child: const ColoredBox(color: _mint),
                        ),
                        Positioned(
                          left: filled,
                          width: thumb,
                          height: thumb,
                          child: const ColoredBox(color: _ink),
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
  const BeatStrip({super.key, required this.remaining, this.total = 4})
    : assert(total > 0 && remaining >= 0 && remaining <= total);

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '남은 박 $remaining',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('남은 박 $remaining', style: const TextStyle(color: _ink)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              total,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ColoredBox(
                    color: index < remaining ? _amber : _line,
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

class EventNotice extends StatelessWidget {
  const EventNotice({super.key, required this.message, this.remainingBeats});

  final String message;
  final int? remainingBeats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF382A33),
        border: Border.all(color: _amber.withAlpha(140)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        remainingBeats == null ? message : '$message · $remainingBeats박 후',
        style: const TextStyle(color: _amber),
      ),
    );
  }
}

class PerformanceScore extends StatelessWidget {
  const PerformanceScore({super.key, required this.score, this.maximum = 90})
    : assert(maximum > 0 && score >= 0 && score <= maximum);

  final int score;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '공연 점수 $score점, $maximum점 만점',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: _muted),
          children: [
            const TextSpan(text: '공연 점수  '),
            TextSpan(
              text: '$score',
              style: const TextStyle(
                color: _ink,
                fontSize: 24,
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
  });

  final String zone;
  final CrowdStatus status;
  final int volume;
  final ValueChanged<int> onVolumeChanged;
  final SignalState signalState;
  final VoidCallback? onSignal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
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
          const SizedBox(height: 6),
          CrowdStatusBadge(status: status),
          const SizedBox(height: 12),
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
