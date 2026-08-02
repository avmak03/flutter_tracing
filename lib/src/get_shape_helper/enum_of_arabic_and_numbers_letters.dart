import 'package:flutter/material.dart';
import 'package:tracing_game/src/colors/phonetics_color.dart';
import 'package:tracing_game/src/phontics_constants/english_shape_path2.dart';
import 'package:tracing_game/src/phontics_constants/math_trace_shape_paths.dart';
import 'package:tracing_game/src/phontics_constants/shape_paths.dart';
import 'package:tracing_game/src/points_manager/shape_points_manger.dart';
import 'package:tracing_game/src/tracing/model/trace_model.dart';
import 'package:tracing_game/tracing_game.dart';

class TypeExtensionTracking {
  List<TraceModel> getTracingData({
    List<TraceCharModel>? chars,
    TraceWordModel? word,
    required StateOfTracing currentOfTracking,
    List<MathShapeWithOption>? geometryShapes,
  }) {
  
    List<TraceModel> tracingDataList = [];

    if (currentOfTracking == StateOfTracing.traceShapes) {
      tracingDataList
          .addAll(getListOfTracingDataMathShapes(shapes: geometryShapes!));
    } else if (currentOfTracking == StateOfTracing.traceWords) {
      tracingDataList.addAll(getTraceWords(wordWithOption: word!));
    } else if (currentOfTracking == StateOfTracing.chars) {
        if(chars==null){
      return [];
    }
      for (var char in chars) {
        final letters = char.char;

        // Detect the type of letter and add the corresponding tracing data
        if (_isPhonicsCharacter(letters)) {
          tracingDataList.add(
              _getTracingDataPhonics(letter: letters.toLowerCase())
                  .first
                  .copyWith(
                    innerPaintColor: char.traceShapeOptions.innerPaintColor,
                    outerPaintColor: char.traceShapeOptions.outerPaintColor,
                    indexColor: char.traceShapeOptions.indexColor,
                    dottedColor: char.traceShapeOptions.dottedColor,
                  ));
        } else if (_isUpperCasePhonicsCharacter(letters)) {
          final uppers =
              _getTracingDataPhonicsUp(letter: letters.toLowerCase());
          final newBigSizedUppers = uppers
              .map((up) => up.copyWith(letterViewSize: const Size(300, 300)))
              .toList();
          tracingDataList.add(newBigSizedUppers.first.copyWith(
            innerPaintColor: char.traceShapeOptions.innerPaintColor,
            outerPaintColor: char.traceShapeOptions.outerPaintColor,
            indexColor: char.traceShapeOptions.indexColor,
            dottedColor: char.traceShapeOptions.dottedColor,
          ));
        } else {
          throw Exception('Unsupported character type for tracing.');
        }
      }
    } else {
      throw Exception('Unknown StateOfTracing value');
    }

    return tracingDataList; // Return the combined tracing data list
  }

// Helper functions to detect the type of letter

  bool _isPhonicsCharacter(String letter) {
    // Check if the letter is a valid phonics character (assuming it's A-Z or a-z)
    return RegExp(r'^[a-z]$').hasMatch(letter);
  }

  bool _isUpperCasePhonicsCharacter(String letter) {
    // Check if the letter is an uppercase phonics character
    return RegExp(r'^[A-Z]$').hasMatch(letter);
  }

  List<TraceModel> getListOfTracingDataMathShapes(
      {required List<MathShapeWithOption> shapes}) {
    List<TraceModel> traceModels = [];

    // Iterate over each MathShapes enum and generate a TraceModel for it
    for (var sh in shapes) {
      traceModels
          .add(getTracingDataMathShapes(currentLetter: sh.shape).first.copyWith(
                innerPaintColor: sh.traceShapeOptions.innerPaintColor,
                outerPaintColor: sh.traceShapeOptions.outerPaintColor,
                indexColor: sh.traceShapeOptions.indexColor,
                dottedColor: sh.traceShapeOptions.dottedColor,
              ));
    }

    return traceModels; // Return the list of enums
  }

  List<TraceModel> getTracingDataMathShapes(
      {required MathShapes currentLetter}) {
    switch (currentLetter) {
      case MathShapes.circle:
        final circ = TraceModel(
            letterViewSize: const Size(200, 200),
            positionIndexPath: const Size(100, -60),
            positionDottedPath: const Size(0, 0),
            scaledottedPath: .9,
            scaleIndexPath: .4,
            indexPathPaintStyle: PaintingStyle.stroke,
            dottedPath: MathTraceShapePaths.circleDottedPath,
            dottedColor: Colors.black,
            indexColor: AppColorPhonetics.grey,
            indexPath: MathTraceShapePaths.circleIndexPath,
            letterPath: MathTraceShapePaths.circleShapePath,
            strokeWidth: 30,
            strokeIndex: 1,
            pointsJsonFile: ShapePointsManger.mathCircleShape,
            innerPaintColor: AppColorPhonetics.lightBlueColor5,
            outerPaintColor: Colors.transparent);
        return [
          circ.copyWith(
            letterViewSize: const Size(200, 200),
          ),
        ];

      case MathShapes.rectangle:
        final rect = TraceModel(
            letterViewSize: const Size(200, 200),
            positionIndexPath: const Size(0, 15),
            positionDottedPath: const Size(10, -7),
            scaledottedPath: .95,
            scaleIndexPath: 1.4,
            indexPathPaintStyle: PaintingStyle.stroke,
            dottedPath: MathTraceShapePaths.rectangleDottedPath,
            dottedColor: Colors.black,
            indexColor: AppColorPhonetics.grey,
            indexPath: MathTraceShapePaths.rectangleIndexPath,
            letterPath: MathTraceShapePaths.rectangleShapePath,
            strokeWidth: 30,
            strokeIndex: 1,
            pointsJsonFile: ShapePointsManger.rectangleShape,
            innerPaintColor: AppColorPhonetics.lightBlueColor5,
            outerPaintColor: Colors.transparent);
        return [
          rect.copyWith(
            letterViewSize: const Size(160, 160),
          ),
        ];

      case MathShapes.triangle1:
        return [
          TraceModel(
              letterViewSize: const Size(150, 150),
              positionIndexPath: const Size(-5, 10),
              positionDottedPath: const Size(0, 3),
              scaledottedPath: .9,
              scaleIndexPath: 1.14,
              indexPathPaintStyle: PaintingStyle.stroke,
              dottedPath: MathTraceShapePaths.triangle1DottedPath,
              dottedColor: Colors.black,
              indexColor: AppColorPhonetics.grey,
              indexPath: MathTraceShapePaths.triangle1IndexPath,
              letterPath: MathTraceShapePaths.triangle1ShapePath,
              strokeWidth: 30,
              strokeIndex: 1,
              pointsJsonFile: ShapePointsManger.triangle1Shape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: Colors.transparent),
        ];

      case MathShapes.triangle2:
        return [
          TraceModel(
              letterViewSize: const Size(160, 160),
              positionIndexPath: const Size(5, 0),
              positionDottedPath: const Size(-5, 3),
              scaledottedPath: .85,
              scaleIndexPath: 1.1,
              indexPathPaintStyle: PaintingStyle.stroke,
              dottedPath: MathTraceShapePaths.triangle2DottedPath,
              dottedColor: Colors.black,
              indexColor: AppColorPhonetics.grey,
              indexPath: MathTraceShapePaths.triangle2IndexPath,
              letterPath: MathTraceShapePaths.triangle2ShapePath,
              strokeWidth: 30,
              strokeIndex: 1,
              pointsJsonFile: ShapePointsManger.triangle2Shape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: Colors.transparent),
        ];

      case MathShapes.triangle3:
        return [
          TraceModel(
              letterViewSize: const Size(180, 180),
              positionIndexPath: const Size(-8, 10),
              positionDottedPath: const Size(0, 3),
              scaledottedPath: .9,
              scaleIndexPath: 1.17,
              indexPathPaintStyle: PaintingStyle.stroke,
              dottedPath: MathTraceShapePaths.triangle3DottedPath,
              dottedColor: Colors.black,
              indexColor: AppColorPhonetics.grey,
              indexPath: MathTraceShapePaths.triangle3Index,
              letterPath: MathTraceShapePaths.triangle3ShapePath,
              strokeWidth: 40,
              strokeIndex: 1,
              pointsJsonFile: ShapePointsManger.triangle3Shape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: Colors.transparent),
        ];
      case MathShapes.triangle4:
        return [
          TraceModel(
              letterViewSize: const Size(150, 150),
              positionIndexPath: const Size(-10, 10),
              positionDottedPath: const Size(-5, 3),
              scaledottedPath: .85,
              scaleIndexPath: 1.25,
              indexPathPaintStyle: PaintingStyle.stroke,
              dottedPath: MathTraceShapePaths.triangle4DottedPath,
              dottedColor: Colors.black,
              indexColor: AppColorPhonetics.grey,
              indexPath: MathTraceShapePaths.triangle4IndexPath,
              letterPath: MathTraceShapePaths.triangle4ShapePath,
              strokeWidth: 35,
              strokeIndex: 1,
              pointsJsonFile: ShapePointsManger.triangle4Shape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: Colors.transparent),
        ];
    }
  }

  List<TraceModel> getTraceWords({
    required TraceWordModel wordWithOption,
    Size sizeOfLetter = const Size(500, 500),
  }) {
    List<TraceModel> letters = [];
    int i = 0;
    final word = wordWithOption.word;
    while (i < word.length) {
      bool isNextSpace = (i + 1 < word.length) &&
          word[i + 1] == ' '; // Check if the next character is a space

      if (_isPhonicsCharacter(word[i])) {
        letters.add(_getTracingDataPhonics(letter: word[i].toLowerCase())
            .first
            .copyWith(
              isSpace: isNextSpace,
            ));
      } else if (_isUpperCasePhonicsCharacter(word[i])) {
        final uppers = _getTracingDataPhonicsUp(letter: word[i].toLowerCase());
        final newBigSizedUppers = uppers
            .map((up) => up.copyWith(letterViewSize: const Size(300, 300)))
            .first;
        letters.add(newBigSizedUppers.copyWith(isSpace: isNextSpace));
      }

      i++; // Move to the next character
    }

    return letters
        .map((e) => e.copyWith(
              innerPaintColor: wordWithOption.traceShapeOptions.innerPaintColor,
              outerPaintColor: wordWithOption.traceShapeOptions.outerPaintColor,
              indexColor: wordWithOption.traceShapeOptions.indexColor,
              dottedColor: wordWithOption.traceShapeOptions.dottedColor,
            ))
        .toList();
  }

  List<TraceModel> _getTracingDataPhonics(
      {required String letter, Size sizeOfLetter = const Size(200, 200)}) {
    PhonicsLetters currentLetter =
        _detectTheCurrentEnumFromPhonics(letter: letter);

    switch (currentLetter) {
      case PhonicsLetters.n:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.nlowerShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.nlowerShapeIndex,
              strokeWidth: 70,
              disableDividedStrokes: true,
              scaleIndexPath: .3,
              positionDottedPath: const Size(0, 0),
              positionIndexPath: const Size(-50, -65),
              scaledottedPath: .75,
              letterPath: EnglishShapePaths2.nlowerShape,
              pointsJsonFile: ShapePointsManger.nLowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.e:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.eLowerShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.eLowerShapeIndex,
              strokeWidth: 70,
              disableDividedStrokes: true,
              scaleIndexPath: .12,
              positionDottedPath: const Size(0, 0),
              positionIndexPath: const Size(-20, -5),
              scaledottedPath: .75,
              letterPath: EnglishShapePaths2.eLowerShape,
              pointsJsonFile: ShapePointsManger.eLowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.w:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              dottedPath: EnglishShapePaths2.wBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.wBigShapeIndex,
              strokeWidth: 68,
              disableDividedStrokes: true,
              scaleIndexPath: .65,
              positionDottedPath: const Size(0, 10),
              positionIndexPath: const Size(-20, 5),
              scaledottedPath: .75,
              letterPath: EnglishShapePaths2.wBigShape,
              pointsJsonFile: ShapePointsManger.wUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.d:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.dLowerShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.dLowerShapeIndex,
              strokeWidth: 65,
              scaleIndexPath: .35,
              positionDottedPath: const Size(0, 10),
              positionIndexPath: const Size(30, -60),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.dLowerShape,
              pointsJsonFile: ShapePointsManger.dlowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.o:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              dottedPath: EnglishShapePaths2.oShapeBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.oShapeBigShapeIndex,
              strokeWidth: 60,
              scaleIndexPath: .15,
              positionDottedPath: const Size(5, 0),
              positionIndexPath: const Size(-10, -70),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.oShapeBigShape,
              pointsJsonFile: ShapePointsManger.oUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.g:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.gLowrShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.gLowrShapeIndex,
              strokeWidth: 60,
              scaleIndexPath: .2,
              positionIndexPath: const Size(40, -75),
              positionDottedPath: const Size(0, 0),
              scaledottedPath: .8,
              letterPath: EnglishShapePaths2.gLowrShape,
              pointsJsonFile: ShapePointsManger.glowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.f:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.fLowerShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.fLowerShapeIndex,
              strokeWidth: 45,
              scaleIndexPath: .4,
              positionIndexPath: const Size(10, -55),
              positionDottedPath: const Size(10, 0),
              scaledottedPath: .8,
              letterPath: EnglishShapePaths2.fLowerShape,
              pointsJsonFile: ShapePointsManger.flowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.b:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.blowerShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.blowerShapeIndex,
              strokeWidth: 50,
              scaleIndexPath: .4,
              positionIndexPath: const Size(-30, -55),
              positionDottedPath: const Size(0, 10),
              scaledottedPath: .8,
              letterPath: EnglishShapePaths2.blowerShape,
              pointsJsonFile: ShapePointsManger.blowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.l:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.lLowerShapeDotted,
              strokeWidth: 90,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              indexPath: EnglishShapePaths2.lLowerShapeIndex,
              scaleIndexPath: .1,
              scaledottedPath: .93,
              positionIndexPath: const Size(0, -55),
              positionDottedPath: const Size(5, 0),
              letterPath: EnglishShapePaths2.lLowerShape,
              pointsJsonFile: ShapePointsManger.llowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5)
        ];

      case PhonicsLetters.u:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.uLowerShapeDotted,
              strokeWidth: 80,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.uLowerShapeIndex,
              scaleIndexPath: .7,
              scaledottedPath: .8,
              positionIndexPath: const Size(0, -70),
              positionDottedPath: const Size(0, 10),
              letterPath: EnglishShapePaths2.uLowerShape,
              pointsJsonFile: ShapePointsManger.ulowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.j:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.jlowerShapeDotetd,
              strokeWidth: 50,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.jlowerShapeIndex,
              scaleIndexPath: .3,
              scaledottedPath: .65,
              positionIndexPath: const Size(22, -65),
              positionDottedPath: const Size(0, 25),
              letterPath: EnglishShapePaths2.jlowerShape,
              pointsJsonFile: ShapePointsManger.jlowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.h:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.hLowerShapeDotted,
              strokeWidth: 50,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.hlowerShapeIndex,
              scaleIndexPath: .45,
              scaledottedPath: .85,
              positionIndexPath: const Size(-40, -45),
              positionDottedPath: const Size(0, 10),
              letterPath: EnglishShapePaths2.hLoweCaseShape,
              pointsJsonFile: ShapePointsManger.hlowerShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.s:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              dottedPath: ShapePaths.sDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: ShapePaths.sIndex,
              strokeWidth: 75,
              scaleIndexPath: .65,
              positionIndexPath: const Size(-10, 0),
              scaledottedPath: .8,
              letterPath: ShapePaths.s3,
              pointsJsonFile: ShapePointsManger.sShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5)
        ];
      case PhonicsLetters.a:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.aDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: ShapePaths.aIndex,
              dottedPathPaintStyle: PaintingStyle.fill,
              indexPathPaintStyle: PaintingStyle.fill,
              scaleIndexPath: .3,
              positionIndexPath: const Size(50, -60),
              scaledottedPath: .8,
              letterPath: ShapePaths.aShape,
              strokeWidth: 67,
              pointsJsonFile: ShapePointsManger.aShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5)
        ];
      case PhonicsLetters.m:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.mDotted,
              strokeWidth: 65,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: ShapePaths.mIndex,
              indexPathPaintStyle: PaintingStyle.fill,
              scaleIndexPath: .6,
              scaledottedPath: .8,
              positionIndexPath: const Size(-30, -50),
              letterPath: ShapePaths.mshape,
              pointsJsonFile: ShapePointsManger.mShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.k:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.kshapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              positionIndexPath: const Size(-25, -30),
              positionDottedPath: const Size(-10, 10),
              strokeWidth: 70,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.kshapeIndex,
              scaleIndexPath: .6,
              scaledottedPath: .8,
              letterPath: ShapePaths.kshape,
              pointsJsonFile: ShapePointsManger.kShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.q:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.qshapeDotted,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(40, -80),
              strokeWidth: 50,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.qshapeIndex,
              scaleIndexPath: .2,
              scaledottedPath: .8,
              letterPath: ShapePaths.qshape,
              pointsJsonFile: ShapePointsManger.qShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.v:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.vShapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(-30, -0),
              strokeWidth: 52,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.vShapeIndex,
              scaleIndexPath: .9,
              scaledottedPath: .8,
              letterPath: ShapePaths.vshape,
              pointsJsonFile: ShapePointsManger.vShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.x:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.xDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(-0, -75),
              strokeWidth: 57,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.xIndex,
              scaleIndexPath: .7,
              scaledottedPath: .8,
              disableDividedStrokes: true,
              letterPath: ShapePaths.xShape,
              pointsJsonFile: ShapePointsManger.xShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.y:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.yshapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(-0, -65),
              strokeWidth: 60,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.yShapeIndex,
              scaleIndexPath: .6,
              scaledottedPath: .75,
              letterPath: ShapePaths.yshape,
              pointsJsonFile: ShapePointsManger.yShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.z:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.zShapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(0, 0),
              strokeWidth: 75,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.zShapeIndex,
              scaleIndexPath: .7,
              scaledottedPath: .8,
              letterPath: ShapePaths.zShape,
              pointsJsonFile: ShapePointsManger.zShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.t:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.tshapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: ShapePaths.tshapeIndex,
              letterPath: ShapePaths.tShape,
              strokeWidth: 50,
              scaledottedPath: .8,
              scaleIndexPath: .33,
              positionDottedPath: const Size(2, 10),
              positionIndexPath: const Size(-30, -60),
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              pointsJsonFile: ShapePointsManger.tShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.c:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              dottedPath: ShapePaths.cshapeDoted,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.cshapeIndex,
              strokeWidth: 50,
              scaleIndexPath: .1,
              positionIndexPath: const Size(140, -25),
              positionDottedPath: const Size(5, 0),
              scaledottedPath: .9,
              letterPath: ShapePaths.cshaped,
              pointsJsonFile: ShapePointsManger.cShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.r:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.rShapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              strokeWidth: 70,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.rshapeIndex,
              scaleIndexPath: .5,
              positionIndexPath: const Size(-10, -50),
              scaledottedPath: .8,
              letterPath: ShapePaths.rshape,
              pointsJsonFile: ShapePointsManger.rShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.i:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.iShapeDotetd,
              dottedPathPaintStyle: PaintingStyle.fill,
              indexPathPaintStyle: PaintingStyle.fill,
              positionDottedPath: const Size(12, 20),
              positionIndexPath: const Size(-15, -35),
              strokeWidth: 45,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.iShapeIndex,
              scaleIndexPath: .5,
              scaledottedPath: .5,
              letterPath: ShapePaths.iShape,
              pointsJsonFile: ShapePointsManger.iShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.p:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: ShapePaths.pShapeDotted,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              positionDottedPath: const Size(0, 5),
              positionIndexPath: const Size(-46, -70),
              strokeWidth: 40,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: ShapePaths.pShapeIndex,
              scaleIndexPath: .2,
              scaledottedPath: .9,
              letterPath: ShapePaths.pShape,
              pointsJsonFile: ShapePointsManger.pShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
    
    }
  }

  List<TraceModel> _getTracingDataPhonicsUp(
      {required String letter, Size sizeOfLetter = const Size(200, 200)}) {
    PhonicsLetters currentLetter =
        _detectTheCurrentEnumFromPhonics(letter: letter);

    switch (currentLetter) {
      case PhonicsLetters.l:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.lBigShapeDotted,
              strokeWidth: 75,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              indexPath: EnglishShapePaths2.lBigShapeIndex,
              scaleIndexPath: .85,
              scaledottedPath: .8,
              positionIndexPath: const Size(-45, 0),
              positionDottedPath: const Size(0, 10),
              letterPath: EnglishShapePaths2.lBigShape,
              pointsJsonFile: ShapePointsManger.lUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.u:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.uBigShapeDotted,
              strokeWidth: 70,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.uBigShapeIndex,
              scaleIndexPath: .15,
              scaledottedPath: .93,
              positionIndexPath: const Size(-50, -70),
              positionDottedPath: const Size(5, 0),
              letterPath: EnglishShapePaths2.uBigShape,
              pointsJsonFile: ShapePointsManger.uUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.j:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.jBigShapeDotted,
              strokeWidth: 40,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.jBigShapeIndex,
              scaleIndexPath: .28,
              scaledottedPath: .93,
              positionIndexPath: const Size(-22, -70),
              positionDottedPath: const Size(0, 0),
              letterPath: EnglishShapePaths2.jBigShape,
              pointsJsonFile: ShapePointsManger.jUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.h:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.hBigShapeDotted,
              strokeWidth: 50,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.hBigShapeIndex,
              scaleIndexPath: .75,
              scaledottedPath: .8,
              positionIndexPath: const Size(0, -45),
              positionDottedPath: const Size(0, 10),
              letterPath: EnglishShapePaths2.hBigShape,
              pointsJsonFile: ShapePointsManger.hUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.o:
        return [
          _getTracingDataPhonics(
                  letter: 'o', sizeOfLetter: const Size(200, 200))
              .first,
        ];

      case PhonicsLetters.g:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.gShapeBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.gShapeBigShapeIndex,
              strokeWidth: 60,
              scaleIndexPath: .4,
              positionIndexPath: const Size(40, -30),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.gShapeBigShape,
              pointsJsonFile: ShapePointsManger.gUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.f:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.fShapeBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.fShapeBigShapeIndex,
              strokeWidth: 60,
              scaleIndexPath: .5,
              positionIndexPath: const Size(-45, -40),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.fShapeBigShape,
              pointsJsonFile: ShapePointsManger.fUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.d:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.dBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.dBigShapeIndex,
              strokeWidth: 75,
              scaleIndexPath: .3,
              positionIndexPath: const Size(-45, -80),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.dBigShape,
              pointsJsonFile: ShapePointsManger.dUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.w:
        return [
          _getTracingDataPhonics(
                  letter: 'w', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.e:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.eBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.eBigShapeIndex,
              strokeWidth: 75,
              scaleIndexPath: .8,
              positionIndexPath: const Size(-20, 0),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.eBigShape,
              pointsJsonFile: ShapePointsManger.eUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.n:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.nBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.nBigShapeIndex,
              strokeWidth: 63,
              scaleIndexPath: .94,
              distanceToCheck: 25,
              disableDividedStrokes: true,
              positionIndexPath: const Size(0, 0),
              scaledottedPath: .87,
              letterPath: EnglishShapePaths2.nBigShape,
              pointsJsonFile: ShapePointsManger.nUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.b:
        return [
          TraceModel(
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              dottedPath: EnglishShapePaths2.bShapeBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.bShapeBigShapeIndex,
              strokeWidth: 60,
              scaleIndexPath: .25,
              positionIndexPath: const Size(-30, -80),
              scaledottedPath: .85,
              letterPath: EnglishShapePaths2.bShapeBigShape,
              pointsJsonFile: ShapePointsManger.bUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];

      case PhonicsLetters.s:
        // s phone
        return [
          _getTracingDataPhonics(
                  letter: 's', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.a:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.aShapeBigDotted,
              dottedColor: AppColorPhonetics.white,
              disableDividedStrokes: true,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.aShapeBigShapeIndex,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              scaleIndexPath: .67,
              positionIndexPath: const Size(-15, -20),
              scaledottedPath: .8,
              letterPath: EnglishShapePaths2.aShapeBigShape,
              strokeWidth: 65,
              pointsJsonFile: ShapePointsManger.aUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.m:
        return [
          TraceModel(
              letterViewSize: sizeOfLetter,
              dottedPath: EnglishShapePaths2.mSHapeBigDoted,
              strokeWidth: 60,
              disableDividedStrokes: true,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPath: EnglishShapePaths2.mShapeBigIndex,
              scaleIndexPath: .9,
              scaledottedPath: .9,
              positionIndexPath: const Size(0, 2),
              letterPath: EnglishShapePaths2.mShapeBigShape,
              pointsJsonFile: ShapePointsManger.mUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.k:
        return [
          _getTracingDataPhonics(
                  letter: 'k', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.q:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.qBigShapeDotted,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              positionIndexPath: const Size(10, 55),
              strokeWidth: 40,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: EnglishShapePaths2.qBigShapesIndex,
              scaleIndexPath: .3,
              scaledottedPath: .9,
              letterPath: EnglishShapePaths2.qBigShapes,
              pointsJsonFile: ShapePointsManger.qUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.v:
        return [
          _getTracingDataPhonics(
                  letter: 'v', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.x:
        return [
          _getTracingDataPhonics(
                  letter: 'x', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.y:
        return [
          _getTracingDataPhonics(
                  letter: 'y', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.z:
        return [
          _getTracingDataPhonics(
                  letter: 'z', sizeOfLetter: const Size(200, 200))
              .first,
        ];
      case PhonicsLetters.t:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.tShapeBigShapeDotted,
              dottedColor: AppColorPhonetics.white,
              indexColor: AppColorPhonetics.grey,
              indexPath: EnglishShapePaths2.tShapeBigShapeIndex,
              letterPath: EnglishShapePaths2.tShapeBigShape,
              strokeWidth: 50,
              scaledottedPath: .8,
              scaleIndexPath: .35,
              disableDividedStrokes: true,
              positionDottedPath: const Size(5, -5),
              positionIndexPath: const Size(-30, -70),
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              pointsJsonFile: ShapePointsManger.tUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.c:
        return [
          _getTracingDataPhonics(letter: 'c').first,
        ];
      case PhonicsLetters.r:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.rShapeBigShapeDotted,
              indexPathPaintStyle: PaintingStyle.fill,
              dottedPathPaintStyle: PaintingStyle.fill,
              strokeWidth: 60,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: EnglishShapePaths2.rShapeBigShapeIndex,
              scaleIndexPath: .5,
              positionIndexPath: const Size(-20, -40),
              scaledottedPath: .9,
              letterPath: EnglishShapePaths2.rShapeBigShape,
              pointsJsonFile: ShapePointsManger.rUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.i:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.iShapeBigShapeDotted,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              positionDottedPath: const Size(10, 0),
              positionIndexPath: const Size(-22, 0),
              strokeWidth: 60,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: EnglishShapePaths2.iShapeBigShapeIndex,
              scaleIndexPath: .95,
              scaledottedPath: .9,
              letterPath: EnglishShapePaths2.iShapeBigShape,
              pointsJsonFile: ShapePointsManger.iUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
      case PhonicsLetters.p:
        return [
          TraceModel(
              dottedPath: EnglishShapePaths2.pBigShapeDotted,
              dottedPathPaintStyle: PaintingStyle.stroke,
              indexPathPaintStyle: PaintingStyle.fill,
              positionDottedPath: const Size(-5, 5),
              positionIndexPath: const Size(-40, -80),
              strokeWidth: 40,
              dottedColor: AppColorPhonetics.grey,
              indexColor: AppColorPhonetics.white,
              indexPath: EnglishShapePaths2.pBigShapeIndex,
              scaleIndexPath: .25,
              scaledottedPath: .92,
              letterPath: EnglishShapePaths2.pBigShape,
              pointsJsonFile: ShapePointsManger.pUpperShape,
              innerPaintColor: AppColorPhonetics.lightBlueColor5,
              outerPaintColor: AppColorPhonetics.lightBlueColor5),
        ];
    }
  }
}
