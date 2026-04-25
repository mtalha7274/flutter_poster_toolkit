import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';

import '../controller/poster_controller.dart';
import '../models/poster_element.dart';

class PosterCanvas extends StatelessWidget {
  const PosterCanvas({
    super.key,
    required this.controller,
    this.interactionScale = 1,
    this.showSelection = true,
    this.onInteract,
    this.onMorePressed,
  });

  final PosterController controller;
  final double interactionScale;
  final bool showSelection;
  final VoidCallback? onInteract;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final document = controller.document;
        final showEditorChrome = showSelection;
        final selectedElement = controller.selectedElement;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onInteract,
          child: Container(
            width: document.canvasSize.width,
            height: document.canvasSize.height,
            decoration: BoxDecoration(
              boxShadow: showEditorChrome
                  ? const [
                      BoxShadow(
                        color: Color(0x1a000000),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Screenshot(
                  controller: controller.screenshotController,
                  key: controller.canvasKey,
                  child: ClipRect(
                    child: Container(
                      width: document.canvasSize.width,
                      height: document.canvasSize.height,
                      color: document.backgroundColor,
                      child: Stack(
                        children: [
                          for (final element in document.elements)
                            _StaticElementLayer(element: element),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showEditorChrome)
                  for (final element in document.elements)
                    _ElementLayer(
                      key: ValueKey(element.id),
                      element: element,
                      selected: controller.selectedElementId == element.id,
                      showSelection: true,
                      interactionScale: interactionScale,
                      onSelect: () {
                        onInteract?.call();
                        controller.select(element.id);
                      },
                      onMove: controller.moveSelected,
                      onEnd: controller.endInteraction,
                    ),
                if (showEditorChrome && selectedElement != null)
                  _ElementQuickActionsLayer(
                    element: selectedElement,
                    onDuplicate: controller.duplicateSelected,
                    onDelete: controller.deleteSelected,
                    onMore: onMorePressed,
                  ),
                if (showEditorChrome &&
                    selectedElement != null &&
                    !selectedElement.locked)
                  _ElementHandlesLayer(
                    element: selectedElement,
                    interactionScale: interactionScale,
                    onResize: controller.resizeSelected,
                    onRotate: controller.rotateSelected,
                    onEnd: controller.endInteraction,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticElementLayer extends StatelessWidget {
  const _StaticElementLayer({required this.element});

  final PosterElement element;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.size.width,
      height: element.size.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: Transform.scale(
          scaleX: element.flipX ? -1 : 1,
          scaleY: element.flipY ? -1 : 1,
          child: Opacity(
            opacity: element.opacity.clamp(0, 1),
            child: _PosterElementView(element: element),
          ),
        ),
      ),
    );
  }
}

class _ElementLayer extends StatefulWidget {
  const _ElementLayer({
    super.key,
    required this.element,
    required this.selected,
    required this.showSelection,
    required this.interactionScale,
    required this.onSelect,
    required this.onMove,
    required this.onEnd,
  });

  final PosterElement element;
  final bool selected;
  final bool showSelection;
  final double interactionScale;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final VoidCallback onEnd;

  @override
  State<_ElementLayer> createState() => _ElementLayerState();
}

class _ElementLayerState extends State<_ElementLayer> {
  /// Pan deltas must be in canvas (parent) space. `Transform.rotate` maps
  /// pointer movement into the child's local space, so [DragUpdateDetails.delta]
  /// does not match how [PosterElement.position] (top-left in canvas) should move.
  Offset? _lastGlobal;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.element.position.dx,
      top: widget.element.position.dy,
      width: widget.element.size.width,
      height: widget.element.size.height,
      child: Transform.rotate(
        angle: widget.element.rotation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          onPanStart: !widget.selected || widget.element.locked
              ? null
              : (details) {
                  widget.onSelect();
                  _lastGlobal = details.globalPosition;
                },
          onPanUpdate: !widget.selected || widget.element.locked
              ? null
              : (details) {
                  final last = _lastGlobal;
                  if (last == null) {
                    return;
                  }
                  _lastGlobal = details.globalPosition;
                  final canvasDelta = details.globalPosition - last;
                  widget.onMove(canvasDelta / widget.interactionScale);
                },
          onPanEnd: !widget.selected || widget.element.locked
              ? null
              : (_) {
                  _lastGlobal = null;
                  widget.onEnd();
                },
          onPanCancel: !widget.selected || widget.element.locked
              ? null
              : () {
                  _lastGlobal = null;
                },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.001,
                    child: _PosterElementView(element: widget.element),
                  ),
                ),
              ),
              if (widget.showSelection && widget.selected) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.element.locked
                              ? const Color(0xfff59e0b)
                              : const Color(0xff7c3aed),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementHandlesLayer extends StatelessWidget {
  const _ElementHandlesLayer({
    required this.element,
    required this.interactionScale,
    required this.onResize,
    required this.onRotate,
    required this.onEnd,
  });

  final PosterElement element;
  final double interactionScale;
  final ValueChanged<Offset> onResize;
  final ValueChanged<double> onRotate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final center =
        element.position +
        Offset(element.size.width / 2, element.size.height / 2);
    final rotateHandleCenter =
        center +
        _rotateOffset(
          Offset(0, -element.size.height / 2 - 84),
          element.rotation,
        );
    final resizeHandleCenter =
        center +
        _rotateOffset(
          Offset(element.size.width / 2 + 25, element.size.height / 2 + 25),
          element.rotation,
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: resizeHandleCenter.dx - 17,
          top: resizeHandleCenter.dy - 17,
          width: 34,
          height: 34,
          child: _ResizeHandle(
            interactionScale: interactionScale,
            onResize: onResize,
            onEnd: onEnd,
          ),
        ),
        Positioned(
          left: rotateHandleCenter.dx - 20,
          top: rotateHandleCenter.dy - 20,
          width: 40,
          height: 40,
          child: _RotateHandle(
            handleOffsetFromElementCenter: rotateHandleCenter - center,
            interactionScale: interactionScale,
            onRotate: onRotate,
            onEnd: onEnd,
          ),
        ),
      ],
    );
  }

  Offset _rotateOffset(Offset offset, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(
      offset.dx * cosA - offset.dy * sinA,
      offset.dx * sinA + offset.dy * cosA,
    );
  }
}

class _ElementQuickActionsLayer extends StatelessWidget {
  const _ElementQuickActionsLayer({
    required this.element,
    required this.onDuplicate,
    required this.onDelete,
    this.onMore,
  });

  final PosterElement element;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final left = element.position.dx + element.size.width / 2 - 84;
    final top = math.max(8.0, element.position.dy - 56);
    return Positioned(
      left: left,
      top: top,
      width: 168,
      height: 44,
      child: _ElementQuickActions(
        onDuplicate: onDuplicate,
        onDelete: onDelete,
        onMore: onMore,
      ),
    );
  }
}

class _ElementQuickActions extends StatelessWidget {
  const _ElementQuickActions({
    required this.onDuplicate,
    required this.onDelete,
    this.onMore,
  });

  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xff171124),
        elevation: 10,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickButton(
                tooltip: 'Duplicate',
                icon: Icons.copy,
                onPressed: onDuplicate,
              ),
              _QuickButton(
                tooltip: 'Delete',
                icon: Icons.delete,
                onPressed: onDelete,
              ),
              _QuickButton(
                tooltip: 'More',
                icon: Icons.more_horiz,
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 34,
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
      child: IconButton(
        iconSize: 22,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
        color: Colors.white,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _PosterElementView extends StatelessWidget {
  const _PosterElementView({required this.element});

  final PosterElement element;

  @override
  Widget build(BuildContext context) {
    return switch (element) {
      TextElement() => _TextElementView(element: element as TextElement),
      ImageElement() => _ImageElementView(element: element as ImageElement),
      ShapeElement() => CustomPaint(
        painter: _ShapePainter(element: element as ShapeElement),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TextElementView extends StatelessWidget {
  const _TextElementView({required this.element});

  final TextElement element;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.getFont(
      element.fontFamily,
      fontSize: element.fontSize,
      fontWeight: element.fontWeight,
      fontStyle: element.italic ? FontStyle.italic : FontStyle.normal,
      decoration: element.underline ? TextDecoration.underline : null,
      color: element.color,
      letterSpacing: element.letterSpacing,
      height: 1.05,
    );
    return Center(
      child: Text(
        element.text,
        textAlign: element.alignment,
        maxLines: null,
        overflow: TextOverflow.clip,
        style: style,
      ),
    );
  }
}

class _ImageElementView extends StatelessWidget {
  const _ImageElementView({required this.element});

  final ImageElement element;

  @override
  Widget build(BuildContext context) {
    final fit = switch (element.fit) {
      PosterImageFit.cover => BoxFit.cover,
      PosterImageFit.contain => BoxFit.contain,
      PosterImageFit.fill => BoxFit.fill,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(element.cornerRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xffe5e7eb)),
        child: element.bytes == null
            ? const _ImagePlaceholder()
            : Image.memory(element.bytes!, fit: fit),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.pets, color: Color(0xff6b7280), size: 96),
    );
  }
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.element});

  final ShapeElement element;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = element.fillColor;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = element.strokeColor;
    final rect = Offset.zero & size;

    switch (element.shape) {
      case PosterShapeType.rectangle:
        final radius = Radius.circular(element.borderRadius);
        final rrect = RRect.fromRectAndRadius(
          rect.deflate(stroke.strokeWidth / 2),
          radius,
        );
        canvas.drawRRect(rrect, fill);
        if (element.strokeWidth > 0) {
          canvas.drawRRect(rrect, stroke);
        }
      case PosterShapeType.circle:
        canvas.drawOval(rect.deflate(stroke.strokeWidth / 2), fill);
        if (element.strokeWidth > 0) {
          canvas.drawOval(rect.deflate(stroke.strokeWidth / 2), stroke);
        }
      case PosterShapeType.line:
        canvas.drawLine(
          Offset(stroke.strokeWidth / 2, size.height / 2),
          Offset(size.width - stroke.strokeWidth / 2, size.height / 2),
          stroke,
        );
      case PosterShapeType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, stroke.strokeWidth / 2)
          ..lineTo(
            size.width - stroke.strokeWidth / 2,
            size.height - stroke.strokeWidth / 2,
          )
          ..lineTo(stroke.strokeWidth / 2, size.height - stroke.strokeWidth / 2)
          ..close();
        canvas.drawPath(path, fill);
        if (element.strokeWidth > 0) {
          canvas.drawPath(path, stroke);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.element != element;
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.interactionScale,
    required this.onResize,
    required this.onEnd,
  });

  final double interactionScale;
  final ValueChanged<Offset> onResize;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {},
      onPanUpdate: (details) => onResize(details.delta / interactionScale),
      onPanEnd: (_) => onEnd(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xff2563eb), width: 2),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotateHandle extends StatefulWidget {
  const _RotateHandle({
    required this.handleOffsetFromElementCenter,
    required this.interactionScale,
    required this.onRotate,
    required this.onEnd,
  });

  final Offset handleOffsetFromElementCenter;
  final double interactionScale;
  final ValueChanged<double> onRotate;
  final VoidCallback onEnd;

  @override
  State<_RotateHandle> createState() => _RotateHandleState();
}

class _RotateHandleState extends State<_RotateHandle> {
  double? _previousAngle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _previousAngle = _angleFor(details.globalPosition);
      },
      onPanUpdate: (details) {
        final previous = _previousAngle;
        final current = _angleFor(details.globalPosition);
        _previousAngle = current;
        if (previous == null) {
          return;
        }
        widget.onRotate(_normalizeRadians(current - previous));
      },
      onPanEnd: (_) {
        _previousAngle = null;
        widget.onEnd();
      },
      onPanCancel: () {
        _previousAngle = null;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xff2563eb), width: 2),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.rotate_right,
          size: 22,
          color: Color(0xff2563eb),
        ),
      ),
    );
  }

  double _angleFor(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final handleCenter = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    final elementCenter =
        handleCenter -
        widget.handleOffsetFromElementCenter * widget.interactionScale;
    final vector = globalPosition - elementCenter;
    return math.atan2(vector.dy, vector.dx);
  }

  double _normalizeRadians(double radians) {
    while (radians <= -math.pi) {
      radians += math.pi * 2;
    }
    while (radians > math.pi) {
      radians -= math.pi * 2;
    }
    return radians;
  }
}
