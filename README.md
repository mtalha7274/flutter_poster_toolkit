# flutter_poster

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

The example uses `image_picker` for image selection and `image_gallery_saver_plus` for PNG export.

## Package Dependencies

- `uuid`: stable IDs for poster elements.
- `equatable`: value equality for document and element models.
- `flutter_colorpicker`: color editing in the bottom-sheet properties editor.
- `google_fonts`: font selection for text elements.

The package does not open pickers or save files directly. Host apps provide those behaviors through callbacks.

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
