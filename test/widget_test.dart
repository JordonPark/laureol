import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/festival_records.dart';
import 'package:laureol/festival_scene.dart';
import 'package:laureol/main.dart';
import 'package:laureol/performance_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('First rehearsal waits for the highlighted slider and signal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final firstRun = FestivalRecords(await SharedPreferences.getInstance());
    await firstRun.setVolume(0);
    await tester.binding.setSurfaceSize(const Size(390, 740));
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
    expect(find.text('뒷줄 볼륨을 맞춰요'), findsOneWidget);
    expect(tester.widget<ZoneVolumeSlider>(rear).highlighted, isTrue);
    await tester.pump(const Duration(seconds: 25));
    expect(scene().tick, 0);

    final rearTrack = find.descendant(
      of: rear,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onVerticalDragUpdate != null,
      ),
    );
    final track = tester.getRect(rearTrack);
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
    expect(find.text('이제 관객에게 신호를 보내요'), findsOneWidget);
    expect(find.text('라우럴!'), findsOneWidget);
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
              width: 300,
              child: BeatStrip(
                remaining: 4,
                combo: combo,
                holdingCombo: holding,
              ),
            ),
          ),
        ),
      );
    }

    double scale() =>
        tester.widget<Transform>(find.byType(Transform)).transform[0];
    await tester.pumpWidget(strip(18, holding: true));
    final originalBounds = tester.getRect(find.byType(BeatStrip));
    expect(find.text('18 콤보 유지'), findsOneWidget);
    expect(scale(), 1);

    await tester.pumpWidget(strip(19));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('19 콤보'), findsOneWidget);
    expect(scale(), greaterThan(1.2));
    expect(tester.getRect(find.byType(BeatStrip)), originalBounds);
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
      expect(cards, findsNWidgets(2));
      expect(find.textContaining('뒷줄 볼륨을 올려 ✓ 준비에 맞춰요'), findsOneWidget);
      for (final target in [
        find.byType(FestivalScene),
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
      final backTrack = find.descendant(
        of: find.byType(ZoneVolumeSlider).last,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector && widget.onVerticalDragUpdate != null,
        ),
      );
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
      await tester.tapAt(Offset(backBounds.center.dx, backBounds.top + 8));
      await tester.pump();
      final focused = tester.widget<FestivalScene>(find.byType(FestivalScene));
      expect(focused.focusedZone, FestivalZone.back);
      expect(focused.focusedVolume, 55);
      expect(tester.widget<ZoneControlCard>(cards.last).selected, isTrue);

      final stage = tester.widget<FestivalScene>(find.byType(FestivalScene));
      await tester.pump(festivalTick * (272 - stage.tick));
      expect(find.text('후렴 2 신호까지 16박'), findsOneWidget);
      expect(find.byType(ZoneVolumeSlider).hitTestable(), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester.widget<FestivalScene>(find.byType(FestivalScene)).tick,
        368,
      );
      expect(find.text('후렴 2 신호까지 8박'), findsOneWidget);

      final closingTick = tester
          .widget<FestivalScene>(find.byType(FestivalScene))
          .tick;
      await tester.pump(festivalTick * (799 - closingTick));
      expect(find.byType(FestivalScene), findsOneWidget);
      expect(find.text('전체 결과'), findsNothing);
      await tester.pump(festivalTick);
      await tester.pumpAndSettle();
      expect(find.text('전체 결과'), findsOneWidget);
      expect(find.text('결과 보기'), findsNothing);
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
    expect(find.text('잠김'), findsOneWidget);
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
      expect(sceneRect.contains(front.center), isTrue);
      expect(sceneRect.contains(back.center), isTrue);
      expect(front.bottom, lessThanOrEqualTo(sceneRect.bottom));
      expect(back.bottom, lessThanOrEqualTo(sceneRect.bottom));
      expect(Scrollable.of(tester.element(cards.first)).position.pixels, 0);
      return [front, back];
    }

    final cardBounds = checkControlsInView();
    expect(scene().compact, isTrue);
    await tester.pump(Duration(milliseconds: (176 - scene().tick) * 125));
    final rearSlider = find.byType(ZoneVolumeSlider).last;
    final track = find.descendant(
      of: rearSlider,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onVerticalDragUpdate != null,
      ),
    );
    expect(tester.getSize(track).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(track).width, greaterThanOrEqualTo(48));
    await tester.drag(track, const Offset(0, -30));
    await tester.pump();
    expect(find.text('✓  준비'), findsNWidgets(2));

    final signal = find.text('라우럴!').first;
    expect(find.byType(SignalButton), findsOneWidget);
    expect(find.bySemanticsLabel('라우럴! 앞줄'), findsOneWidget);
    expect(scene().frontCue, MixCue.signal);
    expect(
      tester.getSize(find.byType(SignalButton).first).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(signal);
    await tester.pump();

    expect(find.text('신호 예약'), findsOneWidget);
    expect(find.text('남은 박 4'), findsOneWidget);
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

    await tester.pump(Duration(milliseconds: (800 - scene().tick) * 125));
    await tester.pumpAndSettle();
    expect(find.text('전체 결과'), findsOneWidget);
    expect(find.text('동네 축제 완료'), findsOneWidget);
    expect(find.text('추천 연습'), findsOneWidget);
    expect(find.textContaining('동시 떼창'), findsNothing);
    await tapLabel('후렴 1');
    expect(find.text('후렴 1 연습'), findsOneWidget);
    await tapLabel('후렴 2');
    expect(find.text('후렴 1 연습'), findsNothing);
    expect(find.textContaining('앞줄 미합류'), findsOneWidget);
    await tapLabel('후렴 2 연습');
    expect(find.text('후렴 2 연습'), findsOneWidget);
    expect(
      tester
          .widget<ZoneVolumeSlider>(find.byType(ZoneVolumeSlider).first)
          .value,
      50,
    );
    await tester.pump(Duration(milliseconds: (496 - scene().tick) * 125));
    await tester.pumpAndSettle();
    expect(find.text('후렴 연습 결과'), findsOneWidget);
    expect(find.text('이전 떼창 기록'), findsOneWidget);
    expect(find.text('이번 떼창 기록'), findsOneWidget);
    await tapLabel('전체 결과로');
    expect(find.text('전체 결과'), findsOneWidget);
    expect(records.concertBest?.score, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Combo practice opens and returns from results automatically', (
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
    final rearTrack = find.descendant(
      of: find.byType(ZoneVolumeSlider).last,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onVerticalDragUpdate != null,
      ),
    );
    const missedTick = 248;
    await advanceTo(176);
    await tester.drag(rearTrack, const Offset(0, -30));
    await tester.pump();
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
    await advanceTo(800);
    await tester.pumpAndSettle();

    final retry = find.text('끊기기 3초 전부터 연습');
    expect(retry, findsOneWidget);
    final saved = records.concertBest?.score;
    expect(saved, isNotNull);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(scene().tick, inInclusiveRange(missedTick - 24, missedTick - 1));
    expect(
      tester.widget<ZoneVolumeSlider>(find.byType(ZoneVolumeSlider).last).value,
      50,
    );
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('콤보 복구 연습 결과'), findsOneWidget);
    expect(find.text('두 줄이 다시 합류했어요!'), findsOneWidget);
    await tester.tap(find.text('전체 결과로'));
    await tester.pumpAndSettle();
    expect(find.text('전체 결과'), findsOneWidget);
    expect(records.concertBest?.score, saved);
  });
}
