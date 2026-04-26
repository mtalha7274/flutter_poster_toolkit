import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../controller/poster_controller.dart';
import '../models/poster_document.dart';
import '../models/poster_element.dart';
import '../theme/poster_editor_theme.dart';
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
    this.theme = const PosterEditorTheme(),
  });

  final PosterController? controller;
  final PosterDocument? initialDocument;
  final PosterImagePicker? onPickImage;
  final PosterExportCallback? onExportPng;
  final PosterEditorTheme theme;

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
    final theme = widget.theme;
    final toolbarLuminance = theme.toolbar.backgroundColor.computeLuminance();
    return PosterEditorThemeScope(
      theme: theme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: theme.toolbar.backgroundColor,
          systemNavigationBarDividerColor: theme.toolbar.backgroundColor,
          systemNavigationBarIconBrightness: toolbarLuminance > 0.5
              ? Brightness.dark
              : Brightness.light,
        ),
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Material(
                color: theme.stage.scaffoldBackgroundColor,
                child: Column(
                  children: [
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: _buildCanvasStage(theme),
                      ),
                    ),
                    _Toolbar(
                      theme: theme,
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
        ),
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
    if (bytes == null) {
      return;
    }
    final size = await _sizeForImage(bytes);
    controller.addImage(bytes: bytes, size: size);
  }

  Future<Size> _sizeForImage(Uint8List bytes) async {
    final maxSize = widget.theme.imports.maxImageSize;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final aspectRatio = image.width / image.height;
      image.dispose();
      final maxAspectRatio = maxSize.width / maxSize.height;
      if (aspectRatio >= maxAspectRatio) {
        return Size(maxSize.width, maxSize.width / aspectRatio);
      }
      return Size(maxSize.height * aspectRatio, maxSize.height);
    } catch (_) {
      return maxSize;
    }
  }

  Future<void> _exportPng() async {
    final result = await controller.exportPng();
    await widget.onExportPng?.call(result);
  }

  Future<void> _showPropertiesSheet() async {
    if (controller.selectedElement == null) {
      return;
    }
    final theme = widget.theme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: theme.properties.sheetBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.properties.topCornerRadius),
        ),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxHeight = (screenHeight * 0.62).clamp(360, 620).toDouble();
        final maxChildSize = (maxHeight / screenHeight)
            .clamp(0.25, 1.0)
            .toDouble();
        final minChildSize = math.min(0.32, maxChildSize);
        return PosterEditorThemeScope(
          theme: theme,
          child: DraggableScrollableSheet(
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
          ),
        );
      },
    );
  }

  Widget _buildCanvasStage(PosterEditorTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = controller.document.canvasSize;
        final inset = theme.stage.canvasInset;
        final availableSize = Size(
          math.max(120, constraints.maxWidth - inset),
          math.max(120, constraints.maxHeight - inset),
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
          color: theme.stage.scaffoldBackgroundColor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.select(null),
            child: CustomPaint(
              painter: _StageDotsPainter(stage: theme.stage),
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
  const _StageDotsPainter({required this.stage});

  final PosterStageTheme stage;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = stage.dotSpacing;
    final paint = Paint()
      ..color = stage.dotColor
      ..style = PaintingStyle.fill;

    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), stage.dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StageDotsPainter oldDelegate) =>
      oldDelegate.stage != stage;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.theme,
    required this.controller,
    required this.onAddImage,
    required this.onExport,
    required this.onProperties,
  });

  final PosterEditorTheme theme;
  final PosterController controller;
  final VoidCallback onAddImage;
  final VoidCallback onExport;
  final VoidCallback onProperties;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.toolbar.backgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: theme.toolbar.height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: theme.toolbar.horizontalPadding,
              vertical: theme.toolbar.verticalPadding,
            ),
            child: Row(
              children: [
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Text',
                  icon: Icons.title,
                  onPressed: () => controller.addText(),
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Image',
                  icon: Icons.image,
                  onPressed: onAddImage,
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Rectangle',
                  icon: Icons.crop_square,
                  onPressed: () =>
                      controller.addShape(PosterShapeType.rectangle),
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Circle',
                  icon: Icons.circle_outlined,
                  onPressed: () => controller.addShape(PosterShapeType.circle),
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Line',
                  icon: Icons.horizontal_rule,
                  onPressed: () => controller.addShape(PosterShapeType.line),
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Add Triangle',
                  icon: Icons.change_history,
                  onPressed: () =>
                      controller.addShape(PosterShapeType.triangle),
                ),
                _ToolbarDivider(theme: theme),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Properties',
                  icon: Icons.tune,
                  onPressed: controller.selectedElement == null
                      ? null
                      : onProperties,
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Duplicate',
                  icon: Icons.copy,
                  onPressed: controller.selectedElement == null
                      ? null
                      : controller.duplicateSelected,
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Delete',
                  icon: Icons.delete,
                  onPressed: controller.selectedElement == null
                      ? null
                      : controller.deleteSelected,
                ),
                _ToolbarDivider(theme: theme),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Undo',
                  icon: Icons.undo,
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                _ToolButton(
                  theme: theme,
                  tooltip: 'Redo',
                  icon: Icons.redo,
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                _ToolbarDivider(theme: theme),
                _ToolButton(
                  theme: theme,
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
  const _ToolbarDivider({required this.theme});

  final PosterEditorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: theme.toolbar.dividerWidth,
      height: theme.toolbar.dividerHeight,
      margin: EdgeInsets.symmetric(
        horizontal: theme.toolbar.dividerHorizontalMargin,
      ),
      color: theme.toolbar.dividerColor,
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final PosterEditorTheme theme;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.toolbar.toolButtonHorizontalPadding,
      ),
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        verticalOffset: 30,
        textStyle: TextStyle(
          color: theme.tooltip.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: BoxDecoration(
          color: theme.tooltip.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: theme.toolbar.toolButtonBackgroundColor,
            foregroundColor: theme.toolbar.toolButtonForegroundColor,
            disabledBackgroundColor: theme.toolbar.toolButtonBackgroundColor,
            disabledForegroundColor:
                theme.toolbar.toolButtonDisabledForegroundColor,
            fixedSize: Size(
              theme.toolbar.toolButtonSize,
              theme.toolbar.toolButtonSize,
            ),
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
    final theme = PosterEditorThemeScope.of(context);
    final element = controller.selectedElement;
    return Container(
      decoration: BoxDecoration(
        color: theme.properties.panelBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.properties.topCornerRadius),
        ),
      ),
      child: element == null
          ? Center(
              child: Text(
                'No element selected',
                style: TextStyle(color: theme.properties.emptyTextColor),
              ),
            )
          : ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                theme.properties.listHorizontalPadding,
                0,
                theme.properties.listHorizontalPadding,
                theme.properties.listBottomPadding,
              ),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: theme.properties.headerLeadingSize,
                    height: theme.properties.headerLeadingSize,
                    decoration: BoxDecoration(
                      color: theme.properties.headerIconBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        theme.properties.headerLeadingRadius,
                      ),
                    ),
                    child: Icon(
                      _iconFor(element),
                      color: theme.properties.headerIconForegroundColor,
                    ),
                  ),
                  title: Text(
                    _titleFor(element),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: theme.properties.titleTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Adjust style and arrangement'),
                  trailing: IconButton.filledTonal(
                    tooltip: element.locked ? 'Unlock' : 'Lock',
                    style: IconButton.styleFrom(
                      fixedSize: Size(
                        theme.properties.lockButtonSize,
                        theme.properties.lockButtonSize,
                      ),
                      backgroundColor:
                          theme.properties.lockButtonBackgroundColor,
                      foregroundColor:
                          theme.properties.lockButtonForegroundColor,
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
    final theme = PosterEditorThemeScope.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.propertyCard.sectionSpacing),
      padding: EdgeInsets.all(theme.propertyCard.innerPadding),
      decoration: BoxDecoration(
        color: theme.propertyCard.backgroundColor,
        borderRadius: BorderRadius.circular(theme.propertyCard.borderRadius),
        border: Border.all(color: theme.propertyCard.borderColor),
        boxShadow: [theme.propertyCard.boxShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: theme.propertyCard.sectionTitleColor,
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
    final theme = PosterEditorThemeScope.of(context);
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: Size(theme.layerButton.minWidth, theme.layerButton.height),
        backgroundColor: theme.layerButton.backgroundColor,
        foregroundColor: theme.layerButton.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.layerButton.borderRadius),
        ),
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
                iconTurns: 1,
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
    this.iconTurns = 0,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final int iconTurns;

  @override
  Widget build(BuildContext context) {
    final theme = PosterEditorThemeScope.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(theme.toggleButton.minHeight),
        backgroundColor: selected
            ? theme.toggleButton.selectedBackgroundColor
            : theme.toggleButton.unselectedBackgroundColor,
        foregroundColor: selected
            ? theme.toggleButton.selectedForegroundColor
            : theme.toggleButton.unselectedForegroundColor,
        side: BorderSide(
          color: selected
              ? theme.toggleButton.selectedBackgroundColor
              : theme.toggleButton.unselectedBorderColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.toggleButton.borderRadius),
        ),
      ),
      onPressed: onPressed,
      icon: RotatedBox(quarterTurns: iconTurns, child: Icon(icon)),
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
    final theme = PosterEditorThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SliderProperty(
          label: 'Font size',
          value: element.fontSize,
          min: 8,
          max: 140,
          onChanged: (value) =>
              controller.updateElement(element.copyWith(fontSize: value)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: element.fontFamily,
          decoration: posterInputDecoration(theme.input, 'Font family'),
          items:
              const [
                    'Roboto',
                    'Inter',
                    'Nunito',
                    'Quicksand',
                    'Comic Neue',
                    'Fredoka',
                    'Baloo 2',
                    'DynaPuff',
                    'Caveat',
                    'Pacifico',
                    'Lobster',
                    'Oswald',
                    'Montserrat',
                    'Merriweather',
                  ]
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
        const SizedBox(height: 12),
        DropdownButtonFormField<FontWeight>(
          initialValue: element.fontWeight,
          decoration: posterInputDecoration(theme.input, 'Weight'),
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
          decoration: posterInputDecoration(theme.input, 'Alignment'),
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
    final theme = PosterEditorThemeScope.of(context);
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
          decoration: posterInputDecoration(theme.input, 'Fit'),
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
    final theme = PosterEditorThemeScope.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final pickerColor = color.a == 0 ? const Color(0xffff8a00) : color;
          final sheetTheme = PosterEditorThemeScope.of(context);
          final nextColor = await showDialog<Color>(
            context: context,
            builder: (context) => PosterEditorThemeScope(
              theme: sheetTheme,
              child: _HexColorPickerDialog(
                label: label,
                initialColor: pickerColor,
              ),
            ),
          );
          if (nextColor != null) {
            onChanged(nextColor);
          }
        },
        child: Container(
          width: theme.colorSwatch.size,
          height: theme.colorSwatch.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorSwatch.borderColor,
              width: theme.colorSwatch.borderWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexColorPickerDialog extends StatefulWidget {
  const _HexColorPickerDialog({
    required this.label,
    required this.initialColor,
  });

  final String label;
  final Color initialColor;

  @override
  State<_HexColorPickerDialog> createState() => _HexColorPickerDialogState();
}

class _HexColorPickerDialogState extends State<_HexColorPickerDialog> {
  late Color _color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
    _hexController = TextEditingController(text: _hexFromColor(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPicker(
            pickerColor: _color,
            onColorChanged: (value) {
              setState(() {
                _color = value;
                _hexController.text = _hexFromColor(value);
                _hexController.selection = TextSelection.collapsed(
                  offset: _hexController.text.length,
                );
              });
            },
            enableAlpha: true,
            displayThumbColor: true,
            hexInputBar: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Apply'),
        ),
      ],
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
    final theme = PosterEditorThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.slider.valueChipBackgroundColor,
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
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: theme.slider.thumbRadius,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: theme.slider.overlayRadius,
            ),
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

String _hexFromColor(Color color) {
  final argb = color.toARGB32();
  final alpha = (argb >> 24) & 0xff;
  final rgb = argb & 0x00ffffff;
  final value = alpha == 0xff ? rgb : argb;
  final length = alpha == 0xff ? 6 : 8;
  return '#${value.toRadixString(16).padLeft(length, '0').toUpperCase()}';
}
