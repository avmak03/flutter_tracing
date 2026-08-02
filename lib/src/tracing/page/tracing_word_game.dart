import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracing_game/src/tracing/phonetics_paint_widget/phonetics_painter.dart';
import 'package:tracing_game/tracing_game.dart';

class TracingWordGame extends StatefulWidget {
  const TracingWordGame({
    super.key,
    required this.words,
    this.loadingIndictor = const CircularProgressIndicator(),
    this.showAnchor = true,
    this.onTracingUpdated,
    this.onGameFinished,
    this.onCurrentTracingScreenFinished,
    this.letterSpacing = 16,
    this.wordSpacing = 60,
    this.targetGlyphHeight = 200,
    this.anchorAssetPath,
    this.anchorBuilder,
  });
  final List<TraceWordModel> words;

  final Future<void> Function(int index)? onTracingUpdated;
  final Future<void> Function(int index)? onGameFinished;
  final Future<void> Function(int index)? onCurrentTracingScreenFinished;

  final Widget loadingIndictor;
  final bool showAnchor;

  /// Horizontal gap, in logical pixels, between adjacent letters within
  /// the same word.
  final double letterSpacing;

  /// Extra horizontal gap at a space between words. This replaces the
  /// old hardcoded 150px margin — same idea, just tunable, and additive
  /// on top of [letterSpacing] rather than a magic number.
  final double wordSpacing;

  /// The tallest glyph on a screen is scaled to this height, and every
  /// other glyph on that screen shares the same scale factor — see
  /// TracingCubit.targetGlyphHeight for the full rationale.
  final double targetGlyphHeight;

  /// Asset path for the "pointing finger" anchor image. Defaults to the
  /// package's bundled image if left null. Must resolve via your app's
  /// own `Image.asset` (your pubspec assets), not the package's.
  final String? anchorAssetPath;

  /// Full control over the anchor visual — takes priority over
  /// [anchorAssetPath] if provided.
  final Widget Function(BuildContext context)? anchorBuilder;

  @override
  State<StatefulWidget> createState() => _TracingWordGameState();
}

class _TracingWordGameState extends State<TracingWordGame> {
  late TracingCubit tracingCubit;

  @override
  void initState() {
    super.initState();

    tracingCubit = TracingCubit(
      stateOfTracing: StateOfTracing.traceWords,
      traceWordModels: widget.words,
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
      }, builder: (context, state) {
               if(widget.words.isEmpty){
              return const SizedBox();
            }
        if (state.drawingStates == DrawingStates.loading ||
            state.drawingStates == DrawingStates.initial) {
          return widget.loadingIndictor;
        }

        return FittedBox(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    state.letterPathsModels.length,
                    (index) {
                      final letterModel = state.letterPathsModels[index];
                      final isLast =
                          index == state.letterPathsModels.length - 1;

                      final gap = letterModel.isSpace
                          ? widget.wordSpacing
                          : (isLast ? 0.0 : widget.letterSpacing);

                      return Container(
                        height: letterModel.viewSize.height,
                        width: letterModel.viewSize.width,
                        margin: EdgeInsets.only(right: gap),
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
                                size: letterModel.viewSize,
                                painter: PhoneticsPainter(
                                  strokeIndex: letterModel.strokeIndex,
                                  indexPath: letterModel.letterIndex,
                                  dottedPath: letterModel.dottedIndex,
                                  letterColor: letterModel.outerPaintColor,
                                  letterImage: letterModel.letterImage!,
                                  paths: letterModel.paths,
                                  currentDrawingPath:
                                      letterModel.currentDrawingPath,
                                  pathPoints: letterModel.allStrokePoints
                                      .expand((p) => p)
                                      .toList(),
                                  strokeColor: letterModel.innerPaintColor,
                                  viewSize: letterModel.viewSize,
                                  strokePoints: letterModel.allStrokePoints[
                                      letterModel.currentStroke],
                                  strokeWidth: letterModel.strokeWidth,
                                  dottedColor: letterModel.dottedColor,
                                  indexColor: letterModel.indexColor,
                                  indexPathPaintStyle:
                                      letterModel.indexPathPaintStyle,
                                  dottedPathPaintStyle:
                                      letterModel.dottedPathPaintStyle,
                                ),
                              ),
                              if (state.activeIndex == index &&
                                  widget.showAnchor)
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
              ],
            ),
          ),
        );
      }),
    );
  }
}
