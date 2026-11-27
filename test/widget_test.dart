import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/concert_stage_art.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/festival_records.dart';
import 'package:laureol/festival_scene.dart';
import 'package:laureol/main.dart';
import 'package:laureol/performance_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _dialGesture(Finder slider) =>
    find.descendant(of: slider, matching: find.byType(RawGestureDetector));

void main() {
  late FestivalRecords records;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    records = FestivalRecords(await SharedPreferences.getInstance());
    await records.setVolume(0);
    await records.completeRehearsal();
  });

  testWidgets('Shows the game title on launch', (tester) async {
    await tester.pumpWidget(LaureolApp(records: records));

    expect(find.bySemanticsLabel('라우럴! 볼륨 좀 올려'), findsOneWidget);
  });

  testWidgets(
    'The stage catalog previews 200 variants apart from tour records',
    (tester) async {
      final art = StageSet.values.expand((set) => set.stages).toList();
      expect(art, hasLength(200));
      expect(art.map((stage) => stage.id).toSet(), hasLength(200));
      final tourArt = FestivalVenue.tourVenues.map(
        (venue) => ConcertStageArt.forVenue(venue)!.id,
      );
      expect(art.map((stage) => stage.id), containsAll(tourArt));
      expect(tourArt.toSet(), hasLength(FestivalVenue.tourVenues.length));

      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(LaureolApp(records: records));
      for (final label in ['공연 시작', '투어 48곳', '무대 도감', '골목과 광장']) {
        final button = find.text(label);
        expect(button.hitTestable(), findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
      expect(find.text('기와 정자 · 기본'), findsOneWidget);
      final last = find.text('골목 차양 · 피날레');
      await tester.scrollUntilVisible(last, 260);
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tour opens a region, plays a venue, and reflects its saved result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(LaureolApp(records: records));

      for (final label in ['공연 시작', '투어 48곳', '골목과 광장', '우체국 앞 작은광장 시작']) {
        final target = find.text(label);
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      FestivalScene scene() => tester.widget(find.byType(FestivalScene));
      expect(scene().venue, TourRegion.alley.venues.first);
      final rear = _dialGesture(find.byType(ZoneVolumeSlider).last);
      await tester.drag(rear, const Offset(0, -30));
      await tester.pump();
      await tester.tap(find.text('시작'));
      await tester.pump();
      await tester.pump(festivalTick * (736 - scene().tick));
      await tester.pumpAndSettle();
      expect(find.text('전체 결과'), findsOneWidget);
      final next = find.bySemanticsLabel('다음 무대 · 은행나무 삼거리');
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(scene().venue, TourRegion.alley.venues.elementAt(1));
      await tester.pageBack();
      await tester.pumpAndSettle();
      final best = records.bestFor(TourRegion.alley.venues.first);
      expect(best, isNotNull);
      expect(find.text('최고 ${best!.score}/90'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1 / 6 공연 완료'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An existing market record leads through the club to the rooftop',
    (tester) async {
      final festival = FestivalPerformance()
        ..startMainConcert()
        ..setVolume(FestivalZone.back, 50)
        ..advanceTicks(600);
      final market = FestivalPerformance(venue: FestivalVenue.nightMarket)
        ..advanceTicks(736);
      expect(await records.record(festival), isTrue);
      expect(await records.record(market), isTrue);

      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(LaureolApp(records: records));
      await tester.tap(find.text('공연 시작'));
      await tester.pumpAndSettle();
      expect(find.text('옥상 공연 시작'), findsNothing);
      final club = find.text('지하 라이브클럽 시작');
      await tester.ensureVisible(club);
      await tester.pumpAndSettle();
      await tester.tap(club);
      await tester.pumpAndSettle();

      FestivalScene scene() => tester.widget(find.byType(FestivalScene));
      expect(scene().venue, FestivalVenue.liveClub);
      final rear = _dialGesture(find.byType(ZoneVolumeSlider).last);
      BeatProgress beatBar() => tester.widget(find.byType(BeatProgress));
      expect(beatBar().active, isFalse);
      await tester.drag(rear, const Offset(0, -30));
      await tester.pump();
      await tester.tap(find.text('시작'));
      await tester.pump();
      expect(beatBar().active, isTrue);
      final frontDial = find.byType(ZoneVolumeSlider).first;
      ({int minimum, int maximum})? frontTarget() =>
          tester.widget<ZoneVolumeSlider>(frontDial).target;
      for (final count in [3, 2, 1]) {
        expect(find.bySemanticsLabel('앞줄 목표 변경까지 $count초'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('뒷줄 목표 변경까지')), findsNothing);
        expect(frontTarget(), (minimum: 46, maximum: 58));
        expect(beatBar().beat, count == 2 ? 2 : 0);
        expect(beatBar().phase, 0);
        await tester.pump(festivalTick);
        expect(beatBar().phase, .25);
        await tester.pump(festivalTick * 7);
      }
      expect(find.bySemanticsLabel(RegExp('앞줄 목표 변경까지')), findsNothing);
      expect(frontTarget(), (minimum: 30, maximum: 42));
      await tester.pump(festivalTick * (736 - scene().tick));
      await tester.pumpAndSettle();

      final nextShow = find.bySemanticsLabel('다음 무대 · 옥상 공연');
      await tester.ensureVisible(nextShow);
      await tester.tap(nextShow);
      await tester.pumpAndSettle();
      expect(scene().venue, FestivalVenue.rooftop);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('First rehearsal waits for the highlighted slider and signal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final firstRun = FestivalRecords(await SharedPreferences.getInstance());
    await firstRun.setVolume(0);
    const viewport = Size(320, 640);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LaureolApp(records: firstRun));
    await tester.tap(find.text('공연 시작'));
    await tester.pumpAndSettle();

    FestivalScene scene() =>
        tester.widget<FestivalScene>(find.byType(FestivalScene));
    final rear = find.byType(ZoneVolumeSlider);
    expect(find.text('공연 선택'), findsNothing);
    expect(rear, findsOneWidget);
    expect(find.byType(PerformanceScore), findsNothing);
    expect(find.text('라우럴!'), findsNothing);
    expect(scene().tick, 0);
    expect(find.text('뒷줄 볼륨'), findsOneWidget);
    expect(find.bySemanticsLabel('조율, 현재 단계'), findsOneWidget);
    expect(tester.widget<ZoneVolumeSlider>(rear).target, isNotNull);
    expect(tester.widget<ZoneVolumeSlider>(rear).highlighted, isTrue);
    await tester.pump(const Duration(seconds: 25));
    expect(scene().tick, 0);

    final rearTrack = _dialGesture(rear);
    final track = tester.getRect(rearTrack);
    expect(track.width, greaterThanOrEqualTo(140));
    expect(track.bottom, lessThan(viewport.height));
    final gesture = await tester.startGesture(
      Offset(track.center.dx, track.top + track.height * .60),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(scene().focusedZone, FestivalZone.back);
    expect(scene().focusedVolume, 50);
    expect(scene().readyZones, 1 << FestivalZone.back.index);
    expect(find.text('라우럴!'), findsNothing);
    await gesture.up();
    await tester.pump();
    expect(find.text('뒷줄에 신호 보내기'), findsOneWidget);
    expect(find.bySemanticsLabel('신호, 현재 단계'), findsOneWidget);
    expect(find.text('라우럴!').hitTestable(), findsOneWidget);
    expect(rear, findsNothing);
    expect(scene().tick, 112);
    await tester.pump(const Duration(seconds: 25));
    expect(scene().tick, 112);

    await tester.tap(find.text('라우럴!'));
    await tester.pump(const Duration(seconds: 2));
    expect(scene().back, CrowdStatus.singing);
    expect(scene().front, CrowdStatus.singing);
    await tester.pump(const Duration(seconds: 4));
    expect(firstRun.rehearsalCompleted, isTrue);
    expect(find.text('동네 축제 공연'), findsOneWidget);
    expect(tester.widget<ZoneVolumeSlider>(rear.last).value, 50);
    expect(rear, findsNWidgets(2));
    expect(find.text('시작'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(scene().tick, 160);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(LaureolApp(records: firstRun));
    await tester.tap(find.text('공연 시작'));
    await tester.pumpAndSettle();
    expect(find.text('조작 다시 연습'), findsOneWidget);
    await tester.tap(find.text('동네 축제 시작'));
    await tester.pumpAndSettle();
    expect(scene().tick, greaterThanOrEqualTo(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('The rim tracks clockwise and counterclockwise turns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LaureolApp(records: records));
    await tester.tap(find.text('공연 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('동네 축제 시작'));
    await tester.pumpAndSettle();

    final slider = find.byType(ZoneVolumeSlider).first;
    final bounds = tester.getRect(_dialGesture(slider));
    Offset rim(double degrees) {
      final angle = degrees * math.pi / 180;
      return bounds.center +
          Offset(math.cos(angle), math.sin(angle)) * (bounds.width * .38);
    }

    int volume() => tester.widget<ZoneVolumeSlider>(slider).value;

    expect(volume(), 50);
    final turn = await tester.startGesture(rim(170));
    await turn.moveTo(rim(190));
    await tester.pump();
    expect(volume(), 57);
    await turn.moveTo(rim(217));
    await tester.pump();
    expect(volume(), 67);
    await turn.moveTo(rim(190));
    await tester.pump();
    expect(volume(), 57);
    await turn.up();

    final regrip = await tester.startGesture(rim(260));
    await tester.pump();
    expect(volume(), 57);
    await regrip.moveTo(rim(233));
    await regrip.up();
    await tester.pump();
    expect(volume(), 47);

    final across = await tester.startGesture(rim(0));
    await across.moveTo(rim(180));
    await tester.pump();
    expect(volume(), 47);
    await across.moveTo(rim(207));
    await across.up();
    await tester.pump();
    expect(volume(), 57);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Both mixer targets and readiness stay independent of input', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LaureolApp(records: records));
    await tester.tap(find.text('공연 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('동네 축제 시작'));
    await tester.pumpAndSettle();

    final sliders = find.byType(ZoneVolumeSlider);
    CustomPaint dial(Finder slider) => tester.widget<CustomPaint>(
      find.descendant(
        of: _dialGesture(slider),
        matching: find.byType(CustomPaint),
      ),
    );
    final frontBefore = dial(sliders.first);
    final rearBefore = dial(sliders.last);
    expect(frontBefore.foregroundPainter, isNotNull);
    expect(rearBefore.foregroundPainter, isNotNull);
    FestivalScene scene() => tester.widget(find.byType(FestivalScene));
    const targets = (minimum: 46, maximum: 58);
    ZoneVolumeSlider slider(Finder knob) => tester.widget(knob);
    expect(slider(sliders.first).target, targets);
    expect(slider(sliders.last).target, targets);

    await tester.drag(_dialGesture(sliders.last), const Offset(0, -60));
    await tester.pump();
    expect(slider(sliders.last).value, 60);
    expect(slider(sliders.first).value, 50);
    expect(scene().front, CrowdStatus.ready);

    await tester.drag(_dialGesture(sliders.last), const Offset(0, 180));
    await tester.pump();
    expect(slider(sliders.first).value, 50);
    expect(slider(sliders.last).value, 0);
    expect(scene().front, CrowdStatus.ready);
    expect(
      dial(sliders.first).painter!.shouldRepaint(frontBefore.painter!),
      isFalse,
    );

    await tester.drag(_dialGesture(sliders.last), const Offset(0, -150));
    await tester.pump();
    final rearReady = dial(sliders.last);
    expect(scene().back, CrowdStatus.ready);

    await tester.drag(_dialGesture(sliders.first), const Offset(0, 150));
    await tester.pump();
    expect(slider(sliders.first).value, 0);
    expect(slider(sliders.last).value, 50);
    expect(scene().back, CrowdStatus.ready);
    expect(
      dial(sliders.last).painter!.shouldRepaint(rearReady.painter!),
      isFalse,
    );
    expect(
      dial(sliders.first).foregroundPainter!
          .shouldRepaint(frontBefore.foregroundPainter!),
      isFalse,
    );
    expect(
      dial(sliders.last).foregroundPainter!
          .shouldRepaint(rearBefore.foregroundPainter!),
      isFalse,
    );
  });

  testWidgets(
    'A small turn responds from the cap and can reverse immediately',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(LaureolApp(records: records));
      await tester.tap(find.text('공연 시작'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('동네 축제 시작'));
      await tester.pumpAndSettle();

      final front = find.byType(ZoneVolumeSlider).first;
      final bounds = tester.getRect(_dialGesture(front));
      Offset path(double degrees) {
        final angle = degrees * math.pi / 180;
        return bounds.center +
            Offset(math.cos(angle), math.sin(angle)) * (bounds.width * .17);
      }

      int volume() => tester.widget<ZoneVolumeSlider>(front).value;

      await tester.tapAt(bounds.topCenter + const Offset(0, 10));
      await tester.pump();
      expect(volume(), 50);

      final turn = await tester.startGesture(path(-90));
      await turn.moveTo(path(-72));
      await tester.pump();
      expect(volume(), greaterThan(50));
      final adjusted = volume();
      await turn.up();
      await tester.pump();

      final reverse = await tester.startGesture(path(-90));
      await reverse.moveTo(path(-72));
      await reverse.moveTo(path(-90));
      await reverse.up();
      await tester.pump();
      expect(volume(), adjusted);

      final rear = find.byType(ZoneVolumeSlider).last;
      await tester.drag(_dialGesture(rear), const Offset(0, -6));
      await tester.pump();
      expect(tester.widget<ZoneVolumeSlider>(rear).value, 42);
    },
  );

  testWidgets('Combo reconnect animates in place and respects reduced motion', (
    tester,
  ) async {
    Widget strip(int combo, {bool holding = false, bool reduceMotion = false}) {
      return MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              key: const ValueKey('combo test frame'),
              width: 300,
              child: ComboBadge(count: combo, holding: holding),
            ),
          ),
        ),
      );
    }

    double scale() =>
        tester.widget<Transform>(find.byType(Transform)).transform[0];
    await tester.pumpWidget(strip(18, holding: true));
    final frame = find.byKey(const ValueKey('combo test frame'));
    final originalBounds = tester.getRect(frame);
    expect(find.text('18 콤보 유지'), findsOneWidget);
    expect(scale(), 1);

    await tester.pumpWidget(strip(19));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('19 콤보'), findsOneWidget);
    expect(scale(), greaterThan(1.2));
    expect(tester.getRect(frame), originalBounds);
    await tester.pumpAndSettle();
    expect(scale(), 1);

    await tester.pumpWidget(strip(20, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('20 콤보'), findsOneWidget);
    expect(scale(), 1);
  });

  for (final (name, size, padding) in [
    (
      'short portrait',
      const Size(390, 740),
      const EdgeInsets.only(top: 59, bottom: 34),
    ),
    (
      'landscape with a notch',
      const Size(852, 393),
      const EdgeInsets.only(left: 59, right: 59, bottom: 21),
    ),
  ]) {
    testWidgets('iPhone $name keeps live controls and results in reach', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      final ratio = tester.view.devicePixelRatio;
      tester.view.padding = FakeViewPadding(
        left: padding.left * ratio,
        top: padding.top * ratio,
        right: padding.right * ratio,
        bottom: padding.bottom * ratio,
      );
      addTearDown(tester.view.resetPadding);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(LaureolApp(records: records));

      await tester.tap(find.text('공연 시작'));
      await tester.pumpAndSettle();
      final start = find.text('동네 축제 시작');
      expect(start.hitTestable(), findsOneWidget);
      await tester.tap(start);
      await tester.pumpAndSettle();

      final safeBounds = padding.deflateRect(Offset.zero & size);
      final cards = find.byType(ZoneControlCard);
      final beatBar = find.byType(BeatProgress);
      expect(cards, findsNWidgets(2));
      expect(find.text('두 노브를 민트색 눈금에 맞춰요'), findsOneWidget);
      for (final target in [
        find.byType(FestivalScene),
        beatBar,
        cards.first,
        cards.last,
        find.byType(SignalButton),
      ]) {
        final bounds = tester.getRect(target);
        expect(bounds.left, greaterThanOrEqualTo(safeBounds.left));
        expect(bounds.right, lessThanOrEqualTo(safeBounds.right));
        expect(bounds.top, greaterThanOrEqualTo(safeBounds.top));
        expect(bounds.bottom, lessThanOrEqualTo(safeBounds.bottom));
      }
      expect(
        tester.getBottomLeft(beatBar).dy,
        lessThan(tester.getTopLeft(cards.first).dy),
      );
      expect(Scrollable.of(tester.element(cards.first)).position.pixels, 0);
      expect(find.byType(ZoneVolumeSlider).hitTestable(), findsNWidgets(2));
      expect(find.byType(SignalButton).hitTestable(), findsOneWidget);
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).backCue,
        MixCue.adjust,
      );
      final rearSlider = tester.widget<ZoneVolumeSlider>(
        find.byType(ZoneVolumeSlider).last,
      );
      expect(rearSlider.highlighted, isTrue);
      expect(rearSlider.target, (minimum: 46, maximum: 58));
      await tester.tap(find.bySemanticsLabel('앞줄 볼륨 조작으로 이동'));
      await tester.pump();
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).focusedZone,
        FestivalZone.front,
      );
      expect(tester.widget<ZoneControlCard>(cards.first).selected, isTrue);
      final backTrack = _dialGesture(find.byType(ZoneVolumeSlider).last);
      final backBounds = tester.getRect(backTrack);
      await tester.drag(backTrack, const Offset(0, -21));
      await tester.pump();
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).focusedVolume,
        47,
      );
      await tester.drag(backTrack, const Offset(0, -21));
      await tester.pump();
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).focusedVolume,
        54,
      );
      await tester.tapAt(Offset(backBounds.right - 8, backBounds.top + 8));
      await tester.pump();
      final focused = tester.widget<FestivalScene>(find.byType(FestivalScene));
      expect(focused.focusedZone, FestivalZone.back);
      expect(focused.focusedVolume, 55);
      expect(tester.widget<ZoneControlCard>(cards.last).selected, isTrue);
      await tester.tap(find.text('시작'));
      await tester.pump();

      final stage = tester.widget<FestivalScene>(find.byType(FestivalScene));
      await tester.pump(festivalTick * (272 - stage.tick));
      expect(
        tester.widget<SignalButton>(find.byType(SignalButton)).onPressed,
        isNull,
      );
      expect(find.byType(ZoneVolumeSlider).hitTestable(), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).tick,
        368,
      );
      expect(
        tester.widget<SignalButton>(find.byType(SignalButton)).onPressed,
        isNull,
      );

      final closingTick = tester
          .widget<FestivalScene>(find.byType(FestivalScene))
          .tick;
      await tester.pump(festivalTick * (735 - closingTick));
      expect(find.byType(FestivalScene), findsOneWidget);
      expect(find.text('전체 결과'), findsNothing);
      await tester.pump(festivalTick);
      await tester.pumpAndSettle();
      expect(find.text('전체 결과'), findsOneWidget);
      expect(find.text('결과 보기'), findsNothing);
      final nextShow = find.bySemanticsLabel('다음 무대 · 야외 야시장');
      expect(nextShow.hitTestable(), findsOneWidget);
      final footerBounds = tester.getRect(nextShow);
      final chorus = find.text('후렴 1');
      await tester.ensureVisible(chorus);
      await tester.tap(chorus);
      await tester.pumpAndSettle();
      expect(find.textContaining('동시 떼창'), findsOneWidget);
      expect(find.textContaining('연습'), findsNothing);
      expect(nextShow.hitTestable(), findsOneWidget);
      expect(tester.getRect(nextShow), footerBounds);
      expect(records.concertBest, isNotNull);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.iOS}));
  }

  testWidgets('Large system text keeps the rear controls reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(LaureolApp(records: records));
    final start = find.text('공연 시작');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    final festival = find.text('동네 축제 시작');
    await tester.ensureVisible(festival);
    await tester.tap(festival);
    await tester.pumpAndSettle();

    final rear = find.text('뒷줄');
    await tester.scrollUntilVisible(rear, 160);
    final rearSlider = find.byWidgetPredicate(
      (widget) => widget is ZoneVolumeSlider && widget.zone == '뒷줄',
    );
    await tester.ensureVisible(rearSlider);
    expect(rearSlider, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preview connects settings, performance, pause and results', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    final inset = tester.view.devicePixelRatio * 24;
    tester.view.padding = FakeViewPadding(top: inset, bottom: inset);
    addTearDown(tester.view.resetPadding);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LaureolApp(records: records));

    Future<void> tapLabel(String label) async {
      final target = find.text(label);
      if (target.evaluate().isEmpty) {
        await tester.scrollUntilVisible(target, 120);
      } else {
        await tester.ensureVisible(target.first);
      }
      await tester.pump();
      await tester.tap(target.first);
      await tester.pumpAndSettle();
    }

    await tapLabel('설정');
    expect(find.text('진동'), findsOneWidget);
    await tapLabel('뒤로');
    await tapLabel('공연 시작');
    expect(find.text('공연 선택'), findsOneWidget);
    expect(find.text('야외 야시장'), findsOneWidget);
    expect(find.text('잠김'), findsNWidgets(3));
    expect(find.text('야외 야시장 시작'), findsNothing);
    await tapLabel('동네 축제 시작');
    FestivalScene scene() =>
        tester.widget<FestivalScene>(find.byType(FestivalScene));
    List<Rect> checkControlsInView() {
      final sceneRect = tester.getRect(find.byType(FestivalScene));
      final cards = find.byType(ZoneControlCard);
      final front = tester.getRect(cards.first);
      final back = tester.getRect(cards.last);
      expect(front.right, lessThan(back.left));
      expect(sceneRect.top, greaterThanOrEqualTo(24));
      expect(sceneRect.bottom, lessThan(front.top));
      expect(front.top, back.top);
      expect(front.size, back.size);
      expect(front.width, front.height);
      expect(
        back.bottom,
        lessThan(tester.getRect(find.byType(SignalButton)).top),
      );
      expect(Scrollable.of(tester.element(cards.first)).position.pixels, 0);
      return [front, back];
    }

    final cardBounds = checkControlsInView();
    expect(scene().compact, isTrue);
    expect(find.text('준비'), findsOneWidget);
    expect(find.text('시작'), findsNothing);
    await tester.pump(const Duration(seconds: 8));
    expect(scene().tick, 160);
    final rearSlider = find.byType(ZoneVolumeSlider).last;
    final track = _dialGesture(rearSlider);
    expect(tester.getSize(track).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(track).width, greaterThanOrEqualTo(76));
    await tester.drag(track, const Offset(0, -30));
    await tester.pump();
    expect(find.text('✓  준비'), findsNWidgets(2));
    await tester.tap(find.text('시작'));
    await tester.pump();
    expect(
      tester.widget<SignalButton>(find.byType(SignalButton)).onPressed,
      isNull,
    );
    await tester.pump(festivalTick * (176 - scene().tick));

    final signal = find.text('라우럴!').first;
    expect(find.byType(SignalButton), findsOneWidget);
    await tester.drag(track, const Offset(0, 150));
    await tester.pump();
    expect(scene().front, CrowdStatus.ready);
    expect(scene().back, CrowdStatus.quiet);
    expect(
      tester.widget<SignalButton>(find.byType(SignalButton)).onPressed,
      isNotNull,
    );
    await tester.drag(track, const Offset(0, -150));
    await tester.pump();
    expect(find.bySemanticsLabel('라우럴! 앞줄'), findsOneWidget);
    expect(scene().frontCue, MixCue.signal);
    expect(
      tester.getSize(find.byType(SignalButton).first).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(signal);
    await tester.pump();

    expect(find.text('신호 예약'), findsOneWidget);
    expect(scene().signalPulse?.rows, 1 << FestivalZone.front.index);
    expect(scene().front, CrowdStatus.ready);
    expect(find.textContaining('남은 박'), findsNothing);
    expect(checkControlsInView(), cardBounds);

    await tester.tap(find.bySemanticsLabel('일시정지'));
    await tester.pumpAndSettle();
    expect(find.text('이어 하기'), findsOneWidget);
    final pausedTick = tester
        .widget<FestivalScene>(find.byType(FestivalScene))
        .tick;
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<FestivalScene>(find.byType(FestivalScene)).tick,
      pausedTick,
    );
    expect(find.text('신호 예약'), findsOneWidget);
    await tapLabel('이어 하기');

    for (var i = 0; i < 28 && scene().waveFrame == null; i++) {
      await tester.pump(const Duration(milliseconds: 125));
    }
    expect(scene().generatorRunning, isFalse);
    expect(scene().front, CrowdStatus.singing);
    expect(scene().back, CrowdStatus.singing);
    expect(scene().waveFrame, isNotNull);
    expect(checkControlsInView(), cardBounds);

    await tester.pump(Duration(milliseconds: (736 - scene().tick) * 125));
    await tester.pumpAndSettle();
    expect(find.text('전체 결과'), findsOneWidget);
    expect(find.text('동네 축제 완료'), findsOneWidget);
    expect(find.text('추천 연습'), findsNothing);
    expect(find.textContaining('동시 떼창'), findsNothing);
    await tapLabel('후렴 1');
    expect(find.textContaining('동시 떼창'), findsOneWidget);
    expect(find.text('후렴 1 연습'), findsNothing);
    await tapLabel('후렴 2');
    expect(find.textContaining('동시 떼창'), findsOneWidget);
    expect(find.textContaining('앞줄 미합류'), findsOneWidget);
    expect(find.text('후렴 2 연습'), findsNothing);
    expect(records.concertBest?.score, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Combo break stays visible and replay starts a new concert', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LaureolApp(records: records));
    await tester.tap(find.text('공연 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('동네 축제 시작'));
    await tester.pumpAndSettle();

    FestivalScene scene() =>
        tester.widget<FestivalScene>(find.byType(FestivalScene));
    Future<void> advanceTo(int tick) =>
        tester.pump(festivalTick * (tick - scene().tick));
    final rearTrack = _dialGesture(find.byType(ZoneVolumeSlider).last);
    const missedTick = 248;
    await tester.drag(rearTrack, const Offset(0, -30));
    await tester.pump();
    await tester.tap(find.text('시작'));
    await tester.pump();
    await advanceTo(176);
    await tester.tap(find.text('라우럴!').first);
    await advanceTo(240);
    expect(find.text('10 콤보!'), findsOneWidget);
    final front = find.bySemanticsLabel('앞줄 볼륨 조작으로 이동');
    await tester.tap(front);
    await tester.pump();
    expect(scene().focusedZone, FestivalZone.front);
    expect(find.byType(ZoneVolumeSlider).hitTestable(), findsNWidgets(2));
    await advanceTo(missedTick);
    await tester.drag(rearTrack, const Offset(0, -54));
    await advanceTo(252);
    expect(find.text('10 콤보!'), findsNothing);
    await advanceTo(736);
    await tester.pumpAndSettle();

    expect(find.text('끊기기 3초 전부터 연습'), findsNothing);
    expect(find.textContaining('콤보 끊김 · 후렴 1'), findsOneWidget);
    final saved = records.concertBest?.score;
    expect(saved, isNotNull);
    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    expect(scene().tick, 160);
    expect(find.text('두 노브를 민트색 눈금에 맞춰요'), findsOneWidget);
    expect(records.concertBest?.score, saved);
  });
}
