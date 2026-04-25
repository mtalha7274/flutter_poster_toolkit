import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

import '../models/poster_document.dart';
import '../models/poster_element.dart';

class PosterExportResult {
  const PosterExportResult({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class PosterController extends ChangeNotifier {
  PosterController({PosterDocument? document, Uuid? uuid})
    : _document = document ?? PosterDocument.empty(),
      _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final GlobalKey canvasKey = GlobalKey(debugLabel: 'poster-canvas-export');
  final ScreenshotController screenshotController = ScreenshotController();
  final List<PosterDocument> _undoStack = [];
  final List<PosterDocument> _redoStack = [];

  PosterDocument _document;
  String? _selectedElementId;
  PosterDocument? _interactionSnapshot;

  PosterDocument get document => _document;
  String? get selectedElementId => _selectedElementId;
  PosterElement? get selectedElement =>
      _document.elementById(_selectedElementId);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void replaceDocument(PosterDocument document) {
    _recordHistory();
    _document = _constrainDocument(document);
    _selectedElementId = null;
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    final safeSize = Size(
      size.width.clamp(120, 4000).toDouble(),
      size.height.clamp(120, 4000).toDouble(),
    );
    _recordHistory();
    _document = _constrainDocument(_document.copyWith(canvasSize: safeSize));
    notifyListeners();
  }

  void select(String? id) {
    if (_selectedElementId == id) {
      return;
    }
    _selectedElementId = id;
    notifyListeners();
  }

  TextElement addText({
    String text = 'New text',
    Offset position = const Offset(80, 80),
    Size size = const Size(240, 80),
  }) {
    final element = TextElement(
      id: _uuid.v4(),
      position: position,
      size: size,
      text: text,
    );
    _addElement(element);
    return element;
  }

  ImageElement addImage({
    Uint8List? bytes,
    Offset position = const Offset(80, 160),
    Size size = const Size(260, 220),
  }) {
    final element = ImageElement(
      id: _uuid.v4(),
      position: position,
      size: size,
      bytes: bytes,
      cornerRadius: 10,
    );
    _addElement(element);
    return element;
  }

  ShapeElement addShape(
    PosterShapeType shape, {
    Offset position = const Offset(90, 120),
    Size size = const Size(180, 110),
  }) {
    final element = ShapeElement(
      id: _uuid.v4(),
      position: position,
      size: shape == PosterShapeType.line ? const Size(220, 16) : size,
      shape: shape,
    );
    _addElement(element);
    return element;
  }

  void updateElement(PosterElement element, {bool recordHistory = true}) {
    final index = _document.elements.indexWhere(
      (item) => item.id == element.id,
    );
    if (index == -1) {
      return;
    }
    if (recordHistory) {
      _recordHistory();
    }
    final updated = List<PosterElement>.of(_document.elements);
    updated[index] = _constrainElement(element);
    _document = _document.copyWith(elements: updated);
    if (_selectedElementId == element.id) {
      _selectedElementId = element.id;
    }
    notifyListeners();
  }

  void beginInteraction() {
    _interactionSnapshot ??= _document;
  }

  void endInteraction() {
    final snapshot = _interactionSnapshot;
    _interactionSnapshot = null;
    if (snapshot == null || snapshot == _document) {
      return;
    }
    _undoStack.add(snapshot);
    _redoStack.clear();
    notifyListeners();
  }

  void cancelInteraction() {
    final snapshot = _interactionSnapshot;
    _interactionSnapshot = null;
    if (snapshot == null) {
      return;
    }
    _document = snapshot;
    notifyListeners();
  }

  void moveSelected(Offset delta) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    beginInteraction();
    updateElement(
      element.copyWithBase(position: element.position + delta),
      recordHistory: false,
    );
  }

  void resizeSelected(Offset delta) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    beginInteraction();
    updateElement(
      element.copyWithBase(
        size: Size(
          (element.size.width + delta.dx).clamp(12, _document.canvasSize.width),
          (element.size.height + delta.dy).clamp(
            12,
            _document.canvasSize.height,
          ),
        ),
      ),
      recordHistory: false,
    );
  }

  void rotateSelected(double radiansDelta) {
    final element = selectedElement;
    if (element == null || element.locked) {
      return;
    }
    beginInteraction();
    updateElement(
      element.copyWithBase(rotation: element.rotation + radiansDelta),
      recordHistory: false,
    );
  }

  void duplicateSelected() {
    final element = selectedElement;
    if (element == null) {
      return;
    }
    final duplicated = _copyWithId(
      element.copyWithBase(position: element.position + const Offset(24, 24)),
      _uuid.v4(),
    );
    _addElement(duplicated);
  }

  void deleteSelected() {
    final id = selectedElementId;
    if (id == null) {
      return;
    }
    _recordHistory();
    _document = _document.copyWith(
      elements: _document.elements
          .where((element) => element.id != id)
          .toList(),
    );
    _selectedElementId = null;
    notifyListeners();
  }

  void toggleSelectedLock() {
    final element = selectedElement;
    if (element == null) {
      return;
    }
    updateElement(element.copyWithBase(locked: !element.locked));
  }

  void bringForward() => _moveSelectedLayer(1);

  void sendBackward() => _moveSelectedLayer(-1);

  void bringToFront() => _moveSelectedLayer(_document.elements.length);

  void sendToBack() => _moveSelectedLayer(-_document.elements.length);

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    _redoStack.add(_document);
    _document = _undoStack.removeLast();
    if (_document.elementById(_selectedElementId) == null) {
      _selectedElementId = null;
    }
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    _undoStack.add(_document);
    _document = _redoStack.removeLast();
    if (_document.elementById(_selectedElementId) == null) {
      _selectedElementId = null;
    }
    notifyListeners();
  }

  Future<PosterExportResult> exportPng({double pixelRatio = 3}) async {
    final bytes = await screenshotController.capture(pixelRatio: pixelRatio);
    if (bytes == null) {
      throw StateError('Unable to encode poster PNG.');
    }
    return PosterExportResult(
      bytes: bytes,
      width: (_document.canvasSize.width * pixelRatio).round(),
      height: (_document.canvasSize.height * pixelRatio).round(),
    );
  }

  void _addElement(PosterElement element) {
    _recordHistory();
    final constrained = _constrainElement(element);
    _document = _document.copyWith(
      elements: [..._document.elements, constrained],
    );
    _selectedElementId = constrained.id;
    notifyListeners();
  }

  void _moveSelectedLayer(int delta) {
    final id = selectedElementId;
    if (id == null) {
      return;
    }
    final elements = List<PosterElement>.of(_document.elements);
    final current = elements.indexWhere((element) => element.id == id);
    if (current == -1) {
      return;
    }
    final target = (current + delta).clamp(0, elements.length - 1);
    if (target == current) {
      return;
    }
    _recordHistory();
    final item = elements.removeAt(current);
    elements.insert(target, item);
    _document = _document.copyWith(elements: elements);
    notifyListeners();
  }

  PosterDocument _constrainDocument(PosterDocument document) {
    return document.copyWith(
      elements: document.elements
          .map(
            (element) =>
                _constrainElement(element, canvasSize: document.canvasSize),
          )
          .toList(),
    );
  }

  PosterElement _constrainElement(PosterElement element, {Size? canvasSize}) {
    final canvas = canvasSize ?? _document.canvasSize;
    final size = Size(
      element.size.width.clamp(12, canvas.width).toDouble(),
      element.size.height.clamp(12, canvas.height).toDouble(),
    );
    final position = _clampPosition(element, size, canvas);
    return element.copyWithBase(position: position, size: size);
  }

  Offset _clampPosition(PosterElement element, Size size, Size canvas) {
    final angle = element.rotation;
    final cosA = math.cos(angle).abs();
    final sinA = math.sin(angle).abs();
    final rotatedWidth = size.width * cosA + size.height * sinA;
    final rotatedHeight = size.width * sinA + size.height * cosA;
    final halfWidth = math.min(rotatedWidth / 2, canvas.width / 2);
    final halfHeight = math.min(rotatedHeight / 2, canvas.height / 2);
    final center = element.position + Offset(size.width / 2, size.height / 2);
    final clampedCenter = Offset(
      center.dx.clamp(halfWidth, canvas.width - halfWidth).toDouble(),
      center.dy.clamp(halfHeight, canvas.height - halfHeight).toDouble(),
    );
    return clampedCenter - Offset(size.width / 2, size.height / 2);
  }

  PosterElement _copyWithId(PosterElement element, String id) {
    return switch (element) {
      TextElement() => element.copyWith(id: id),
      ImageElement() => element.copyWith(id: id),
      ShapeElement() => element.copyWith(id: id),
      _ => element,
    };
  }

  void _recordHistory() {
    _undoStack.add(_document);
    _redoStack.clear();
  }
}
