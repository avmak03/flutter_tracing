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
  /// for the full rationale. Set this from your app when you've
  /// calibrated a letter (see the calibration screen) and want the
  /// correction applied everywhere that letter is used.
  final double letterScaleOverride;

  TraceCharModel({
   required this.char,
    this.traceShapeOptions= const TraceShapeOptions(),
    this.letterScaleOverride = 1.0,
  });
}
