import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_poster_toolkit/flutter_poster_toolkit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adds, selects, duplicates, deletes, and orders elements', () {
    final controller = PosterController();

    final text = controller.addText(text: 'Lost cat');
    expect(controller.document.elements, hasLength(1));
    expect(controller.selectedElementId, text.id);

    controller.duplicateSelected();
    expect(controller.document.elements, hasLength(2));
    expect(controller.selectedElementId, isNot(text.id));

    controller.sendToBack();
    expect(controller.document.elements.first.id, controller.selectedElementId);

    controller.bringToFront();
    expect(controller.document.elements.last.id, controller.selectedElementId);

    controller.deleteSelected();
    expect(controller.document.elements, hasLength(1));
    expect(controller.selectedElementId, isNull);
  });

  test('undo and redo restore document states', () {
    final controller = PosterController();

    controller.addText(text: 'One');
    controller.addShape(PosterShapeType.circle);
    expect(controller.document.elements, hasLength(2));

    controller.undo();
    expect(controller.document.elements, hasLength(1));

    controller.redo();
    expect(controller.document.elements, hasLength(2));
  });

  test('new circle shapes are perfect circles', () {
    final controller = PosterController();

    final circle = controller.addShape(PosterShapeType.circle);

    expect(circle.size.width, circle.size.height);
  });

  test('circle shapes can be resized freely after being added', () {
    final controller = PosterController();
    controller.addShape(PosterShapeType.circle);

    controller.resizeSelected(const Offset(40, 12));

    final circle = controller.selectedElement!;
    expect(circle.size.width, isNot(circle.size.height));
  });

  test('canvas resizing clamps elements inside bounds', () {
    final controller = PosterController(
      document: PosterDocument.empty(canvasSize: const Size(500, 500)),
    );

    controller.addShape(
      PosterShapeType.rectangle,
      position: const Offset(420, 430),
      size: const Size(180, 180),
    );
    controller.setCanvasSize(const Size(300, 300));

    final element = controller.document.elements.single;
    expect(element.position.dx, greaterThanOrEqualTo(0));
    expect(element.position.dy, greaterThanOrEqualTo(0));
    expect(element.position.dx + element.size.width, lessThanOrEqualTo(300));
    expect(element.position.dy + element.size.height, lessThanOrEqualTo(300));
  });

  test('locked elements do not move through transform helpers', () {
    final controller = PosterController();
    final text = controller.addText();
    controller.updateElement(text.copyWith(locked: true));

    final before = controller.selectedElement!.position;
    controller.moveSelected(const Offset(80, 40));
    expect(controller.selectedElement!.position, before);
  });

  test('resizing rotated elements uses their local axes', () {
    final controller = PosterController(
      document: PosterDocument.empty(canvasSize: const Size(800, 800)),
    );
    final shape = controller.addShape(
      PosterShapeType.rectangle,
      position: const Offset(240, 240),
      size: const Size(180, 110),
    );
    controller.updateElement(shape.copyWith(rotation: math.pi / 2));

    final before = controller.selectedElement!.size;
    controller.resizeSelected(const Offset(32, 0));

    expect(controller.selectedElement!.size.width, closeTo(before.width, 0.01));
    expect(controller.selectedElement!.size.height, lessThan(before.height));
  });

  test('flip flags are stored on elements', () {
    final controller = PosterController();
    final text = controller.addText();

    controller.updateElement(text.copyWithBase(flipX: true, flipY: true));

    expect(controller.selectedElement!.flipX, isTrue);
    expect(controller.selectedElement!.flipY, isTrue);
  });

  testWidgets('starts blank with the bottom toolbar visible', (tester) async {
    final controller = PosterController();

    await tester.pumpWidget(
      MaterialApp(home: PosterEditor(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(controller.document.elements, isEmpty);
    expect(find.byTooltip('Add Text'), findsOneWidget);
    expect(find.byTooltip('Show tools'), findsNothing);
  });

  testWidgets('editor canvas is centered and scaled once', (tester) async {
    final controller = PosterController(
      document: PosterDocument.empty(canvasSize: const Size(600, 820)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 720,
            child: PosterEditor(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editorRect = tester.getRect(find.byType(PosterEditor));
    final canvasRect = tester.getRect(find.byType(PosterCanvas));

    expect(canvasRect.width, closeTo(352, 1));
    expect(canvasRect.center.dx, closeTo(editorRect.center.dx, 1));
  });

  testWidgets('bottom toolbar adds items and opens selected properties', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PosterEditor()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add Text'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Text'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add Text'), findsOneWidget);
    expect(find.byTooltip('Properties'), findsOneWidget);
    expect(find.byTooltip('More'), findsOneWidget);

    await tester.tap(find.byTooltip('Properties'));
    await tester.pumpAndSettle();

    expect(find.text('Font size'), findsOneWidget);
  });

  testWidgets('selected element quick actions are tappable', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PosterEditor()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Text'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Font size'), findsOneWidget);
  });

  testWidgets('tapping the empty canvas clears selection', (tester) async {
    final controller = PosterController();
    final shape = controller.addShape(PosterShapeType.rectangle);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(
            controller: controller,
            onInteract: () => controller.select(null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.selectedElementId, shape.id);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(controller.selectedElementId, isNull);
  });

  testWidgets('selected element drag moves the element instead of the stage', (
    tester,
  ) async {
    final controller = PosterController();
    final shape = controller.addShape(PosterShapeType.rectangle);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = controller.selectedElement!.position;
    final dragStart =
        shape.position + Offset(shape.size.width / 2, shape.size.height / 2);
    await tester.dragFrom(dragStart, const Offset(60, 20));
    await tester.pumpAndSettle();

    expect(controller.selectedElement!.position.dx, greaterThan(before.dx));
    expect(controller.selectedElement!.position.dy, greaterThan(before.dy));
  });

  testWidgets('second tap on selected text edits it inline', (tester) async {
    final controller = PosterController();
    final text = controller.addText(text: 'Edit me');
    controller.select(null);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tapPoint =
        text.position + Offset(text.size.width / 2, text.size.height / 2);
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    expect(controller.selectedElementId, text.id);
    expect(find.byType(TextField), findsNothing);

    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Inline edit');
    await tester.pumpAndSettle();

    expect((controller.selectedElement! as TextElement).text, 'Inline edit');
  });

  testWidgets('selected element rotate handle changes rotation', (
    tester,
  ) async {
    final controller = PosterController();
    final shape = controller.addShape(PosterShapeType.rectangle);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = controller.selectedElement!.rotation;
    final handleCenter = Offset(
      shape.position.dx + shape.size.width / 2,
      shape.position.dy - 84,
    );
    await tester.dragFrom(handleCenter, const Offset(48, 0));
    await tester.pumpAndSettle();

    expect(controller.selectedElement!.rotation, greaterThan(before));
  });

  testWidgets('rotate handle stays smooth across the angle boundary', (
    tester,
  ) async {
    final controller = PosterController();
    final shape = controller.addShape(PosterShapeType.rectangle);
    controller.updateElement(shape.copyWith(rotation: math.pi * 1.5));

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = controller.selectedElement!.rotation;
    final center =
        shape.position + Offset(shape.size.width / 2, shape.size.height / 2);
    final handleCenter = center + const Offset(-139, 0);
    await tester.dragFrom(handleCenter, const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(controller.selectedElement!.rotation, greaterThan(before));
    expect(controller.selectedElement!.rotation - before, lessThan(math.pi));
  });

  testWidgets('selected element resize handle changes size', (tester) async {
    final controller = PosterController();
    final shape = controller.addShape(PosterShapeType.rectangle);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = controller.selectedElement!.size;
    final handleCenter = Offset(
      shape.position.dx + shape.size.width + 25,
      shape.position.dy + shape.size.height + 25,
    );
    await tester.dragFrom(handleCenter, const Offset(40, 30));
    await tester.pumpAndSettle();

    expect(controller.selectedElement!.size.width, greaterThan(before.width));
    expect(controller.selectedElement!.size.height, greaterThan(before.height));
  });

  testWidgets('keyboard delete removes selected element', (tester) async {
    final controller = PosterController();
    controller.addText(text: 'Delete me');

    await tester.pumpWidget(
      MaterialApp(home: PosterEditor(controller: controller)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(controller.document.elements, isEmpty);
  });

  testWidgets('exports only the mounted canvas as PNG bytes', (tester) async {
    final controller = PosterController();
    controller.addShape(PosterShapeType.rectangle);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 900,
          child: PosterCanvas(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final result = (await tester.runAsync(
      () => controller.exportPng(pixelRatio: 1),
    ))!;
    expect(result.bytes, isNotEmpty);
    expect(result.width, greaterThan(0));
    expect(result.height, greaterThan(0));
  });
}
