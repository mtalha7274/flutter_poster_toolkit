import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../controller/poster_controller.dart';
import '../models/poster_document.dart';
import '../models/poster_element.dart';
import 'poster_canvas.dart';

typedef PosterImagePicker = Future<Uint8List?> Function();
typedef PosterExportCallback = Future<void> Function(PosterExportResult result);

class PosterEditor extends StatefulWidget {
  const PosterEditor({
    super.key,
    this.controller,
    this.initialDocument,
    this.onPickImage,
    this.onExportPng,
  });

  final PosterController? controller;
  final PosterDocument? initialDocument;
  final PosterImagePicker? onPickImage;
  final PosterExportCallback? onExportPng;

  @override
  State<PosterEditor> createState() => _PosterEditorState();
}

class _PosterEditorState extends State<PosterEditor> {
  late final PosterController _controller;
  late final bool _ownsController;
  final FocusNode _focusNode = FocusNode();

  PosterController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        PosterController(
          document: widget.initialDocument ?? PosterDocument.empty(),
        );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Material(
            color: const Color(0xfff6f7fb),
            child: Column(
              children: [
                Expanded(child: _buildCanvasStage()),
                _Toolbar(
                  controller: controller,
                  onAddImage: _addImage,
                  onExport: _exportPng,
                  onProperties: _showPropertiesSheet,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final isShortcut =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      controller.deleteSelected();
      return KeyEventResult.handled;
    }
    if (isShortcut && event.logicalKey == LogicalKeyboardKey.keyD) {
      controller.duplicateSelected();
      return KeyEventResult.handled;
    }
    if (isShortcut && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        controller.redo();
      } else {
        controller.undo();
      }
      return KeyEventResult.handled;
    }
    if (isShortcut && event.logicalKey == LogicalKeyboardKey.keyY) {
      controller.redo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _addImage() async {
    final bytes = await widget.onPickImage?.call();
    controller.addImage(bytes: bytes);
  }

  Future<void> _exportPng() async {
    final result = await controller.exportPng();
    await widget.onExportPng?.call(result);
  }

  Future<void> _showPropertiesSheet() async {
    if (controller.selectedElement == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff8fafc),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxHeight = (screenHeight * 0.62).clamp(360, 620).toDouble();
        final maxChildSize = (maxHeight / screenHeight)
            .clamp(0.25, 1.0)
            .toDouble();
        final minChildSize = math.min(0.32, maxChildSize);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: maxChildSize,
          maxChildSize: maxChildSize,
          minChildSize: minChildSize,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) => _PropertiesPanel(
                controller: controller,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCanvasStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = controller.document.canvasSize;
        final availableSize = Size(
          math.max(120, constraints.maxWidth - 8),
          math.max(120, constraints.maxHeight - 8),
        );
        final scale = math.min(
          availableSize.width / canvasSize.width,
          availableSize.height / canvasSize.height,
        );
        final scaledSize = Size(
          canvasSize.width * scale,
          canvasSize.height * scale,
        );
        return Container(
          color: const Color(0xfff6f7fb),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.select(null),
            child: CustomPaint(
              painter: const _StageDotsPainter(),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: SizedBox(
                      width: scaledSize.width,
                      height: scaledSize.height,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: canvasSize.width,
                        maxWidth: canvasSize.width,
                        minHeight: canvasSize.height,
                        maxHeight: canvasSize.height,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: PosterCanvas(
                            controller: controller,
                            interactionScale: scale,
                            onInteract: () => controller.select(null),
                            onMorePressed: _showPropertiesSheet,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StageDotsPainter extends CustomPainter {
  const _StageDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = const Color(0xffd6dae3)
      ..style = PaintingStyle.fill;

    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StageDotsPainter oldDelegate) => false;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.onAddImage,
    required this.onExport,
    required this.onProperties,
  });

  final PosterController controller;
  final VoidCallback onAddImage;
  final VoidCallback onExport;
  final VoidCallback onProperties;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff111827),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                _ToolButton(
                  tooltip: 'Add Text',
                  icon: Icons.title,
                  onPressed: () => controller.addText(),
                ),
                _ToolButton(
                  tooltip: 'Add Image',
                  icon: Icons.image,
                  onPressed: onAddImage,
                ),
                _ToolButton(
                  tooltip: 'Add Rectangle',
                  icon: Icons.crop_square,
                  onPressed: () =>
                      controller.addShape(PosterShapeType.rectangle),
                ),
                _ToolButton(
                  tooltip: 'Add Circle',
                  icon: Icons.circle_outlined,
                  onPressed: () => controller.addShape(PosterShapeType.circle),
                ),
                _ToolButton(
                  tooltip: 'Add Line',
                  icon: Icons.horizontal_rule,
                  onPressed: () => controller.addShape(PosterShapeType.line),
                ),
                _ToolButton(
                  tooltip: 'Add Triangle',
                  icon: Icons.change_history,
                  onPressed: () =>
                      controller.addShape(PosterShapeType.triangle),
                ),
                const _ToolbarDivider(),
                _ToolButton(
                  tooltip: 'Properties',
                  icon: Icons.tune,
                  onPressed: controller.selectedElement == null
                      ? null
                      : onProperties,
                ),
                _ToolButton(
                  tooltip: 'Duplicate',
                  icon: Icons.copy,
                  onPressed: controller.selectedElement == null
                      ? null
                      : controller.duplicateSelected,
                ),
                _ToolButton(
                  tooltip: 'Delete',
                  icon: Icons.delete,
                  onPressed: controller.selectedElement == null
                      ? null
                      : controller.deleteSelected,
                ),
                const _ToolbarDivider(),
                _ToolButton(
                  tooltip: 'Undo',
                  icon: Icons.undo,
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                _ToolButton(
                  tooltip: 'Redo',
                  icon: Icons.redo,
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                const _ToolbarDivider(),
                _ToolButton(
                  tooltip: 'Export PNG',
                  icon: Icons.download,
                  onPressed: onExport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0x33ffffff),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        verticalOffset: 30,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xff1f2937),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xff1f2937),
            disabledForegroundColor: const Color(0xff6b7280),
            fixedSize: const Size(50, 50),
          ),
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({required this.controller, this.scrollController});

  final PosterController controller;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final element = controller.selectedElement;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: element == null
          ? const Center(
              child: Text(
                'No element selected',
                style: TextStyle(color: Color(0xff6b7280)),
              ),
            )
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xff111827),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFor(element), color: Colors.white),
                  ),
                  title: Text(
                    _titleFor(element),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xff111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Adjust style and arrangement'),
                  trailing: IconButton.filledTonal(
                    tooltip: element.locked ? 'Unlock' : 'Lock',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(44, 44),
                      backgroundColor: const Color(0xffe5e7eb),
                      foregroundColor: const Color(0xff111827),
                    ),
                    onPressed: controller.toggleSelectedLock,
                    icon: Icon(element.locked ? Icons.lock : Icons.lock_open),
                  ),
                ),
                const SizedBox(height: 12),
                _PropertySection(
                  title: 'Basics',
                  child: _CommonProperties(
                    controller: controller,
                    element: element,
                  ),
                ),
                _PropertySection(
                  title: _sectionTitleFor(element),
                  child: switch (element) {
                    TextElement() => _TextProperties(
                      controller: controller,
                      element: element,
                    ),
                    ImageElement() => _ImageProperties(
                      controller: controller,
                      element: element,
                    ),
                    ShapeElement() => _ShapeProperties(
                      controller: controller,
                      element: element,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
                _PropertySection(
                  title: 'Layers',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _LayerButton(
                        onPressed: controller.sendToBack,
                        icon: Icons.vertical_align_bottom,
                        label: 'Back',
                      ),
                      _LayerButton(
                        onPressed: controller.sendBackward,
                        icon: Icons.arrow_downward,
                        label: 'Lower',
                      ),
                      _LayerButton(
                        onPressed: controller.bringForward,
                        icon: Icons.arrow_upward,
                        label: 'Raise',
                      ),
                      _LayerButton(
                        onPressed: controller.bringToFront,
                        icon: Icons.vertical_align_top,
                        label: 'Front',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _titleFor(PosterElement element) {
    return switch (element) {
      TextElement() => 'Text',
      ImageElement() => 'Image',
      ShapeElement element =>
        '${element.shape.name[0].toUpperCase()}${element.shape.name.substring(1)}',
      _ => 'Element',
    };
  }

  IconData _iconFor(PosterElement element) {
    return switch (element) {
      TextElement() => Icons.title,
      ImageElement() => Icons.image,
      ShapeElement element => switch (element.shape) {
        PosterShapeType.rectangle => Icons.crop_square,
        PosterShapeType.circle => Icons.circle_outlined,
        PosterShapeType.line => Icons.horizontal_rule,
        PosterShapeType.triangle => Icons.change_history,
      },
      _ => Icons.category,
    };
  }

  String _sectionTitleFor(PosterElement element) {
    return switch (element) {
      TextElement() => 'Text',
      ImageElement() => 'Image',
      ShapeElement() => 'Shape',
      _ => 'Style',
    };
  }
}

class _PropertySection extends StatelessWidget {
  const _PropertySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xff374151),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LayerButton extends StatelessWidget {
  const _LayerButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(116, 46),
        backgroundColor: const Color(0xfff3f4f6),
        foregroundColor: const Color(0xff111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _CommonProperties extends StatelessWidget {
  const _CommonProperties({required this.controller, required this.element});

  final PosterController controller;
  final PosterElement element;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderProperty(
          label: 'Opacity',
          value: element.opacity,
          min: 0,
          max: 1,
          onChanged: (value) =>
              controller.updateElement(element.copyWithBase(opacity: value)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TogglePropertyButton(
                selected: element.flipX,
                icon: Icons.flip,
                label: 'Flip H',
                onPressed: () => controller.updateElement(
                  element.copyWithBase(flipX: !element.flipX),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TogglePropertyButton(
                selected: element.flipY,
                icon: Icons.flip,
                label: 'Flip V',
                onPressed: () => controller.updateElement(
                  element.copyWithBase(flipY: !element.flipY),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TogglePropertyButton extends StatelessWidget {
  const _TogglePropertyButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: selected ? const Color(0xff111827) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xff111827),
        side: BorderSide(
          color: selected ? const Color(0xff111827) : const Color(0xffd1d5db),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _TextProperties extends StatelessWidget {
  const _TextProperties({required this.controller, required this.element});

  final PosterController controller;
  final TextElement element;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('text-${element.id}-${element.text}'),
          initialValue: element.text,
          minLines: 2,
          maxLines: 4,
          decoration: _posterInputDecoration('Content'),
          onChanged: (value) =>
              controller.updateElement(element.copyWith(text: value)),
        ),
        _SliderProperty(
          label: 'Font size',
          value: element.fontSize,
          min: 8,
          max: 140,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(fontSize: value)),
        ),
        DropdownButtonFormField<String>(
          initialValue: element.fontFamily,
          decoration: _posterInputDecoration('Font family'),
          items:
              const ['Roboto', 'Oswald', 'Montserrat', 'Inter', 'Merriweather']
                  .map(
                    (font) => DropdownMenuItem(value: font, child: Text(font)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.updateElement(element.copyWith(fontFamily: value));
            }
          },
        ),
        DropdownButtonFormField<FontWeight>(
          initialValue: element.fontWeight,
          decoration: _posterInputDecoration('Weight'),
          items: const [
            DropdownMenuItem(value: FontWeight.normal, child: Text('Regular')),
            DropdownMenuItem(value: FontWeight.w600, child: Text('Semi bold')),
            DropdownMenuItem(value: FontWeight.bold, child: Text('Bold')),
            DropdownMenuItem(value: FontWeight.w900, child: Text('Black')),
          ],
          onChanged: (value) {
            if (value != null) {
              controller.updateElement(element.copyWith(fontWeight: value));
            }
          },
        ),
        Row(
          children: [
            Expanded(
              child: _LabeledCheckbox(
                label: 'Italic',
                value: element.italic,
                onChanged: (value) => controller.updateElement(
                  element.copyWith(italic: value ?? false),
                ),
              ),
            ),
            Expanded(
              child: _LabeledCheckbox(
                label: 'Underline',
                value: element.underline,
                onChanged: (value) => controller.updateElement(
                  element.copyWith(underline: value ?? false),
                ),
              ),
            ),
          ],
        ),
        _ColorProperty(
          label: 'Text color',
          color: element.color,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(color: value)),
        ),
        DropdownButtonFormField<TextAlign>(
          initialValue: element.alignment,
          decoration: _posterInputDecoration('Alignment'),
          items: const [
            DropdownMenuItem(value: TextAlign.left, child: Text('Left')),
            DropdownMenuItem(value: TextAlign.center, child: Text('Center')),
            DropdownMenuItem(value: TextAlign.right, child: Text('Right')),
          ],
          onChanged: (value) {
            if (value != null) {
              controller.updateElement(element.copyWith(alignment: value));
            }
          },
        ),
        _SliderProperty(
          label: 'Letter spacing',
          value: element.letterSpacing,
          min: 0,
          max: 12,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(letterSpacing: value)),
        ),
      ],
    );
  }
}

class _ImageProperties extends StatelessWidget {
  const _ImageProperties({required this.controller, required this.element});

  final PosterController controller;
  final ImageElement element;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderProperty(
          label: 'Corner radius',
          value: element.cornerRadius,
          min: 0,
          max: 80,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(cornerRadius: value)),
        ),
        DropdownButtonFormField<PosterImageFit>(
          initialValue: element.fit,
          decoration: _posterInputDecoration('Fit'),
          items: const [
            DropdownMenuItem(value: PosterImageFit.cover, child: Text('Cover')),
            DropdownMenuItem(
              value: PosterImageFit.contain,
              child: Text('Contain'),
            ),
            DropdownMenuItem(value: PosterImageFit.fill, child: Text('Fill')),
          ],
          onChanged: (value) {
            if (value != null) {
              controller.updateElement(element.copyWith(fit: value));
            }
          },
        ),
      ],
    );
  }
}

class _ShapeProperties extends StatelessWidget {
  const _ShapeProperties({required this.controller, required this.element});

  final PosterController controller;
  final ShapeElement element;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColorProperty(
          label: 'Fill color',
          color: element.fillColor,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(fillColor: value)),
        ),
        _ColorProperty(
          label: 'Stroke color',
          color: element.strokeColor,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(strokeColor: value)),
        ),
        _SliderProperty(
          label: 'Stroke width',
          value: element.strokeWidth,
          min: 0,
          max: 24,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(strokeWidth: value)),
        ),
        if (element.shape == PosterShapeType.rectangle)
          _SliderProperty(
            label: 'Border radius',
            value: element.borderRadius,
            min: 0,
            max: 80,
            onChanged: (value) =>
                controller.updateElement(element.copyWith(borderRadius: value)),
          ),
      ],
    );
  }
}

class _LabeledCheckbox extends StatelessWidget {
  const _LabeledCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ColorProperty extends StatelessWidget {
  const _ColorProperty({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final pickerColor = color.a == 0 ? const Color(0xffff8a00) : color;
          var nextColor = pickerColor;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(label),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (value) => nextColor = value,
                  enableAlpha: true,
                  displayThumbColor: true,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(nextColor);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffe5e7eb), width: 2),
          ),
        ),
      ),
    );
  }
}

class _SliderProperty extends StatelessWidget {
  const _SliderProperty({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xfff3f4f6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  value.toStringAsFixed(value.abs() < 10 ? 1 : 0),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

InputDecoration _posterInputDecoration(String hintText) {
  const borderRadius = BorderRadius.all(Radius.circular(14));
  const borderSide = BorderSide(color: Color(0xffd1d5db));
  return const InputDecoration(
    filled: true,
    fillColor: Color(0xfff9fafb),
    hintStyle: TextStyle(color: Color(0xff9ca3af)),
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Color(0xff2563eb), width: 1.6),
    ),
  ).copyWith(hintText: hintText);
}
