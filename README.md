# flutter_poster_toolkit

A reusable Flutter poster editor for Android and iOS apps. It includes an interactive editor, editable text/image/shape elements, undo/redo, and PNG export of the poster canvas.

## Features

- Centered poster canvas with a dotted editor background.
- Mobile-first editor shell with a bottom toolbar.
- Editable element types: text, images, rectangles, circles, lines, and triangles.
- Drag, resize, rotate, select, lock, duplicate, delete, and layer ordering actions.
- Inline text editing on the canvas.
- Quick actions and draggable bottom-sheet properties.
- Undo/redo history and keyboard shortcuts where supported.
- Canvas-only PNG export.
- Host-provided image picking and export saving.

## Getting Started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_poster_toolkit/flutter_poster.dart';

class PosterScreen extends StatefulWidget {
  const PosterScreen({super.key});

  @override
  State<PosterScreen> createState() => _PosterScreenState();
}

class _PosterScreenState extends State<PosterScreen> {/
  final controller = PosterController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PosterEditor(
      controller: controller,
      onPickImage: () async {
        // Return image bytes from your app's picker.
        return null;
      },
      onExportPng: (result) async {
        // Save, share, upload, or preview result.bytes.
      },
    );
  }
}
```

## Public API

- `PosterEditor`: complete editor UI.
- `PosterCanvas`: renderable poster canvas widget.
- `PosterController`: document state, selection, history, transforms, actions, and PNG export.
- `PosterDocument`: canvas size, background color, and ordered elements.
- `TextElement`, `ImageElement`, `ShapeElement`: editable poster element models.
- `PosterExportResult`: PNG bytes and rendered dimensions.
