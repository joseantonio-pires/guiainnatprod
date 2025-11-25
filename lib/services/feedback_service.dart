import 'dart:convert';
//import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FeedbackService {
  static const String _feedbackKey = 'classification_feedback';

  // Salvar feedback localmente
  static Future<void> saveFeedbackLocally({
    required String imageId,
    required String predictedClass,
    required String userFeedback,
    required double confidence,
    String? correctClass,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? location,
  }) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final feedbackData = {
      'image_id': imageId,
      'predicted_class': predictedClass,
      'user_feedback': userFeedback,
      'correct_class': correctClass,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': deviceInfo ?? {},
      'location': location ?? {},
      'synced': false,
    };

    final existingFeedbacks = prefs.getStringList(_feedbackKey) ?? [];
    existingFeedbacks.add(jsonEncode(feedbackData));
    await prefs.setStringList(_feedbackKey, existingFeedbacks);
  }

  // Obter feedbacks locais não sincronizados
  static Future<List<Map<String, dynamic>>> getUnsyncedFeedbacks() async {
    if (kIsWeb) return [];

    final prefs = await SharedPreferences.getInstance();
    final feedbacks = prefs.getStringList(_feedbackKey) ?? [];

    return feedbacks
        .map((feedback) => Map<String, dynamic>.from(jsonDecode(feedback)))
        .where((feedback) => feedback['synced'] == false)
        .toList();
  }

  // Sincronizar feedbacks com o backend
  static Future<bool> syncFeedbacksWithBackend(String backendUrl) async {
    if (kIsWeb) return false;

    try {
      final unsyncedFeedbacks = await getUnsyncedFeedbacks();
      final prefs = await SharedPreferences.getInstance();

      for (final feedback in unsyncedFeedbacks) {
        final response = await http.post(
          Uri.parse('$backendUrl/feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(feedback),
        );

        if (response.statusCode == 200) {
          // Marcar como sincronizado
          final allFeedbacks = prefs.getStringList(_feedbackKey) ?? [];
          final updatedFeedbacks = allFeedbacks.map((f) {
            final data = Map<String, dynamic>.from(jsonDecode(f));
            if (data['image_id'] == feedback['image_id'] &&
                data['timestamp'] == feedback['timestamp']) {
              data['synced'] = true;
            }
            return jsonEncode(data);
          }).toList();

          await prefs.setStringList(_feedbackKey, updatedFeedbacks);
        }
      }

      return true;
    } catch (e) {
      // Erro ao sincronizar feedbacks
      return false;
    }
  }

  // Enviar feedback individual para o backend
  static Future<bool> sendFeedbackToBackend({
    required String backendUrl,
    required String imageId,
    required String predictedClass,
    required String userFeedback,
    required double confidence,
    String? correctClass,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? location,
  }) async {
    try {
      final feedbackData = {
        'image_id': imageId,
        'predicted_class': predictedClass,
        'user_feedback': userFeedback,
        'correct_class': correctClass,
        'confidence': confidence,
        'device_info': deviceInfo ?? {},
        'location': location ?? {},
      };

      final response = await http.post(
        Uri.parse('$backendUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );

      return response.statusCode == 200;
    } catch (e) {
      // Erro ao enviar feedback
      return false;
    }
  }

  // Obter estatísticas do backend
  static Future<Map<String, dynamic>?> getBackendStats(
      String backendUrl) async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/feedback/stats'));

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      // Erro ao obter estatísticas
      return null;
    }
  }
}
