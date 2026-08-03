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
  /// Every letter is scaled to this height (logical px), using ONLY its
  /// own bounds — not compared against other letters on the same screen.
  /// Comparing raw SVG bounding-box sizes ACROSS different letters isn't
  /// reliable with this asset set (the source SVGs weren't authored on a
  /// shared canvas/scale per letter), so this does NOT do cross-letter
  /// scale-sharing. What it does do, relative to the original package:
  ///   - every letter still ends up a consistent height (like the
  ///     original's fixed-box behavior), avoiding the "some letters
  ///     tiny, some huge" breakage that a shared cross-letter scale
  ///     produces with this data,
  ///   - but each letter's box WIDTH is computed from its own true
  ///     aspect ratio at that height, instead of being squashed into a
  ///     fixed square — so downstream spacing reflects each letter's
  ///     real relative width (e.g. "i" narrower than "m").
  /// True cross-letter stroke-width matching (e.g. K's legs exactly as
  /// thick as I's stem) isn't achievable this way — that would require
  /// the source SVGs themselves to be authored/recalibrated on one
  /// consistent scale, which is a data problem, not something this
  /// transform step can fix.
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

    // Each letter is scaled using ONLY its own bounds — see the
    // targetGlyphHeight doc comment above for why cross-letter
    // comparison isn't safe with this asset set. Scaling purely by
    // height (rather than the original's min(scaleX, scaleY) fit into
    // a fixed square) means the box width comes out as this letter's
    // true aspect ratio at that height, instead of being forced square.
    List<LetterPathsModel> model = [];
    for (final letterModel in state.traceLetter) {
      final parsedPath = parseSvgPath(letterModel.letterPath);
      final bounds = parsedPath.getBounds();

      final double scale = bounds.height > 0
          ? (targetGlyphHeight / bounds.height) * letterModel.letterScaleOverride
          : 1.0;
      final Size perLetterViewSize = Size(
        bounds.width * scale,
        bounds.height * scale,
      );

      final dottedIndexPath = parseSvgPath(letterModel.indexPath);
      final dottedPath = parseSvgPath(letterModel.dottedPath);

      // Explicit fill rule for the letter's own filled shape. Several
      // letters (b, t, ...) are built from overlapping/self-intersecting
      // sub-paths; Flutter's default nonZero winding rule can leave
      // slivers unfilled where those sub-paths' windings cancel out.
      // evenOdd toggles fill per-crossing instead. Kept as its own
      // isolated change (independent of the guide-path fix above) so
      // it can be verified/reverted on its own if it turns out wrong.
      parsedPath.fillType = PathFillType.evenOdd;

      final transformedPath = _applyTransformation(
        parsedPath,
        perLetterViewSize,
      );

      // Guide paths are anchored to the LETTER's own bounds/scale, not
      // independently re-fit — see the comment above
      // _applyTransformationForOtherPaths for the full rationale and
      // the verified transform math.
      final dottedPathTransformed = _applyTransformationForOtherPaths(
          dottedPath,
          bounds,
          scale,
          letterModel.positionDottedPath,
          letterModel.scaledottedPath);
      final indexPathTransformed = _applyTransformationForOtherPaths(
          dottedIndexPath,
          bounds,
          scale,
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

  // _applyTransformation (letter shape) is UNCHANGED from the original
  // package — still independently fits the letter's own path into
  // whatever `viewSize` it's handed. _applyTransformationForOtherPaths
  // (below it) is NOT unchanged — see its own doc comment for why.

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

  // _applyTransformationForOtherPaths (dotted spine + index arrows):
  // anchored to the LETTER's own bounds/scale, not independently re-fit
  // from the guide's own bounds. Verified transform rule (numerically
  // checked against _applyTransformation's own working centering
  // formula before writing this): `..scale(s)..translate(tx,ty)`
  // produces `finalPoint = s*originalPoint + (tx,ty)` — the translate
  // is a RAW, UNSCALED offset applied in already-scaled output pixels,
  // not multiplied by scale. That means `offset` below behaves as a
  // fixed number of visual pixels regardless of the letter's own
  // scale — exactly what a calibration slider needs to behave
  // predictably across differently-scaled letters.
  //
  // Base position: auto-center the guide's own bounding-box center
  // onto the letter's own rendered center (letterImage's box spans
  // [0, letterBounds.width*letterScale] x [0, letterBounds.height*
  // letterScale], since _applyTransformation maps letterBounds.topLeft
  // to the origin). `offset` and `extraScale` are then a nudge on top
  // of that auto-centered guess — fresh calibration values, since the
  // old position/scale numbers in the data were calibrated against a
  // different (independent-refit) system and no longer apply.
  Path _applyTransformationForOtherPaths(
    Path path,
    Rect letterBounds,
    double letterScale,
    Size? offset,
    double? extraScale,
  ) {
    final Rect guideBounds = path.getBounds();
    final double effectiveScale = letterScale * (extraScale ?? 1.0);

    final double letterCenterFinalX = letterBounds.width * letterScale / 2;
    final double letterCenterFinalY = letterBounds.height * letterScale / 2;

    final double translateX = letterCenterFinalX -
        effectiveScale * guideBounds.center.dx +
        (offset?.width ?? 0);
    final double translateY = letterCenterFinalY -
        effectiveScale * guideBounds.center.dy +
        (offset?.height ?? 0);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(effectiveScale, effectiveScale)
      ..translate(translateX, translateY);

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
