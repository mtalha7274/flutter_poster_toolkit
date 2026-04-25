# flutter_poster

A reusable Flutter poster editor package for building editable flyer and poster experiences in Android and iOS apps. It ships with an interactive editor widget, document/controller APIs, editable text/image/shape elements, undo/redo, keyboard shortcuts, and high-quality PNG export of the poster canvas only.

The included example app demonstrates a fully editable lost-cat poster layout. The poster is made from real editor elements, not a static image.

## Features

- Adjustable poster canvas with visible editor bounds, centered layout, zoom controls, and fit-to-screen.
- Mobile-first editor shell with a top app bar and collapsible tool drawer.
- Editable element types: text, images, rectangles, circles, lines, and triangles.
- Drag, resize, rotate, select, lock, duplicate, delete, and layer ordering actions.
- Inline selected-element quick actions for duplicate, delete, and opening more options.
- Bottom-sheet properties editor for text, image, and shape styling.
- Undo/redo history and keyboard shortcuts where supported.
- PNG export through a canvas-only `RepaintBoundary`.
- Reusable package API with platform-specific image picking and file saving left to host apps.

JSON save/load and JPEG export are intentionally not included in this version.

## Getting Started

Add the package to your app:

```yaml
dependencies:
  flutter_poster:
    path: path/to/flutter_poster
```

Then use the editor:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_poster/flutter_poster.dart';

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

## Example App

Run the example:

```sh
cd example
flutter run
```

The example uses:

- `image_picker` to select image bytes for image elements.
- `file_saver` to save PNG exports across supported platforms.

## Package Dependencies

- `uuid`: stable IDs for poster elements.
- `equatable`: value equality for document and element models.
- `flutter_colorpicker`: color editing in the bottom-sheet properties editor.
- `google_fonts`: convenient font selection for text elements.

The core package does not directly save files or open image-picking dialogs. Host apps provide those behaviors through callbacks, which keeps the editor reusable across Android and iOS apps.

## Public API

- `PosterEditor`: complete editor UI.
- `PosterCanvas`: renderable poster canvas widget.
- `PosterController`: document state, selection, history, transforms, actions, and PNG export.
- `PosterDocument`: canvas size, background color, and ordered elements.
- `TextElement`, `ImageElement`, `ShapeElement`: editable poster element models.
- `PosterExportResult`: PNG bytes and rendered dimensions.

## Verification

```sh
flutter pub get
flutter analyze
flutter test

cd example
flutter pub get
flutter analyze
flutter test
```
