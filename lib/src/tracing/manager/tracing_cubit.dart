import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:tracing_game/src/tracing/model/letter_paths_model.dart';
import 'package:tracing_game/src/tracing/model/trace_model.dart';
import 'package:tracing_game/tracing_game.dart';

import '../../get_shape_helper/enum_of_arabic_and_numbers_letters.dart';

part 'tracing_state.dart';

class TracingCubit extends Cubit<TracingState> {
  /// The tallest glyph on a screen is scaled to this height (logical px),
  /// and every other glyph on that same screen shares the exact same
  /// scale factor. This is what replaces the old "every letter forced
  /// into its own fixed 200x200 box" behavior:
  ///   - stroke thickness stays consistent across letters, because the
  ///     whole glyph — outline included — is scaled by one shared number
  ///     instead of each letter being independently stretched to fill
  ///     an identical square,
  ///   - short letters stay shorter than tall letters instead of both
  ///     being blown up to the same visual height,
  ///   - each letter's rendered box is now its own true (scaled) size,
  ///     so downstream layout (spacing) reflects real glyph width
  ///     instead of a uniform placeholder square.
  final double targetGlyphHeight;

  TracingCubit({
    List<TraceWordModel>? traceWordModels,
    List<TraceGeoMetricShapeModel>? traceGeoMetricShapeModel,
    List<TraceCharsModel>? traceShapeModel,
    required StateOfTracing stateOfTracing,
    this.targetGlyphHeight = 200,
  }) : super(TracingState(
          numberOfScreens: stateOfTracing == StateOfTracing.chars
              ? traceShapeModel!.length
              : stateOfTracing == StateOfTracing.traceShapes
                  ? traceGeoMetricShapeModel!.length
                  : stateOfTracing == StateOfTracing.traceWords
                      ? traceWordModels!.length
                      : 0,
          traceWordModels: traceWordModels,
          traceGeoMetricShapes: traceGeoMetricShapeModel,
          traceShapeModel: traceShapeModel,
          index: 0,
          stateOfTracing: stateOfTracing,
          traceLetter: const [],
          letterPathsModels: const [],
        )) {
    updateTheTraceLetter();
  }

  updateIndex() {
    int index = state.index;
    index++;
    if (index < state.numberOfScreens) {
      emit(state.copyWith(index: index, drawingStates: DrawingStates.loaded));
      updateTheTraceLetter();
    }
  }

  updateTheTraceLetter() async {
    emit(state.clearData());
    emit(state.copyWith(
        activeIndex: 0,
        stateOfTracing: state.stateOfTracing,
        traceLetter: TypeExtensionTracking().getTracingData(
            geometryShapes: state.stateOfTracing == StateOfTracing.traceShapes &&  state.traceGeoMetricShapes!.isNotEmpty
                ? state.traceGeoMetricShapes![state.index].shapes
                : null,
            chars: state.stateOfTracing == StateOfTracing.chars &&  state.traceShapeModel!.isNotEmpty
                ? state.traceShapeModel![state.index].chars
                : null,
                word:state.stateOfTracing == StateOfTracing.traceWords &&  state.traceWordModels!.isNotEmpty
                ? state.traceWordModels![state.index]
                : null ,
            currentOfTracking: state.stateOfTracing)));
    await loadAssets();
  }

  Future<void> loadAssets() async {
    emit(state.copyWith(drawingStates: DrawingStates.loading));

    // --- Pass 1: parse every glyph's path once, and find the tallest
    // non-space glyph on this screen. That height becomes the reference
    // every other glyph on this screen is scaled against.
    final List<Path> parsedLetterPaths = [];
    double tallestGlyphHeight = 0;

    for (final letterModel in state.traceLetter) {
      final parsed = parseSvgPath(letterModel.letterPath);
      parsedLetterPaths.add(parsed);

      if (letterModel.isSpace) continue; // don't let a blank space's
      // (possibly degenerate) bounds skew the shared scale.

      final bounds = parsed.getBounds();
      if (bounds.height > tallestGlyphHeight) {
        tallestGlyphHeight = bounds.height;
      }
    }

    // One scale for the entire screen/word. Guard against an empty or
    // degenerate screen (all-space, or a zero-height glyph) so we never
    // divide by zero.
    final double screenScale =
        tallestGlyphHeight > 0 ? targetGlyphHeight / tallestGlyphHeight : 1.0;

    // --- Pass 2: transform every glyph using the SAME screenScale,
    // each into its own natural-proportioned box (not a shared fixed
    // square). This is the only structural change from the original
    // per-letter-independent-scale approach — the actual fit/center/
    // transform math for the letter, dotted guide, and index arrows is
    // otherwise untouched, so their relative alignment to each other is
    // preserved exactly as before.
    List<LetterPathsModel> model = [];
    for (int i = 0; i < state.traceLetter.length; i++) {
      final letterModel = state.traceLetter[i];
      final parsedPath = parsedLetterPaths[i];

      final Size perLetterViewSize;
      if (letterModel.isSpace) {
        // No visible glyph to measure — reserve a modest placeholder
        // footprint; the actual word/letter gap on screen is controlled
        // by `letterSpacing` / `wordSpacing` at the widget layer, not here.
        perLetterViewSize = Size(targetGlyphHeight * 0.5, targetGlyphHeight);
      } else {
        final bounds = parsedPath.getBounds();
        perLetterViewSize = Size(
          bounds.width * screenScale,
          bounds.height * screenScale,
        );
      }

      final dottedIndexPath = parseSvgPath(letterModel.indexPath);
      final dottedPath = parseSvgPath(letterModel.dottedPath);

      final transformedPath = _applyTransformation(
        parsedPath,
        perLetterViewSize,
      );

      final dottedPathTransformed = _applyTransformationForOtherPathsDotted(
          dottedPath,
          perLetterViewSize,
          letterModel.positionDottedPath,
          letterModel.scaledottedPath);
      final indexPathTransformed = _applyTransformationForOtherPathsIndex(
          dottedIndexPath,
          perLetterViewSize,
          letterModel.positionIndexPath,
          letterModel.scaleIndexPath);

      final allStrokePoints = await _loadPointsFromJson(
        letterModel.pointsJsonFile,
        perLetterViewSize,
      );
      final anchorPos =
          allStrokePoints.isNotEmpty ? allStrokePoints[0][0] : Offset.zero;

      model.add(LetterPathsModel(
          isSpace: letterModel.isSpace,
          viewSize: perLetterViewSize,
          disableDivededStrokes: letterModel.disableDividedStrokes,
          strokeIndex: letterModel.strokeIndex,
          strokeWidth: letterModel.strokeWidth,
          dottedIndex: dottedPathTransformed,
          letterIndex: indexPathTransformed,
          dottedColor: letterModel.dottedColor,
          indexColor: letterModel.indexColor,
          innerPaintColor: letterModel.innerPaintColor,
          outerPaintColor: letterModel.outerPaintColor,
          allStrokePoints: allStrokePoints,
          letterImage: transformedPath,
          anchorPos: anchorPos,
          distanceToCheck: letterModel.distanceToCheck,
          indexPathPaintStyle: letterModel.indexPathPaintStyle,
          dottedPathPaintStyle: letterModel.dottedPathPaintStyle));
    }

    emit(state.copyWith(
      letterPathsModels: model,
      drawingStates: DrawingStates.loaded,
    ));
  }

  // --- Everything below is UNCHANGED from the original package. Each
  // function still independently fits its own path into whatever
  // `viewSize` it's handed — the only thing that changed is what caller
  // passes in (see loadAssets above): a per-letter natural size derived
  // from one shared screenScale, instead of the fixed Size(200, 200).

  Path _applyTransformation(
    Path path,
    Size viewSize,
  ) {
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;
    double scale = math.min(scaleX, scaleY);

    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    return path.transform(matrix.storage);
  }

  Path _applyTransformationForOtherPathsIndex(
      Path path, Size viewSize, Size? size, double? pathscale) {
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;

    double scale = math.min(scaleX, scaleY);
    scale = pathscale == null ? scale : scale * pathscale;

    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    if (size != null) {
      matrix = Matrix4.identity()
        ..scale(scale, scale)
        ..translate(translateX + size.width, translateY + size.height);
    }
    return path.transform(matrix.storage);
  }

  Path _applyTransformationForOtherPathsDotted(
      Path path, Size viewSize, Size? size, double? pathscale) {
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;
    double scale = math.min(scaleX, scaleY);
    scale = pathscale == null ? scale : scale * pathscale;

    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    if (size != null) {
      matrix = Matrix4.identity()
        ..scale(scale, scale)
        ..translate(translateX + size.width, translateY + size.height);
    }
    return path.transform(matrix.storage);
  }

  Future<List<List<Offset>>> _loadPointsFromJson(
      String path, Size viewSize) async {
    final jsonString = await rootBundle.loadString('packages/tracing_game/$path');

    final jsonData = jsonDecode(jsonString);
    final List<List<Offset>> strokePointsList = [];

    for (var stroke in jsonData['strokes']) {
      final List<dynamic> strokePointsData = stroke['points'];
      final points = strokePointsData.map<Offset>((pointString) {
        final coords =
            pointString.split(',').map((e) => double.parse(e)).toList();
        return Offset(coords[0] * viewSize.width, coords[1] * viewSize.height);
      }).toList();
      strokePointsList.add(points);
    }

    return strokePointsList;
  }

  void handlePanStart(Offset position) {
    if (!isTracingStartPoint(position)) {
      return;
    }
emit(state.copyWith(drawingStates: DrawingStates.tracing));
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >= 0 &&
        state.letterPathsModels[state.activeIndex].currentStrokeProgress <
            currentStrokePoints.length) {
      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = Path()
            ..moveTo(singlePoint.dx, singlePoint.dy)
            ..lineTo(
                currentStrokePoints.first.dx, currentStrokePoints.first.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = singlePoint;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          completeStroke();
          return;
        }
      }
    } else if (state
            .letterPathsModels[state.activeIndex].currentStrokeProgress ==
        -1) {
      final currentStrokePoints =
          state.letterPathsModels[state.activeIndex].allStrokePoints[
              state.letterPathsModels[state.activeIndex].currentStroke];

      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = Path()..moveTo(singlePoint.dx, singlePoint.dy);
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath..lineTo(singlePoint.dx, singlePoint.dy);
          state.letterPathsModels[state.activeIndex].currentStrokeProgress = 1;
          completeStroke();
        } else {}
      } else {
        if (state.letterPathsModels[state.activeIndex].anchorPos != null) {
          final newDrawingPath = Path()
            ..moveTo(state.letterPathsModels[state.activeIndex].anchorPos!.dx,
                state.letterPathsModels[state.activeIndex].anchorPos!.dy);

          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;
          state.letterPathsModels[state.activeIndex].currentStrokeProgress = 1;
          emit(state.copyWith(
            letterPathsModels: state.letterPathsModels,
          ));
        } 
      }
    }
  }

  void handlePanUpdate(Offset position) {
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >= 0 &&
        state.letterPathsModels[state.activeIndex].currentStrokeProgress <
            currentStrokePoints.length) {
      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = state
              .letterPathsModels[state.activeIndex].currentDrawingPath
            ..lineTo(
                currentStrokePoints.first.dx, currentStrokePoints.first.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = singlePoint;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          completeStroke();
          return;
        } else {}
      } else {
        if (isValidPoint(
            currentStrokePoints[state
                .letterPathsModels[state.activeIndex].currentStrokeProgress],
            position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          state.letterPathsModels[state.activeIndex].currentStrokeProgress =
              state.letterPathsModels[state.activeIndex].currentStrokeProgress +
                  1;

          final point = currentStrokePoints[
              state.letterPathsModels[state.activeIndex].currentStrokeProgress -
                  1];

          final newDrawingPath = state
              .letterPathsModels[state.activeIndex].currentDrawingPath
            ..lineTo(point.dx, point.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = point;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          emit(state.copyWith(letterPathsModels: state.letterPathsModels));
        } else {}
      }
    }

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >=
        currentStrokePoints.length) {
      completeStroke();
    }
  }

  void completeStroke() {
    final currentModel = state.letterPathsModels[state.activeIndex];
    final currentStrokeIndex = currentModel.currentStroke;

    if (currentStrokeIndex < currentModel.allStrokePoints.length - 1) {
      currentModel.paths.add(currentModel.currentDrawingPath);

      currentModel.currentStroke = currentStrokeIndex + 1;
      currentModel.currentStrokeProgress = 0;

      final previousStrokePoints =
          currentModel.allStrokePoints[currentStrokeIndex];
      final endPointOfPreviousStroke = previousStrokePoints.isNotEmpty
          ? currentModel
              .allStrokePoints[currentModel.disableDivededStrokes != null &&
                      currentModel.disableDivededStrokes!
                  ? currentStrokeIndex + 1
                  : currentStrokeIndex]
              .first
          : Offset.zero;

      final newDrawingPath = Path()
        ..moveTo(endPointOfPreviousStroke.dx, endPointOfPreviousStroke.dy);
      currentModel.currentDrawingPath = newDrawingPath;
      currentModel.anchorPos =
          currentModel.allStrokePoints[currentModel.currentStroke].first;
      emit(state.copyWith(letterPathsModels: state.letterPathsModels));
    } else if (!currentModel.letterTracingFinished) {
      currentModel.letterTracingFinished = true;
      currentModel.hasFinishedOneStroke = true;
      if (state.activeIndex < state.letterPathsModels.length - 1) {
        emit(state.copyWith(
          activeIndex: (state.activeIndex + 1),
          letterPathsModels: state.letterPathsModels,
        ));
      } else if (state.index == state.numberOfScreens-1 ) {
    
        emit(state.copyWith(
            activeIndex: (state.activeIndex),
            letterPathsModels: state.letterPathsModels,
            drawingStates: DrawingStates.gameFinished));
      } else {
        emit(state.copyWith(
            activeIndex: (state.activeIndex),
            letterPathsModels: state.letterPathsModels,
            drawingStates: DrawingStates.finishedCurrentScreen));
      }
    }
  }

  bool isTracingStartPoint(Offset position) {
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (currentStrokePoints.length == 1) {
      return true;
    } else if (state.letterPathsModels[state.activeIndex].anchorPos != null) {
      final anchorRect = Rect.fromCenter(
          center: state.letterPathsModels[state.activeIndex].anchorPos!,
          width: 50,
          height: 50);
      bool contains = anchorRect.contains(position);
      return contains;
    }
    return false;
  }

  bool isValidPoint(Offset point, Offset position, double? distanceToCheck) {
    final validArea = distanceToCheck ?? 30.0;
    bool isValid = (position - point).distance < validArea;
    return isValid;
  }
}
