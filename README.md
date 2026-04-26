# flutter_poster_toolkit

A reusable Flutter poster editor for Android and iOS apps. It includes an interactive editor, editable text/image/shape elements, undo/redo, and PNG export of the poster canvas.

<p align="center">
  <img src="https://s13.gifyu.com/images/bqJQJ.jpg" alt="flutter_poster_toolkit demo" />
</p>

## Getting Started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_poster_toolkit/flutter_poster_toolkit.dart';

class PosterScreen extends StatefulWidget {
  const PosterScreen({super.key});

  @override
  State<PosterScreen> createState() => _PosterScreenState();
}

class _PosterScreenState extends State<PosterScreen> {
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
