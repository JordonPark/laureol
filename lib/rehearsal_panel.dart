part of 'main.dart';

const _rehearsalSurface = Color(0xFF1D1C2C);
const _rehearsalEdge = Color(0xFF40384F);

class _RehearsalProgress extends StatelessWidget {
  const _RehearsalProgress({required this.step, required this.accent});

  final _RehearsalStep step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('조율', CupertinoIcons.slider_horizontal_3),
      ('신호', CupertinoIcons.antenna_radiowaves_left_right),
      ('떼창', CupertinoIcons.music_note_2),
    ];
    return Row(
      children: [
        for (final (index, (label, icon)) in steps.indexed) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _RehearsalStepBadge(
              label: label,
              icon: icon,
              active: index == step.index,
              done: index < step.index,
              accent: accent,
            ),
          ),
        ],
      ],
    );
  }
}

class _RehearsalStepBadge extends StatelessWidget {
  const _RehearsalStepBadge({
    required this.label,
    required this.icon,
    required this.active,
    required this.done,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : (done ? _mint : _muted);
    return Semantics(
      container: true,
      label: active ? '$label, 현재 단계' : (done ? '$label 완료' : label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        constraints: const BoxConstraints(minHeight: 38),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? Color.alphaBlend(color.withAlpha(27), _rehearsalSurface)
              : _rehearsalSurface,
          border: Border.all(
            color: active ? color.withAlpha(172) : _rehearsalEdge,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            Icon(
              done ? CupertinoIcons.check_mark : icon,
              color: color,
              size: 14,
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RehearsalBoard extends StatelessWidget {
  const _RehearsalBoard({
    required this.wide,
    required this.accent,
    required this.scene,
    required this.deck,
  });

  final bool wide;
  final Color accent;
  final Widget scene;
  final Widget deck;

  @override
  Widget build(BuildContext context) {
    final stage = Padding(
      padding: const EdgeInsets.all(5),
      child: Center(child: scene),
    );
    final separator = ColoredBox(
      color: accent.withAlpha(120),
      child: SizedBox(
        width: wide ? 1 : double.infinity,
        height: wide ? 164 : 1,
      ),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: wide
            ? LinearGradient(
                colors: [
                  _rehearsalSurface,
                  Color.alphaBlend(accent.withAlpha(13), _rehearsalSurface),
                ],
              )
            : null,
        color: _rehearsalSurface,
        border: Border.all(color: _rehearsalEdge),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 6, child: stage),
                separator,
                Expanded(flex: 5, child: deck),
              ],
            )
          : Column(children: [stage, separator, deck]),
    );
  }
}

class _RehearsalDeck extends StatelessWidget {
  const _RehearsalDeck({
    required this.step,
    required this.status,
    required this.accent,
    required this.volume,
    required this.dialSize,
    required this.wide,
    required this.feedbackBeat,
    required this.control,
  });

  final _RehearsalStep step;
  final CrowdStatus status;
  final Color accent;
  final int volume;
  final double dialSize;
  final bool wide;
  final int feedbackBeat;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    final ready = status == CrowdStatus.ready;
    final loud = status == CrowdStatus.loud;
    final singing = status == CrowdStatus.singing;
    final (title, hint, icon) = switch (step) {
      _RehearsalStep.volume => (
        '뒷줄 볼륨',
        ready ? '손을 떼요' : (loud ? '내려요' : '올려요'),
        ready
            ? CupertinoIcons.check_mark
            : (loud
                  ? CupertinoIcons.arrow_counterclockwise
                  : CupertinoIcons.arrow_clockwise),
      ),
      _RehearsalStep.signal => (
        '뒷줄에 신호 보내기',
        null,
        CupertinoIcons.antenna_radiowaves_left_right,
      ),
      _RehearsalStep.response => (
        singing ? '관객이 따라 불러요!' : '신호를 보냈어요',
        '곧 본 공연이 시작돼요',
        singing ? CupertinoIcons.music_note_2 : CupertinoIcons.check_mark,
      ),
    };
    final adjusting = step == _RehearsalStep.volume;
    final caption = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: adjusting
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (!adjusting) ...[
          Icon(icon, size: 24, color: accent),
          const SizedBox(height: 6),
        ],
        Semantics(
          header: true,
          liveRegion: !adjusting,
          child: Text(
            title,
            textAlign: adjusting ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: adjusting ? _muted : _paper,
              fontSize: adjusting ? 14 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (adjusting)
          ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$volume%',
                style: const TextStyle(
                  color: _paper,
                  fontSize: 36,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        if (hint != null) ...[
          SizedBox(height: adjusting ? 8 : 4),
          Wrap(
            alignment: adjusting ? WrapAlignment.start : WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              if (adjusting) Icon(icon, color: accent, size: 16),
              Text(
                hint,
                textAlign: adjusting ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  color: adjusting ? accent : _muted,
                  fontSize: 13,
                  fontWeight: adjusting ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        15,
        adjusting ? 5 : 12,
        15,
        adjusting ? 5 : 12,
      ),
      constraints: BoxConstraints(minHeight: dialSize + 10),
      decoration: wide
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    accent.withAlpha(15),
                    const Color(0xFF262438),
                  ),
                  const Color(0xFF1D1C2C),
                ],
              ),
            ),
      child: adjusting
          ? LayoutBuilder(
              builder: (context, bounds) {
                final dial = Semantics(
                  hint: ready
                      ? '노브에서 손을 떼면 신호 단계로 넘어가요.'
                      : (loud
                            ? '반시계 방향으로 돌리거나 아래로 밀어요.'
                            : '시계 방향으로 돌리거나 위로 밀어요.'),
                  child: SizedBox.square(dimension: dialSize, child: control),
                );
                if (bounds.maxWidth < dialSize + 84) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      caption,
                      Center(child: dial),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: caption),
                    dial,
                  ],
                );
              },
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                caption,
                const SizedBox(height: 13),
                if (control case final button?)
                  button
                else
                  _RehearsalMeter(
                    beat: feedbackBeat,
                    singing: singing,
                    color: accent,
                  ),
              ],
            ),
    );
  }
}

class _RehearsalMeter extends StatelessWidget {
  const _RehearsalMeter({
    required this.beat,
    required this.singing,
    required this.color,
  });

  final int beat;
  final bool singing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const pattern = [12.0, 21.0, 29.0, 37.0, 26.0, 19.0, 11.0];
    final stationary = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, maxHeight) in pattern.indexed)
              AnimatedContainer(
                duration: stationary
                    ? Duration.zero
                    : const Duration(milliseconds: 130),
                width: 7,
                height: singing
                    ? maxHeight *
                          (stationary || (index + beat) % 3 != 0 ? 1 : .58)
                    : 5 + index % 2 * 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(singing ? 225 : 92),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
