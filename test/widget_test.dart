import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  testWidgets('Shows the game title on launch', (tester) async {
    await tester.pumpWidget(LaureolApp(records: records));

    expect(find.text('라우럴! 볼륨 좀 올려'), findsOneWidget);
  });

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
    await tester.pump(Duration(milliseconds: (176 - scene().tick) * 125));
    final rearSlider = find.byType(ZoneVolumeSlider).last;
    final track = find.descendant(
      of: rearSlider,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onHorizontalDragUpdate != null,
      ),
    );
    await tester.ensureVisible(track);
    await tester.tapAt(tester.getCenter(track));
    await tester.pump();
    expect(find.text('✓  준비'), findsNWidgets(2));

    final signal = find.text('라우럴!').first;
    await tester.ensureVisible(signal);
    await tester.tap(signal);
    await tester.pump();

    expect(find.text('신호 예약'), findsOneWidget);
    expect(find.text('남은 박 4'), findsOneWidget);

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

    await tester.pump(Duration(milliseconds: (800 - scene().tick) * 125));
    await tapLabel('결과 보기');
    expect(find.text('전체 결과'), findsOneWidget);
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
