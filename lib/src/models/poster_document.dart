import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'poster_element.dart';

class PosterDocument extends Equatable {
  const PosterDocument({
    required this.canvasSize,
    this.backgroundColor = Colors.white,
    this.elements = const [],
  });

  factory PosterDocument.empty({Size canvasSize = const Size(600, 820)}) {
    return PosterDocument(canvasSize: canvasSize);
  }

  final Size canvasSize;
  final Color backgroundColor;
  final List<PosterElement> elements;

  PosterDocument copyWith({
    Size? canvasSize,
    Color? backgroundColor,
    List<PosterElement>? elements,
  }) {
    return PosterDocument(
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: elements ?? this.elements,
    );
  }

  PosterElement? elementById(String? id) {
    if (id == null) {
      return null;
    }
    for (final element in elements) {
      if (element.id == id) {
        return element;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [canvasSize, backgroundColor, elements];
}
