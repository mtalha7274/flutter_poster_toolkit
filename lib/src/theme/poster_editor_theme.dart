import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// --- Sub-themes (colors & sizes grouped by UI area) ---

/// Dotted stage behind the poster and scaffold background.
class PosterStageTheme extends Equatable {
  const PosterStageTheme({
    this.scaffoldBackgroundColor = const Color(0xfff6f7fb),
    this.dotColor = const Color(0xffd6dae3),
    this.dotSpacing = 24,
    this.dotRadius = 1.15,
    this.canvasInset = 8,
  });

  final Color scaffoldBackgroundColor;
  final Color dotColor;
  final double dotSpacing;
  final double dotRadius;

  /// Minimum padding subtracted from layout when fitting the poster.
  final double canvasInset;

  @override
  List<Object?> get props =>
      [scaffoldBackgroundColor, dotColor, dotSpacing, dotRadius, canvasInset];
}

/// Drop shadow around the poster document in the editor.
class PosterCanvasChromeTheme extends Equatable {
  const PosterCanvasChromeTheme({
    this.shadowColor = const Color(0x1a000000),
    this.shadowBlurRadius = 28,
    this.shadowSpreadRadius = 4,
    this.shadowOffset = const Offset(0, 3),
  });

  final Color shadowColor;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final Offset shadowOffset;

  BoxShadow get dropShadow => BoxShadow(
        color: shadowColor,
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
        offset: shadowOffset,
      );

  @override
  List<Object?> get props =>
      [shadowColor, shadowBlurRadius, shadowSpreadRadius, shadowOffset];
}

/// Selection outline and inline text editing overlay on the canvas.
class PosterSelectionTheme extends Equatable {
  const PosterSelectionTheme({
    this.borderColor = const Color(0xff7c3aed),
    this.lockedBorderColor = const Color(0xfff59e0b),
    this.borderWidth = 2,
    this.inlineTextEditorOverlayColor = const Color(0xdbffffff),
  });

  final Color borderColor;
  final Color lockedBorderColor;
  final double borderWidth;
  final Color inlineTextEditorOverlayColor;

  @override
  List<Object?> get props =>
      [borderColor, lockedBorderColor, borderWidth, inlineTextEditorOverlayColor];
}

/// Floating action chip above the selection (duplicate / delete / more).
class PosterQuickActionsTheme extends Equatable {
  const PosterQuickActionsTheme({
    this.backgroundColor = const Color(0xff171124),
    this.elevation = 10,
    this.borderRadius = 24,
    this.iconColor = Colors.white,
  });

  final Color backgroundColor;
  final double elevation;
  final double borderRadius;
  final Color iconColor;

  @override
  List<Object?> get props =>
      [backgroundColor, elevation, borderRadius, iconColor];
}

/// Tooltips on toolbar and quick actions.
class PosterTooltipTheme extends Equatable {
  const PosterTooltipTheme({
    this.backgroundColor = const Color(0xff111827),
    this.textColor = Colors.white,
  });

  final Color backgroundColor;
  final Color textColor;

  @override
  List<Object?> get props => [backgroundColor, textColor];
}

/// Resize and rotate handles on the canvas.
class PosterTransformHandleTheme extends Equatable {
  const PosterTransformHandleTheme({
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xff2563eb),
    this.rotateIconColor = const Color(0xff2563eb),
    this.borderWidth = 2,
    this.shadowColor = const Color(0x24000000),
    this.shadowBlurRadius = 8,
    this.shadowOffset = const Offset(0, 3),
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color rotateIconColor;
  final double borderWidth;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  BoxShadow get boxShadow => BoxShadow(
        color: shadowColor,
        blurRadius: shadowBlurRadius,
        offset: shadowOffset,
      );

  @override
  List<Object?> get props => [
        backgroundColor,
        borderColor,
        rotateIconColor,
        borderWidth,
        shadowColor,
        shadowBlurRadius,
        shadowOffset,
      ];
}

/// Bottom tool strip and primary tool buttons.
class PosterToolbarTheme extends Equatable {
  const PosterToolbarTheme({
    this.backgroundColor = const Color(0xff111827),
    this.dividerColor = const Color(0x33ffffff),
    this.dividerWidth = 1,
    this.dividerHeight = 48,
    this.dividerHorizontalMargin = 8,
    this.height = 78,
    this.horizontalPadding = 10,
    this.verticalPadding = 12,
    this.toolButtonSize = 50,
    this.toolButtonBackgroundColor = const Color(0xff1f2937),
    this.toolButtonForegroundColor = Colors.white,
    this.toolButtonDisabledForegroundColor = const Color(0xff6b7280),
    this.toolButtonHorizontalPadding = 4,
  });

  final Color backgroundColor;
  final Color dividerColor;
  final double dividerWidth;
  final double dividerHeight;
  final double dividerHorizontalMargin;
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double toolButtonSize;
  final Color toolButtonBackgroundColor;
  final Color toolButtonForegroundColor;
  final Color toolButtonDisabledForegroundColor;
  final double toolButtonHorizontalPadding;

  @override
  List<Object?> get props => [
        backgroundColor,
        dividerColor,
        dividerWidth,
        dividerHeight,
        dividerHorizontalMargin,
        height,
        horizontalPadding,
        verticalPadding,
        toolButtonSize,
        toolButtonBackgroundColor,
        toolButtonForegroundColor,
        toolButtonDisabledForegroundColor,
        toolButtonHorizontalPadding,
      ];
}

/// Properties bottom sheet shell (header, lock, list padding).
class PosterPropertiesTheme extends Equatable {
  const PosterPropertiesTheme({
    this.sheetBackgroundColor = const Color(0xfff8fafc),
    this.topCornerRadius = 20,
    this.panelBackgroundColor = const Color(0xfff8fafc),
    this.emptyTextColor = const Color(0xff6b7280),
    this.listHorizontalPadding = 20,
    this.listBottomPadding = 24,
    this.headerLeadingSize = 44,
    this.headerLeadingRadius = 12,
    this.headerIconBackgroundColor = const Color(0xff111827),
    this.headerIconForegroundColor = Colors.white,
    this.titleTextColor = const Color(0xff111827),
    this.lockButtonBackgroundColor = const Color(0xffe5e7eb),
    this.lockButtonForegroundColor = const Color(0xff111827),
    this.lockButtonSize = 44,
  });

  final Color sheetBackgroundColor;
  final double topCornerRadius;
  final Color panelBackgroundColor;
  final Color emptyTextColor;
  final double listHorizontalPadding;
  final double listBottomPadding;
  final double headerLeadingSize;
  final double headerLeadingRadius;
  final Color headerIconBackgroundColor;
  final Color headerIconForegroundColor;
  final Color titleTextColor;
  final Color lockButtonBackgroundColor;
  final Color lockButtonForegroundColor;
  final double lockButtonSize;

  @override
  List<Object?> get props => [
        sheetBackgroundColor,
        topCornerRadius,
        panelBackgroundColor,
        emptyTextColor,
        listHorizontalPadding,
        listBottomPadding,
        headerLeadingSize,
        headerLeadingRadius,
        headerIconBackgroundColor,
        headerIconForegroundColor,
        titleTextColor,
        lockButtonBackgroundColor,
        lockButtonForegroundColor,
        lockButtonSize,
      ];
}

/// Grouped property sections inside the sheet.
class PosterPropertyCardTheme extends Equatable {
  const PosterPropertyCardTheme({
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xffe5e7eb),
    this.borderRadius = 14,
    this.shadowColor = const Color(0x08000000),
    this.shadowBlurRadius = 12,
    this.shadowOffset = const Offset(0, 4),
    this.sectionTitleColor = const Color(0xff374151),
    this.sectionSpacing = 14,
    this.innerPadding = 16,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Color sectionTitleColor;
  final double sectionSpacing;
  final double innerPadding;

  BoxShadow get boxShadow => BoxShadow(
        color: shadowColor,
        blurRadius: shadowBlurRadius,
        offset: shadowOffset,
      );

  @override
  List<Object?> get props => [
        backgroundColor,
        borderColor,
        borderRadius,
        shadowColor,
        shadowBlurRadius,
        shadowOffset,
        sectionTitleColor,
        sectionSpacing,
        innerPadding,
      ];
}

/// Layer order controls in the properties sheet.
class PosterLayerButtonTheme extends Equatable {
  const PosterLayerButtonTheme({
    this.backgroundColor = const Color(0xfff3f4f6),
    this.foregroundColor = const Color(0xff111827),
    this.minWidth = 116,
    this.height = 46,
    this.borderRadius = 10,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final double minWidth;
  final double height;
  final double borderRadius;

  @override
  List<Object?> get props =>
      [backgroundColor, foregroundColor, minWidth, height, borderRadius];
}

/// Flip and similar toggles in the properties sheet.
class PosterToggleButtonTheme extends Equatable {
  const PosterToggleButtonTheme({
    this.selectedBackgroundColor = const Color(0xff111827),
    this.selectedForegroundColor = Colors.white,
    this.unselectedBackgroundColor = Colors.white,
    this.unselectedForegroundColor = const Color(0xff111827),
    this.unselectedBorderColor = const Color(0xffd1d5db),
    this.minHeight = 44,
    this.borderRadius = 10,
  });

  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedBackgroundColor;
  final Color unselectedForegroundColor;
  final Color unselectedBorderColor;
  final double minHeight;
  final double borderRadius;

  @override
  List<Object?> get props => [
        selectedBackgroundColor,
        selectedForegroundColor,
        unselectedBackgroundColor,
        unselectedForegroundColor,
        unselectedBorderColor,
        minHeight,
        borderRadius,
      ];
}

/// Sliders in the properties sheet.
class PosterSliderTheme extends Equatable {
  const PosterSliderTheme({
    this.valueChipBackgroundColor = const Color(0xfff3f4f6),
    this.thumbRadius = 10,
    this.overlayRadius = 20,
  });

  final Color valueChipBackgroundColor;
  final double thumbRadius;
  final double overlayRadius;

  @override
  List<Object?> get props =>
      [valueChipBackgroundColor, thumbRadius, overlayRadius];
}

/// Text fields and dropdowns in the properties sheet.
class PosterInputTheme extends Equatable {
  const PosterInputTheme({
    this.fillColor = const Color(0xfff9fafb),
    this.hintColor = const Color(0xff9ca3af),
    this.borderColor = const Color(0xffd1d5db),
    this.focusedBorderColor = const Color(0xff2563eb),
    this.borderRadius = 14,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    this.focusedBorderWidth = 1.6,
  });

  final Color fillColor;
  final Color hintColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final double borderRadius;
  final EdgeInsets contentPadding;
  final double focusedBorderWidth;

  @override
  List<Object?> get props => [
        fillColor,
        hintColor,
        borderColor,
        focusedBorderColor,
        borderRadius,
        contentPadding,
        focusedBorderWidth,
      ];
}

/// Color picker swatch ring in the properties sheet.
class PosterColorSwatchTheme extends Equatable {
  const PosterColorSwatchTheme({
    this.borderColor = const Color(0xffe5e7eb),
    this.borderWidth = 2,
    this.size = 44,
  });

  final Color borderColor;
  final double borderWidth;
  final double size;

  @override
  List<Object?> get props => [borderColor, borderWidth, size];
}

/// Placeholder when an image element has no bytes.
class PosterImagePlaceholderTheme extends Equatable {
  const PosterImagePlaceholderTheme({
    this.backgroundColor = const Color(0xffe5e7eb),
    this.iconColor = const Color(0xff6b7280),
    this.iconSize = 96,
  });

  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  @override
  List<Object?> get props => [backgroundColor, iconColor, iconSize];
}

/// Constraints for imported bitmaps (add image).
class PosterImportTheme extends Equatable {
  const PosterImportTheme({
    this.maxImageSize = const Size(260, 220),
  });

  final Size maxImageSize;

  @override
  List<Object?> get props => [maxImageSize];
}

// --- Root theme ---

/// Visual styling for [PosterEditor] and [PosterCanvas] editor chrome.
///
/// Compose [PosterStageTheme], [PosterToolbarTheme], etc., or override single
/// groups:
/// ```dart
/// PosterEditorTheme(
///   toolbar: PosterToolbarTheme(backgroundColor: Colors.indigo),
///   stage: PosterStageTheme(scaffoldBackgroundColor: Colors.white),
/// )
/// ```
class PosterEditorTheme extends Equatable {
  const PosterEditorTheme({
    this.stage = const PosterStageTheme(),
    this.canvasChrome = const PosterCanvasChromeTheme(),
    this.selection = const PosterSelectionTheme(),
    this.quickActions = const PosterQuickActionsTheme(),
    this.tooltip = const PosterTooltipTheme(),
    this.handles = const PosterTransformHandleTheme(),
    this.toolbar = const PosterToolbarTheme(),
    this.properties = const PosterPropertiesTheme(),
    this.propertyCard = const PosterPropertyCardTheme(),
    this.layerButton = const PosterLayerButtonTheme(),
    this.toggleButton = const PosterToggleButtonTheme(),
    this.slider = const PosterSliderTheme(),
    this.input = const PosterInputTheme(),
    this.colorSwatch = const PosterColorSwatchTheme(),
    this.imagePlaceholder = const PosterImagePlaceholderTheme(),
    this.imports = const PosterImportTheme(),
  });

  static const PosterEditorTheme defaults = PosterEditorTheme();

  final PosterStageTheme stage;
  final PosterCanvasChromeTheme canvasChrome;
  final PosterSelectionTheme selection;
  final PosterQuickActionsTheme quickActions;
  final PosterTooltipTheme tooltip;
  final PosterTransformHandleTheme handles;
  final PosterToolbarTheme toolbar;
  final PosterPropertiesTheme properties;
  final PosterPropertyCardTheme propertyCard;
  final PosterLayerButtonTheme layerButton;
  final PosterToggleButtonTheme toggleButton;
  final PosterSliderTheme slider;
  final PosterInputTheme input;
  final PosterColorSwatchTheme colorSwatch;
  final PosterImagePlaceholderTheme imagePlaceholder;
  final PosterImportTheme imports;

  PosterEditorTheme copyWith({
    PosterStageTheme? stage,
    PosterCanvasChromeTheme? canvasChrome,
    PosterSelectionTheme? selection,
    PosterQuickActionsTheme? quickActions,
    PosterTooltipTheme? tooltip,
    PosterTransformHandleTheme? handles,
    PosterToolbarTheme? toolbar,
    PosterPropertiesTheme? properties,
    PosterPropertyCardTheme? propertyCard,
    PosterLayerButtonTheme? layerButton,
    PosterToggleButtonTheme? toggleButton,
    PosterSliderTheme? slider,
    PosterInputTheme? input,
    PosterColorSwatchTheme? colorSwatch,
    PosterImagePlaceholderTheme? imagePlaceholder,
    PosterImportTheme? imports,
  }) {
    return PosterEditorTheme(
      stage: stage ?? this.stage,
      canvasChrome: canvasChrome ?? this.canvasChrome,
      selection: selection ?? this.selection,
      quickActions: quickActions ?? this.quickActions,
      tooltip: tooltip ?? this.tooltip,
      handles: handles ?? this.handles,
      toolbar: toolbar ?? this.toolbar,
      properties: properties ?? this.properties,
      propertyCard: propertyCard ?? this.propertyCard,
      layerButton: layerButton ?? this.layerButton,
      toggleButton: toggleButton ?? this.toggleButton,
      slider: slider ?? this.slider,
      input: input ?? this.input,
      colorSwatch: colorSwatch ?? this.colorSwatch,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      imports: imports ?? this.imports,
    );
  }

  @override
  List<Object?> get props => [
        stage,
        canvasChrome,
        selection,
        quickActions,
        tooltip,
        handles,
        toolbar,
        properties,
        propertyCard,
        layerButton,
        toggleButton,
        slider,
        input,
        colorSwatch,
        imagePlaceholder,
        imports,
      ];
}

/// Provides [PosterEditorTheme] to descendant widgets.
class PosterEditorThemeScope extends InheritedWidget {
  const PosterEditorThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final PosterEditorTheme theme;

  static PosterEditorTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PosterEditorThemeScope>();
    return scope?.theme ?? PosterEditorTheme.defaults;
  }

  static PosterEditorTheme? maybeOf(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<PosterEditorThemeScope>();
    return scope?.theme;
  }

  @override
  bool updateShouldNotify(PosterEditorThemeScope oldWidget) {
    return theme != oldWidget.theme;
  }
}

InputDecoration posterInputDecoration(
  PosterInputTheme input,
  String hintText,
) {
  final borderRadius = BorderRadius.circular(input.borderRadius);
  final borderSide = BorderSide(color: input.borderColor);
  return InputDecoration(
    filled: true,
    fillColor: input.fillColor,
    hintStyle: TextStyle(color: input.hintColor),
    contentPadding: input.contentPadding,
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
      borderSide: BorderSide(
        color: input.focusedBorderColor,
        width: input.focusedBorderWidth,
      ),
    ),
  ).copyWith(hintText: hintText);
}
