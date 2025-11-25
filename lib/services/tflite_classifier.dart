//import 'dart:io';
//import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'tflite_mobile.dart';
import 'package:http/http.dart' as http;
import 'ml_config.dart';

class TFLiteClassifier {
  static List<String>? _labels;
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Carregar labels do modelo aprimorado (funciona em todas as plataformas)
      final String labelsJson =
          await rootBundle.loadString('assets/models/model_info_enhanced.json');
      final Map<String, dynamic> modelInfo =
          jsonDecode(labelsJson) as Map<String, dynamic>;
      _labels = List<String>.from(
          modelInfo['categories'] as List<dynamic>? ?? <dynamic>[]);

      _isInitialized = true;
      debugPrint('✅ Classificador inicializado com sucesso!');
      debugPrint('Classes disponíveis: ${_labels?.length}');
      debugPrint('Plataforma: ${kIsWeb ? "Web" : "Mobile"}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao inicializar classificador: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> classifyImage(
      Uint8List imageBytes) async {
    if (!_isInitialized || _labels == null) {
      debugPrint('❌ Classificador não foi inicializado');
      return null;
    }

    try {
      if (kIsWeb) {
        // Na web, usar API do backend
        return await _classifyImageWeb(imageBytes);
      } else {
        // No mobile, usar TensorFlow Lite local
        return await _classifyImageMobile(imageBytes);
      }
    } catch (e) {
      debugPrint('❌ Erro na classificação: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _classifyImageWeb(
      Uint8List imageBytes) async {
    try {
      // Usar API do backend para classificação na web
      final ip = '127.0.0.1';
      final uri = Uri.parse('http://$ip:5000/classify');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        return {
          'predicted_class': data['predicted_class'],
          'confidence': data['confidence'],
          'all_predictions': [data['confidence']], // Simplificado para web
          'class_labels': _labels!,
        };
      } else {
        debugPrint('❌ Erro na API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro na classificação web: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _classifyImageMobile(
      Uint8List imageBytes) async {
    try {
      final bool ok = await TFLiteMobile.initialize();
      if (!ok) {
        debugPrint('❌ TFLite não inicializado');
        return null;
      }

      final result = await TFLiteMobile.classifyImage(imageBytes);
      if (result == null) return null;

      // Filtros globais (reduz falsos positivos)
      final double confidence = (result['confidence'] as double?) ?? 0.0;
      final List<double> all =
          (result['all_predictions'] as List?)?.cast<double>() ?? const [];

      // margem top-2
      double top2margin = 1.0;
      if (all.isNotEmpty) {
        final sorted = [...all]..sort((a, b) => b.compareTo(a));
        if (sorted.length >= 2) {
          top2margin = sorted[0] - sorted[1];
        }
      }

      if (confidence < MLConfig.minConfidenceThreshold ||
          top2margin < MLConfig.minTop2Margin) {
        return {
          'predicted_class': 'desconhecido',
          'confidence': confidence,
          'all_predictions':
              result['all_predictions'] as List<dynamic>? ?? <dynamic>[],
          'class_labels': _labels!,
        };
      }

      return {
        'predicted_class': result['predicted_class'],
        'confidence': confidence,
        'all_predictions':
            result['all_predictions'] as List<dynamic>? ?? <dynamic>[],
        'class_labels': _labels!,
      };
    } catch (e) {
      debugPrint('❌ Erro na classificação mobile: $e');
      return null;
    }
  }

  static void dispose() {
    _labels = null;
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static List<String>? get labels => _labels;
}
