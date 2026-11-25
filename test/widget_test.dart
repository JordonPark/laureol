import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/festival_performance.dart';
import 'package:laureol/festival_scene.dart';
import 'package:laureol/festival_records.dart';
import 'package:laureol/main.dart';
import 'package:laureol/performance_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FestivalRecords records;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    records = FestivalRecords(await SharedPreferences.getInstance());
    await records.setVolume(0);
  });

  testWidgets('Shows the game title on launch', (tester) async {
    await tester.pumpWidget(LaureolApp(records: records));

    expect(find.text('라우럴! 볼륨 좀 올려'), findsOneWidget);
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
      expect(find.textContaining('두 줄이 함께 부르면 콤보가 이어져요'), findsOneWidget);
      final start = find.text('동네 축제 시작');
      expect(start.hitTestable(), findsOneWidget);
      await tester.tap(start);
      await tester.pumpAndSettle();

      final safeBounds = padding.deflateRect(Offset.zero & size);
      final cards = find.byType(ZoneControlCard);
      expect(cards, findsNWidgets(2));
      expect(find.textContaining('뒷줄 볼륨을 밀어 ✓ 준비에 맞춰요'), findsOneWidget);
      for (final target in [
        find.byType(FestivalScene),
        cards.first,
        cards.last,
      ]) {
        final bounds = tester.getRect(target);
        expect(bounds.left, greaterThanOrEqualTo(safeBounds.left));
        expect(bounds.right, lessThanOrEqualTo(safeBounds.right));
        expect(bounds.top, greaterThanOrEqualTo(safeBounds.top));
        expect(bounds.bottom, lessThanOrEqualTo(safeBounds.bottom));
      }
      expect(Scrollable.of(tester.element(cards.first)).position.pixels, 0);
      expect(find.byType(ZoneVolumeSlider).hitTestable(), findsNWidgets(2));

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

      await tester.pump(const Duration(seconds: 100));
      final results = find.text('결과 보기');
      expect(results.hitTestable(), findsOneWidget);
      await tester.tap(results);
      await tester.pumpAndSettle();
      expect(find.text('전체 결과'), findsOneWidget);
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
    await tapLabel('동네 축제 시작');
    FestivalScene scene() =>
        tester.widget<FestivalScene>(find.byType(FestivalScene));
    List<Rect> checkControlsInView() {
      final sceneRect = tester.getRect(find.byType(FestivalScene));
      final cards = find.byType(ZoneControlCard);
      final front = tester.getRect(cards.first);
      final back = tester.getRect(cards.last);
      expect(front.top, back.top);
      expect(sceneRect.top, greaterThanOrEqualTo(24));
      expect(sceneRect.bottom, lessThan(front.top));
      expect(front.bottom, lessThanOrEqualTo(616));
      expect(back.bottom, lessThanOrEqualTo(616));
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
            widget is GestureDetector && widget.onHorizontalDragUpdate != null,
      ),
    );
    expect(tester.getSize(track).height, greaterThanOrEqualTo(48));
    await tester.tapAt(tester.getCenter(track));
    await tester.pump();
    expect(find.text('✓  준비'), findsNWidgets(2));

    final signal = find.text('라우럴!').first;
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
    await tapLabel('결과 보기');
    expect(find.text('전체 결과'), findsOneWidget);
    expect(find.text('추천 연습 · 후렴 2 · 앞줄 미합류'), findsOneWidget);
    await tapLabel('후렴 2 연습 · 7/30');
    expect(find.text('후렴 2 연습'), findsOneWidget);
    expect(
      tester
          .widget<ZoneVolumeSlider>(find.byType(ZoneVolumeSlider).first)
          .value,
      50,
    );
    await tester.pump(Duration(milliseconds: (496 - scene().tick) * 125));
    await tapLabel('결과 보기');
    expect(find.text('후렴 연습 결과'), findsOneWidget);
    expect(find.text('이전 떼창 기록'), findsOneWidget);
    expect(find.text('이번 떼창 기록'), findsOneWidget);
    await tapLabel('전체 결과로');
    expect(find.text('전체 결과'), findsOneWidget);
    expect(records.concertBest?.score, 42);
    expect(tester.takeException(), isNull);
  });
}
