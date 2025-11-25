// Este arquivo só é usado no mobile (Android/iOS)
// Não será compilado na web

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// Importação condicional - só funciona no mobile
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class TFLiteMobile {
  static tflite.Interpreter? _interpreter;
  static List<String>? _labels;
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Carregar modelo TensorFlow Lite aprimorado
      _interpreter = await tflite.Interpreter.fromAsset(
          'assets/models/insect_classifier_enhanced.tflite');

      // Carregar labels do modelo aprimorado
      final String labelsJson =
          await rootBundle.loadString('assets/models/model_info_enhanced.json');
      final Map<String, dynamic> modelInfo =
          jsonDecode(labelsJson) as Map<String, dynamic>;
      _labels = List<String>.from(
          modelInfo['categories'] as List<dynamic>? ?? <dynamic>[]);

      _isInitialized = true;
      // TensorFlow Lite Mobile inicializado com sucesso
      return true;
    } catch (e) {
      // Erro ao inicializar TensorFlow Lite Mobile
      return false;
    }
  }

  static Future<Map<String, dynamic>?> classifyImage(
      Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null || _labels == null) {
      return null;
    }

    try {
      // Decodificar e pré-processar a imagem
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Redimensionar para 224x224
      final img.Image resizedImage =
          img.copyResize(image, width: 224, height: 224);

      // Converter para tensor
      final input = _imageToByteListFloat32(resizedImage);

      // Preparar tensor de saída
      // Preparar tensor de saída [1, num_classes]
      final output = List.generate(
        1,
        (_) => List<double>.filled(_labels!.length, 0.0),
      );

      // Executar inferência
      _interpreter!.run(input, output);

      // Processar resultados
      final List<double> predictions = List<double>.from(output[0]);

      // Encontrar top-3 predições
      final List<MapEntry<int, double>> indexedPredictions =
          predictions.asMap().entries.toList();
      indexedPredictions.sort((a, b) => b.value.compareTo(a.value));

      final top3 = indexedPredictions.take(3).toList();

      return {
        'predicted_class': _labels![top3[0].key],
        'confidence': top3[0].value,
        'top3_predictions': top3
            .map((entry) => {
                  'class': _labels![entry.key],
                  'confidence': entry.value,
                })
            .toList(),
        'all_predictions': predictions,
        'class_labels': _labels!,
      };
    } catch (e) {
      // Erro na classificação mobile
      return null;
    }
  }

  static Uint8List _imageToByteListFloat32(img.Image image) {
    final rgbBytes = image.getBytes(order: img.ChannelOrder.rgb);
    final floatData = Float32List(rgbBytes.length);
    for (int i = 0; i < rgbBytes.length; i++) {
      floatData[i] = rgbBytes[i] / 255.0;
    }
    return floatData.buffer.asUint8List();
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static List<String>? get labels => _labels;
}
