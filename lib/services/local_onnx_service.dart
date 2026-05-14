import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import 'roboflow_freshness_service.dart';

class LocalOnnxFreshnessService {
  static const String _modelAssetPath = 'assets/models/fresh_rotten.onnx';

  static OnnxRuntime? _ort;
  static OrtSession? _session;
  static bool _isInitializing = false;

  static Future<void> _ensureInitialized() async {
    if (_session != null) return;

    if (_isInitializing) {
      while (_isInitializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      _ort = OnnxRuntime();
      _session = await _ort!.createSessionFromAsset(_modelAssetPath);
      debugPrint('Local ONNX model loaded successfully.');
    } finally {
      _isInitializing = false;
    }
  }

  static Future<RoboflowImagePrediction?> analyzeImage(File imageFile) async {
    try {
      await _ensureInitialized();

      final session = _session;
      if (session == null) {
        debugPrint('ONNX session is null.');
        return null;
      }

      final input = await _preprocessImage(imageFile);

      final inputs = {
        'input': await OrtValue.fromList(input, [1, 3, 224, 224]),
      };

      final outputs = await session.run(inputs);

      final outputValue = outputs['logits'] ?? outputs.values.first;
      final outputList = await outputValue.asList();

      final logits = _flattenToDoubleList(outputList);

      if (logits.length < 2) {
        debugPrint('ONNX output did not contain 2 logits: $logits');
        return null;
      }

      final probs = _softmax([logits[0], logits[1]]);

      final fresh = probs[0];
      final rotten = probs[1];

      final label = fresh >= rotten ? 'fresh' : 'rotten';
      final confidence = math.max(fresh, rotten);

      return RoboflowImagePrediction(
        label: label,
        confidence: confidence,
        rawResponse: {
          'source': 'local_onnx',
          'fresh': fresh,
          'rotten': rotten,
          'label': label,
          'confidence': confidence,
        },
      );
    } catch (e, st) {
      debugPrint('Local ONNX image analysis failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  static Future<Float32List> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not decode image.');
    }

    final oriented = img.bakeOrientation(decoded);

    const int imgSize = 224;
    final int resizeSize = (imgSize * 1.14).round();

    final int width = oriented.width;
    final int height = oriented.height;

    late img.Image resized;

    if (width < height) {
      final newWidth = resizeSize;
      final newHeight = (height * resizeSize / width).round();
      resized = img.copyResize(oriented, width: newWidth, height: newHeight);
    } else {
      final newHeight = resizeSize;
      final newWidth = (width * resizeSize / height).round();
      resized = img.copyResize(oriented, width: newWidth, height: newHeight);
    }

    final int left = ((resized.width - imgSize) / 2).floor();
    final int top = ((resized.height - imgSize) / 2).floor();

    final cropped = img.copyCrop(
      resized,
      x: left,
      y: top,
      width: imgSize,
      height: imgSize,
    );

    final input = Float32List(1 * 3 * imgSize * imgSize);

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    int index = 0;

    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < imgSize; y++) {
        for (int x = 0; x < imgSize; x++) {
          final pixel = cropped.getPixel(x, y);

          double value;

          if (c == 0) {
            value = pixel.r / 255.0;
          } else if (c == 1) {
            value = pixel.g / 255.0;
          } else {
            value = pixel.b / 255.0;
          }

          input[index++] = ((value - mean[c]) / std[c]).toDouble();
        }
      }
    }

    return input;
  }

  static List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((x) => x / sum).toList();
  }

  static List<double> _flattenToDoubleList(dynamic value) {
    final result = <double>[];

    void walk(dynamic item) {
      if (item is num) {
        result.add(item.toDouble());
      } else if (item is Float32List) {
        for (final subItem in item) {
          result.add(subItem.toDouble());
        }
      } else if (item is List) {
        for (final subItem in item) {
          walk(subItem);
        }
      }
    }

    walk(value);
    return result;
  }

  static Future<void> dispose() async {
    _session = null;
    _ort = null;
  }
}