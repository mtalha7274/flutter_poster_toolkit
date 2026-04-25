import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PosterElementType { text, image, shape }

enum PosterShapeType { rectangle, circle, line, triangle }

enum PosterImageFit { cover, contain, fill }

abstract class PosterElement extends Equatable {
  const PosterElement({
    required this.id,
    required this.position,
    required this.size,
    this.rotation = 0,
    this.opacity = 1,
    this.locked = false,
    this.flipX = false,
    this.flipY = false,
  });

  final String id;
  final Offset position;
  final Size size;
  final double rotation;
  final double opacity;
  final bool locked;
  final bool flipX;
  final bool flipY;

  PosterElementType get type;

  Rect get rect => position & size;

  PosterElement copyWithBase({
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
  });
}

class TextElement extends PosterElement {
  const TextElement({
    required super.id,
    required super.position,
    required super.size,
    super.rotation,
    super.opacity,
    super.locked,
    super.flipX,
    super.flipY,
    this.text = 'Text',
    this.fontFamily = 'Roboto',
    this.fontSize = 32,
    this.fontWeight = FontWeight.normal,
    this.italic = false,
    this.underline = false,
    this.color = Colors.black,
    this.alignment = TextAlign.center,
    this.letterSpacing = 0,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final bool italic;
  final bool underline;
  final Color color;
  final TextAlign alignment;
  final double letterSpacing;

  @override
  PosterElementType get type => PosterElementType.text;

  TextElement copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
    String? text,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    bool? italic,
    bool? underline,
    Color? color,
    TextAlign? alignment,
    double? letterSpacing,
  }) {
    return TextElement(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  @override
  TextElement copyWithBase({
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
  }) {
    return copyWith(
      position: position,
      size: size,
      rotation: rotation,
      opacity: opacity,
      locked: locked,
      flipX: flipX,
      flipY: flipY,
    );
  }

  @override
  List<Object?> get props => [
    id,
    position,
    size,
    rotation,
    opacity,
    locked,
    flipX,
    flipY,
    text,
    fontFamily,
    fontSize,
    fontWeight,
    italic,
    underline,
    color,
    alignment,
    letterSpacing,
  ];
}

class ImageElement extends PosterElement {
  const ImageElement({
    required super.id,
    required super.position,
    required super.size,
    super.rotation,
    super.opacity,
    super.locked,
    super.flipX,
    super.flipY,
    this.bytes,
    this.cornerRadius = 0,
    this.fit = PosterImageFit.cover,
  });

  final Uint8List? bytes;
  final double cornerRadius;
  final PosterImageFit fit;

  @override
  PosterElementType get type => PosterElementType.image;

  ImageElement copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
    Uint8List? bytes,
    bool clearBytes = false,
    double? cornerRadius,
    PosterImageFit? fit,
  }) {
    return ImageElement(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      fit: fit ?? this.fit,
    );
  }

  @override
  ImageElement copyWithBase({
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
  }) {
    return copyWith(
      position: position,
      size: size,
      rotation: rotation,
      opacity: opacity,
      locked: locked,
      flipX: flipX,
      flipY: flipY,
    );
  }

  @override
  List<Object?> get props => [
    id,
    position,
    size,
    rotation,
    opacity,
    locked,
    flipX,
    flipY,
    bytes,
    cornerRadius,
    fit,
  ];
}

class ShapeElement extends PosterElement {
  const ShapeElement({
    required super.id,
    required super.position,
    required super.size,
    required this.shape,
    super.rotation,
    super.opacity,
    super.locked,
    super.flipX,
    super.flipY,
    this.fillColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2,
    this.borderRadius = 0,
  });

  final PosterShapeType shape;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double borderRadius;

  @override
  PosterElementType get type => PosterElementType.shape;

  ShapeElement copyWith({
    String? id,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
    PosterShapeType? shape,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    double? borderRadius,
  }) {
    return ShapeElement(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      shape: shape ?? this.shape,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  ShapeElement copyWithBase({
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    bool? locked,
    bool? flipX,
    bool? flipY,
  }) {
    return copyWith(
      position: position,
      size: size,
      rotation: rotation,
      opacity: opacity,
      locked: locked,
      flipX: flipX,
      flipY: flipY,
    );
  }

  @override
  List<Object?> get props => [
    id,
    position,
    size,
    rotation,
    opacity,
    locked,
    flipX,
    flipY,
    shape,
    fillColor,
    strokeColor,
    strokeWidth,
    borderRadius,
  ];
}
