import 'package:flutter/material.dart';
import 'package:tracing_game/src/tracing/model/trace_shape_options.dart';
import 'package:tracing_game/tracing_game.dart';

class TraceCharsModel{
  final List<TraceCharModel> chars;

  TraceCharsModel({required this.chars,});
}

class TraceCharModel {
final  String char;
 final TraceShapeOptions traceShapeOptions;

  /// Manual per-letter scale correction, default 1.0 (no correction).
  /// Passed through to TraceModel.letterScaleOverride — see that field
  /// for the full rationale.
  final double letterScaleOverride;

  /// Calibration overrides for the dotted-spine guide, in the letter-
  /// anchored transform (see TracingCubit._applyTransformationForOtherPaths).
  /// Null means "use whatever is already set in the underlying data" —
  /// the calibration screen always passes concrete values (starting at
  /// Size.zero / 1.0) so it can tune from a clean, known baseline
  /// regardless of what the data file currently has.
  final Size? dottedOffsetOverride;
  final double? dottedScaleOverride;

  /// Same idea, for the index-arrow guide.
  final Size? indexOffsetOverride;
  final double? indexScaleOverride;

  TraceCharModel({
   required this.char,
    this.traceShapeOptions= const TraceShapeOptions(),
    this.letterScaleOverride = 1.0,
    this.dottedOffsetOverride,
    this.dottedScaleOverride,
    this.indexOffsetOverride,
    this.indexScaleOverride,
  });
}
