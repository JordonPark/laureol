// Use the same SDK widgets as the rest of the prototype.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';

import 'festival_performance.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    required this.artHeight,
    required this.best,
    required this.missionCompleted,
    required this.onPlay,
  });

  final FestivalVenue venue;
  final double artHeight;
  final int? best;
  final bool missionCompleted;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final locked = onPlay == null;
    final accent = Color(venue.accent);
    final objective = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (venue.description case final description?)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              description,
              style: const TextStyle(color: Color(0xFFF7F2FF), fontSize: 13),
            ),
          ),
        Text(
          locked ? venue.unlockHint ?? venue.mission : venue.mission,
          style: TextStyle(
            color: locked ? const Color(0xFFBDB8CD) : accent,
            fontSize: 13,
          ),
        ),
      ],
    );
    final start = CupertinoButton(
      color: accent,
      foregroundColor: const Color(0xFF191427),
      minimumSize: const Size(48, 48),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onPlay,
      child: Text(
        '${venue.title} 시작',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF252037),
        border: Border.all(color: accent.withAlpha(locked ? 55 : 115)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: artHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VenueArtwork(venue: venue),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        locked
                            ? const Color(0x66171329)
                            : const Color(0x24171329),
                        const Color(0x10171329),
                        const Color(0xF8171329),
                      ],
                      stops: const [0, .28, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        venue.title,
                        style: const TextStyle(
                          color: Color(0xFFF7F2FF),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (best case final score?)
                        _VenueTag(color: accent, label: '최고 $score/90')
                      else if (locked)
                        const _VenueTag(
                          color: Color(0xFFE3D8F0),
                          label: '잠김',
                          icon: CupertinoIcons.lock_fill,
                        ),
                      if (missionCompleted)
                        _VenueTag(
                          color: accent,
                          label: '목표 달성',
                          icon: CupertinoIcons.checkmark,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: locked
                ? objective
                : LayoutBuilder(
                    builder: (context, bounds) {
                      if (bounds.maxWidth < 250 ||
                          MediaQuery.textScalerOf(context).scale(14) > 19) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            objective,
                            const SizedBox(height: 8),
                            start,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: objective),
                          const SizedBox(width: 10),
                          start,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class VenueArtwork extends StatelessWidget {
  const VenueArtwork({
    super.key,
    required this.venue,
    this.alignment = const Alignment(0, .18),
  });

  final FestivalVenue venue;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final stage = switch (venue.stage) {
      TourStage.canopy => 'stage.png',
      TourStage.theatre => 'stage-club.png',
      TourStage.deck => 'stage-rooftop.png',
      TourStage.studio => 'stage-tour-studio.png',
      TourStage.rig => 'stage-tour-rig.png',
      TourStage.arena => 'stage-tour-arena.png',
      null => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          venue.posterAsset,
          fit: BoxFit.cover,
          cacheWidth: venue.region == null ? null : 768,
          alignment: alignment,
          excludeFromSemantics: true,
        ),
        if (stage != null)
          Align(
            alignment: const Alignment(.90, .63),
            child: FractionallySizedBox(
              widthFactor: venue.stage == TourStage.arena ? .68 : .58,
              heightFactor: .96,
              child: Image.asset(
                'docs/art/festival/$stage',
                color: Color.lerp(
                  const Color(0xFFFFFFFF),
                  Color(venue.accent),
                  .25,
                ),
                colorBlendMode: BlendMode.modulate,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                excludeFromSemantics: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _VenueTag extends StatelessWidget {
  const _VenueTag({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD91B1529),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final glyph?) ...[
              Icon(glyph, color: color, size: 12),
              const SizedBox(width: 5),
            ],
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
