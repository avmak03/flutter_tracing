
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracing_game/src/tracing/phonetics_paint_widget/phonetics_painter.dart';
import 'package:tracing_game/tracing_game.dart';

class TracingGeometricShapesGame extends StatefulWidget {
  const TracingGeometricShapesGame({
    super.key,
    required this.traceGeoMetricShapeModels,
    this.loadingIndictor = const CircularProgressIndicator(),
    this.showAnchor = true,
    this.onTracingUpdated,
    this.onGameFinished,
    this.onCurrentTracingScreenFinished,
    this.shapeSpacing = 50,
    this.targetGlyphHeight = 200,
    this.anchorAssetPath,
    this.anchorBuilder,
  });
  final List<TraceGeoMetricShapeModel> traceGeoMetricShapeModels;
  final Widget loadingIndictor;
  final bool showAnchor;

  /// Horizontal gap, in logical pixels, between adjacent shapes.
  final double shapeSpacing;

  /// The tallest shape on a screen is scaled to this height, and every
  /// other shape on that screen shares the same scale factor — see
  /// TracingCubit.targetGlyphHeight for the full rationale.
  final double targetGlyphHeight;

  /// Asset path for the "pointing finger" anchor image. Defaults to the
  /// package's bundled image if left null. Must resolve via your app's
  /// own `Image.asset` (your pubspec assets), not the package's.
  final String? anchorAssetPath;

  /// Full control over the anchor visual — takes priority over
  /// [anchorAssetPath] if provided.
  final Widget Function(BuildContext context)? anchorBuilder;

final Future<void> Function(int index)? onTracingUpdated;
final  Future<void> Function(int index)? onGameFinished;
 final  Future<void> Function(int index)? onCurrentTracingScreenFinished;

  @override
  State<StatefulWidget> createState() => _TracingGeometricShapesGameState();
}

class _TracingGeometricShapesGameState
    extends State<TracingGeometricShapesGame> {
  late TracingCubit tracingCubit;

  @override
  void initState() {
    super.initState();
    tracingCubit = TracingCubit(
      stateOfTracing: StateOfTracing.traceShapes,
      traceGeoMetricShapeModel: widget.traceGeoMetricShapeModels,
      targetGlyphHeight: widget.targetGlyphHeight,
    );
  }

  Widget _buildAnchor(BuildContext context) {
    if (widget.anchorBuilder != null) {
      return widget.anchorBuilder!(context);
    }
    return Image.asset(
      widget.anchorAssetPath ??
          'packages/tracing_game/assets/images/position_2_finger.png',
      height: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => tracingCubit,
        child: BlocConsumer<TracingCubit, TracingState>(
          listener: (context, stateOfGame) async {
         if (stateOfGame.drawingStates == DrawingStates.tracing) {
          if (widget.onTracingUpdated != null) {
            await widget.onTracingUpdated!(stateOfGame.activeIndex);
          }
        } else if (stateOfGame.drawingStates ==
            DrawingStates.finishedCurrentScreen) {
          if (widget.onCurrentTracingScreenFinished != null) {
            await widget.onCurrentTracingScreenFinished!(stateOfGame.index + 1);
          }
          if (context.mounted) {
            tracingCubit.updateIndex();
          }
        } else if (stateOfGame.drawingStates == DrawingStates.gameFinished) {
          if (widget.onGameFinished != null) {
            await widget.onGameFinished!(stateOfGame.index);
          }
        }
          },
          builder: (context, state) {
            if(widget.traceGeoMetricShapeModels.isEmpty){
              return const SizedBox();
            }
            if (state.drawingStates == DrawingStates.loading ||
                state.drawingStates == DrawingStates.initial) {
              return widget.loadingIndictor;
            }

            if (state.letterPathsModels.isEmpty) {
              return const SizedBox();
            }

            return FittedBox(
              child: 
              Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      state.letterPathsModels.length,
                      (index) {
                        final shapeModel = state.letterPathsModels[index];
                        final isLast =
                            index == state.letterPathsModels.length - 1;

                        return Container(
                          height: shapeModel.viewSize.height,
                          width: shapeModel.viewSize.width,
                          padding: EdgeInsets.only(
                            right: isLast ? 0 : widget.shapeSpacing,
                          ),
                          child: GestureDetector(
                              onPanStart: (details) {
                                if (index == state.activeIndex) {
                                  tracingCubit
                                      .handlePanStart(details.localPosition);
                                }
                              },
                              onPanUpdate: (details) {
                                if (index == state.activeIndex) {
                                  tracingCubit
                                      .handlePanUpdate(details.localPosition);
                                }
                              },
                              onPanEnd: (details) {},
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CustomPaint(
                                    size: shapeModel.viewSize,
                                    painter: PhoneticsPainter(
                                      strokeIndex: shapeModel.strokeIndex,
                                      indexPath: shapeModel.letterIndex,
                                      dottedPath: shapeModel.dottedIndex,
                                      letterColor: shapeModel.outerPaintColor,
                                      letterImage: shapeModel.letterImage!,
                                      paths: shapeModel.paths,
                                      currentDrawingPath:
                                          shapeModel.currentDrawingPath,
                                      pathPoints: shapeModel.allStrokePoints
                                          .expand((p) => p)
                                          .toList(),
                                      strokeColor: shapeModel.innerPaintColor,
                                      viewSize: shapeModel.viewSize,
                                      strokePoints: shapeModel.allStrokePoints[
                                          shapeModel.currentStroke],
                                      strokeWidth: shapeModel.strokeWidth,
                                      dottedColor: shapeModel.dottedColor,
                                      indexColor: shapeModel.indexColor,
                                      indexPathPaintStyle:
                                          shapeModel.indexPathPaintStyle,
                                      dottedPathPaintStyle:
                                          shapeModel.dottedPathPaintStyle,
                                    ),
                                  ),
                                    if (state.activeIndex == index && widget.showAnchor)
                                    Positioned(
                                      top: state
                                          .letterPathsModels[state.activeIndex]
                                          .anchorPos!
                                          .dy,
                                      left: state
                                          .letterPathsModels[state.activeIndex]
                                          .anchorPos!
                                          .dx,
                                      child: _buildAnchor(context),
                                    ),
                                ],
                              ),
                            ),
                        );
                      },
                    ),
                  ),
                ),
              
            );
          },
        ));
  }
}
