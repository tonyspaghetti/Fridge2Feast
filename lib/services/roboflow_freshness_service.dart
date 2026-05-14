import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'local_onnx_service.dart';

class RoboflowImagePrediction {
  final String label;
  final double confidence;
  final Map<String, dynamic> rawResponse;

  const RoboflowImagePrediction({
    required this.label,
    required this.confidence,
    required this.rawResponse,
  });

  bool get foundPrediction => label.trim().isNotEmpty;
}

class FreshnessInput {
  final String foodName;
  final DateTime? purchaseDate;
  final String storageMethod;
  final String smell;
  final String texture;
  final String appearance;
  final bool hasMold;
  final bool hasSlime;
  final File? imageFile;

  const FreshnessInput({
    required this.foodName,
    required this.purchaseDate,
    required this.storageMethod,
    required this.smell,
    required this.texture,
    required this.appearance,
    required this.hasMold,
    required this.hasSlime,
    required this.imageFile,
  });
}

class FreshnessResult {
  final String status;
  final int score;
  final int estimatedDaysLeft;
  final String confidence;
  final List<String> reasons;
  final RoboflowImagePrediction? imagePrediction;

  const FreshnessResult({
    required this.status,
    required this.score,
    required this.estimatedDaysLeft,
    required this.confidence,
    required this.reasons,
    required this.imagePrediction,
  });

  bool get isUnsafe => status == 'Unsafe';
}

class RoboflowFreshnessService {
  // Roboflow classification model. You can override these at build time:
  // flutter run --dart-define=ROBOFLOW_API_KEY=your_key \
  //   --dart-define=ROBOFLOW_MODEL_ID=fresh-and-rotten-fruit \
  //   --dart-define=ROBOFLOW_MODEL_VERSION=3
  static const String _apiKey = String.fromEnvironment(
    'ROBOFLOW_API_KEY',
    defaultValue: 'PASTE_YOUR_ROBOFLOW_API_KEY_HERE',
  );

  static const String _modelId = String.fromEnvironment(
    'ROBOFLOW_MODEL_ID',
    defaultValue: 'fresh-and-rotten-fruit',
  );

  static const int _modelVersion = int.fromEnvironment(
    'ROBOFLOW_MODEL_VERSION',
    defaultValue: 3,
  );

  static const String _baseUrl = String.fromEnvironment(
    'ROBOFLOW_BASE_URL',
    defaultValue: 'https://classify.roboflow.com',
  );

static bool get _isConfigured {
  final configured = _apiKey.trim().isNotEmpty &&
      !_apiKey.contains('PASTE_YOUR') &&
      _modelId.trim().isNotEmpty &&
      !_modelId.contains('PASTE_YOUR');

  debugPrint('--- Roboflow Config Debug ---');
  debugPrint('Configured: $configured');
  debugPrint('Base URL: $_baseUrl');
  debugPrint('Model ID: $_modelId');
  debugPrint('Model Version: $_modelVersion');
  debugPrint('API Key present: ${_apiKey.trim().isNotEmpty}');
  debugPrint('API Key is placeholder: ${_apiKey.contains('PASTE_YOUR')}');
  debugPrint('API Key length: ${_apiKey.length}');
  debugPrint('-----------------------------');

  return configured;
}

static Future<RoboflowImagePrediction?> analyzeImage(File imageFile) async {
  debugPrint('Starting Roboflow image analysis...');

  if (!_isConfigured) {
    debugPrint('Roboflow is NOT configured. Check API key dart-define.');
    return null;
  }

  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  debugPrint('Image bytes length: ${bytes.length}');
  debugPrint('Base64 image length: ${base64Image.length}');

  final uri = Uri.parse('$_baseUrl/$_modelId/$_modelVersion').replace(
    queryParameters: {'api_key': _apiKey},
  );

  debugPrint('Roboflow URL without key: $_baseUrl/$_modelId/$_modelVersion');
  debugPrint('Sending request to Roboflow...');

  final response = await http
      .post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      )
      .timeout(const Duration(seconds: 20));

  debugPrint('Roboflow status code: ${response.statusCode}');
  debugPrint('Roboflow raw response: ${response.body}');

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Roboflow request failed: ${response.statusCode} ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    debugPrint('Roboflow response was not a JSON object.');
    return null;
  }

  final prediction = _extractBestPrediction(decoded);

  if (prediction == null) {
    debugPrint('Could not extract prediction from Roboflow response.');
    return null;
  }

  debugPrint(
    'Parsed prediction: ${prediction.label}, confidence: ${prediction.confidence}',
  );

return RoboflowImagePrediction(
  label: prediction.label,
  confidence: prediction.confidence,
  rawResponse: {
    ...decoded,
    'source': 'roboflow_fallback',
  },
);
}

static Future<RoboflowImagePrediction?> analyzeImageWithFallback(
  File imageFile, {
  Duration localTimeout = const Duration(seconds: 20),
  Duration roboflowTimeout = const Duration(seconds: 20),
}) async {
  try {
    debugPrint('Trying local ONNX model first...');

    final localPrediction = await LocalOnnxFreshnessService
        .analyzeImage(imageFile)
        .timeout(localTimeout);

    if (localPrediction != null) {
      debugPrint(
        'Local ONNX succeeded: ${localPrediction.label}, '
        '${(localPrediction.confidence * 100).toStringAsFixed(1)}%',
      );
      return localPrediction;
    }

    debugPrint('Local ONNX returned null. Falling back to Roboflow...');
  } on TimeoutException {
    debugPrint(
      'Local ONNX exceeded ${localTimeout.inSeconds} seconds. '
      'Falling back to Roboflow...',
    );
  } catch (e, st) {
    debugPrint('Local ONNX failed. Falling back to Roboflow...');
    debugPrint('$e');
    debugPrint('$st');
  }

  try {
    final roboflowPrediction = await analyzeImage(imageFile)
        .timeout(roboflowTimeout);

    if (roboflowPrediction != null) {
      debugPrint(
        'Roboflow fallback succeeded: ${roboflowPrediction.label}, '
        '${(roboflowPrediction.confidence * 100).toStringAsFixed(1)}%',
      );
    } else {
      debugPrint('Roboflow fallback returned null.');
    }

    return roboflowPrediction;
  } on TimeoutException {
    debugPrint('Roboflow fallback timed out.');
    return null;
  } catch (e, st) {
    debugPrint('Roboflow fallback failed.');
    debugPrint('$e');
    debugPrint('$st');
    return null;
  }
}

  static _ParsedPrediction? _extractBestPrediction(Map<String, dynamic> json) {
    final candidates = <_ParsedPrediction>[];

    void addCandidate(dynamic labelValue, dynamic confidenceValue) {
      final label = labelValue?.toString().trim() ?? '';
      final confidence = _normalizeConfidence(_asDouble(confidenceValue));

      if (label.isEmpty) return;
      if (_isMetadataLabel(label)) return;

      candidates.add(
        _ParsedPrediction(label: label, confidence: confidence),
      );
    }

    // Common Roboflow classification response:
    // {
    //   "predictions": {
    //     "freshapples": {"confidence": 0.91},
    //     "rottenapples": {"confidence": 0.04}
    //   },
    //   "top": "freshapples",
    //   "confidence": 0.91
    // }
    final top = json['top'] ?? json['predicted_class'] ?? json['class'];
    if (top != null) {
      addCandidate(top, json['confidence'] ?? json['top_confidence']);
    }

    final predictedClasses = json['predicted_classes'];
    if (predictedClasses is List && predictedClasses.isNotEmpty) {
      final firstClass = predictedClasses.first;
      addCandidate(firstClass, json['confidence'] ?? 0.60);
    }

    final predictions = json['predictions'];

    if (predictions is Map && predictions.isNotEmpty) {
      predictions.forEach((key, value) {
        if (value is Map) {
          final mapped = Map<String, dynamic>.from(value);
          final label = mapped['class'] ??
              mapped['class_name'] ??
              mapped['label'] ??
              mapped['name'] ??
              key;
          final confidence = mapped['confidence'] ??
              mapped['score'] ??
              mapped['probability'] ??
              mapped['value'];
          addCandidate(label, confidence);
        } else {
          addCandidate(key, value);
        }
      });
    }

    if (predictions is List && predictions.isNotEmpty) {
      for (final item in predictions) {
        if (item is Map) {
          final mapped = Map<String, dynamic>.from(item);

          final label = mapped['class'] ??
              mapped['class_name'] ??
              mapped['label'] ??
              mapped['name'];
          final confidence = mapped['confidence'] ??
              mapped['score'] ??
              mapped['probability'];

          // Normal object/classification list format.
          addCandidate(label, confidence);

          // Some classification APIs return each list item as
          // {"freshapples": 0.91} instead of {"class": "freshapples"}.
          if (label == null) {
            mapped.forEach((key, value) {
              if (!_isMetadataLabel(key.toString())) {
                if (value is Map && value['confidence'] != null) {
                  addCandidate(key, value['confidence']);
                } else if (value is num || value is String) {
                  addCandidate(key, value);
                }
              }
            });
          }
        }
      }
    }

    // Last-resort support for flat responses such as:
    // {"fresh": 0.91, "rotten": 0.09}
    json.forEach((key, value) {
      if (_isMetadataLabel(key)) return;
      if (value is num || value is String) {
        addCandidate(key, value);
      }
    });

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  static bool _isMetadataLabel(String label) {
    final normalized = label.toLowerCase().trim();

    return normalized.isEmpty ||
        normalized == 'image' ||
        normalized == 'time' ||
        normalized == 'inference_id' ||
        normalized == 'predictions' ||
        normalized == 'predicted_classes' ||
        normalized == 'top' ||
        normalized == 'confidence' ||
        normalized == 'license' ||
        normalized.contains('license');
  }

  static double _normalizeConfidence(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;

    // Roboflow usually returns 0.0-1.0, but some tools return 0-100.
    if (value > 1.0 && value <= 100.0) {
      return (value / 100.0).clamp(0.0, 1.0).toDouble();
    }

    return value.clamp(0.0, 1.0).toDouble();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

static Future<FreshnessResult> assessFreshness(FreshnessInput input) async {
  RoboflowImagePrediction? imagePrediction;
  final reasons = <String>[];
  var score = 100;

  // ------------------------------------------------------------
  // IMAGE ANALYSIS:
  // 1. Try local ONNX model first.
  // 2. If local ONNX fails or takes more than 20 seconds, fall back to Roboflow.
  // 3. If both fail, use questionnaire only.
  // ------------------------------------------------------------
  if (input.imageFile != null) {
    try {
      imagePrediction = await analyzeImageWithFallback(
        input.imageFile!,
        localTimeout: const Duration(seconds: 20),
        roboflowTimeout: const Duration(seconds: 20),
      );

      if (imagePrediction == null) {
        reasons.add(
          'Image analysis was unavailable or timed out, so the result used the questionnaire only.',
        );
      } else {
        final label = imagePrediction.label.toLowerCase();
        final confidencePercent = (imagePrediction.confidence * 100).round();

        final source =
            imagePrediction.rawResponse['source']?.toString() ?? 'image model';

        reasons.add(
          '$source detected "${imagePrediction.label}" with $confidencePercent% confidence.',
        );

        if (_looksRotten(label)) {
          score -= imagePrediction.confidence >= 0.70 ? 70 : 45;
        } else if (_looksFresh(label)) {
          score += imagePrediction.confidence >= 0.70 ? 10 : 5;
        }
      }
    } on TimeoutException {
      reasons.add(
        'Image analysis timed out, so the result used the questionnaire only.',
      );
    } catch (_) {
      reasons.add(
        'Image analysis failed, so the result used the questionnaire only.',
      );
    }
  } else {
    reasons.add('No image was added, so the result used the questionnaire only.');
  }

  // ------------------------------------------------------------
  // QUESTIONNAIRE / RULE-BASED SCORING
  // ------------------------------------------------------------

  if (input.hasMold) {
    score -= 100;
    reasons.add('Visible mold is a strong unsafe-food signal.');
  }

  if (input.hasSlime) {
    score -= 75;
    reasons.add('Slimy texture is a strong spoilage signal.');
  }

  switch (input.smell) {
    case 'Bad / rotten':
      score -= 90;
      reasons.add(
        'Bad or rotten smell usually means the food should not be eaten.',
      );
      break;

    case 'Sour / unusual':
      score -= 55;
      reasons.add('Sour or unusual smell lowers freshness confidence.');
      break;

    case 'No smell':
    case 'Normal':
      reasons.add('Smell does not indicate obvious spoilage.');
      break;
  }

  switch (input.texture) {
    case 'Slimy':
      score -= 75;
      reasons.add('Slimy texture suggests spoilage.');
      break;

    case 'Mushy':
      score -= 50;
      reasons.add('Mushy texture suggests the food is past peak freshness.');
      break;

    case 'Soft':
      score -= 20;
      reasons.add('Soft texture suggests the food should be used soon.');
      break;

    case 'Firm':
      reasons.add('Firm texture supports freshness.');
      break;
  }

  switch (input.appearance) {
    case 'Moldy':
      score -= 100;
      reasons.add('Moldy appearance is unsafe.');
      break;

    case 'Discolored':
      score -= 35;
      reasons.add('Discoloration lowers freshness confidence.');
      break;

    case 'Bruised / wilted':
      score -= 20;
      reasons.add('Bruising or wilting suggests the item should be used soon.');
      break;

    case 'Looks normal':
      reasons.add('Appearance looks normal.');
      break;
  }

  // ------------------------------------------------------------
  // DATE / SHELF LIFE SCORING
  // ------------------------------------------------------------

  final shelfLifeDays = _estimateShelfLifeDays(
    input.foodName,
    input.storageMethod,
  );

  var daysLeft = shelfLifeDays;

  if (input.purchaseDate != null) {
    final daysOwned = DateTime.now().difference(input.purchaseDate!).inDays;
    daysLeft = shelfLifeDays - daysOwned;

    reasons.add(
      'Based on purchase date and storage, estimated shelf life is about $shelfLifeDays day(s).',
    );

    if (daysLeft < 0) {
      score -= 40 + (daysLeft.abs() * 5).clamp(0, 40).toInt();
      reasons.add('This item is past its typical storage window.');
    } else if (daysLeft <= 2) {
      score -= 20;
      reasons.add('This item is near the end of its typical storage window.');
    }
  } else {
    reasons.add(
      'No purchase date was provided, so date-based confidence is lower.',
    );
  }

  // ------------------------------------------------------------
  // FINAL RESULT
  // ------------------------------------------------------------

  score = score.clamp(0, 100).toInt();

  final status = score >= 70
      ? 'Fresh'
      : score >= 40
          ? 'Use Soon'
          : 'Unsafe';

  final safeDaysLeft = status == 'Unsafe'
      ? 0
      : daysLeft.clamp(0, 30).toInt();

  final confidence = _confidenceLabel(
    imagePrediction: imagePrediction,
    hasPurchaseDate: input.purchaseDate != null,
    score: score,
  );

  return FreshnessResult(
    status: status,
    score: score,
    estimatedDaysLeft: safeDaysLeft,
    confidence: confidence,
    reasons: reasons,
    imagePrediction: imagePrediction,
  );
}
  static bool _looksRotten(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), ' ');

    return normalized.contains('rotten') ||
        normalized.contains('spoiled') ||
        normalized.contains('bad') ||
        normalized.contains('mold') ||
        normalized.contains('decay') ||
        normalized.contains('not fresh') ||
        normalized.contains('stale');
  }

  static bool _looksFresh(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), ' ');

    return normalized.contains('fresh') && !_looksRotten(normalized);
  }

  static int _estimateShelfLifeDays(String foodName, String storageMethod) {
    final food = foodName.toLowerCase();

    if (storageMethod == 'Freezer') return 90;
    if (storageMethod == 'Pantry / room temp') {
      if (food.contains('banana') || food.contains('avocado')) return 4;
      if (food.contains('bread')) return 5;
      if (food.contains('potato') || food.contains('onion')) return 21;
      return 10;
    }

    if (food.contains('chicken') || food.contains('turkey') || food.contains('raw meat')) return 2;
    if (food.contains('fish') || food.contains('shrimp') || food.contains('seafood')) return 1;
    if (food.contains('beef') || food.contains('pork')) return 3;
    if (food.contains('leftover') || food.contains('cooked')) return 4;
    if (food.contains('milk')) return 7;
    if (food.contains('yogurt')) return 10;
    if (food.contains('cheese')) return 21;
    if (food.contains('egg')) return 28;
    if (food.contains('berry') || food.contains('berries') || food.contains('strawberry')) return 5;
    if (food.contains('lettuce') || food.contains('spinach') || food.contains('leafy')) return 5;
    if (food.contains('tomato')) return 7;
    if (food.contains('broccoli') || food.contains('carrot') || food.contains('cucumber')) return 7;
    if (food.contains('apple')) return 21;
    if (food.contains('banana') || food.contains('avocado')) return 4;

    return 7;
  }

  static String _confidenceLabel({
    required RoboflowImagePrediction? imagePrediction,
    required bool hasPurchaseDate,
    required int score,
  }) {
    var confidencePoints = 0;

    if (imagePrediction != null && imagePrediction.confidence >= 0.70) confidencePoints += 2;
    if (imagePrediction != null && imagePrediction.confidence >= 0.40) confidencePoints += 1;
    if (hasPurchaseDate) confidencePoints += 1;
    if (score <= 25 || score >= 80) confidencePoints += 1;

    if (confidencePoints >= 3) return 'High';
    if (confidencePoints >= 1) return 'Medium';
    return 'Low';
  }
}

class _ParsedPrediction {
  final String label;
  final double confidence;

  const _ParsedPrediction({required this.label, required this.confidence});
}
