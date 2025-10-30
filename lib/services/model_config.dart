// Configurações do modelo de classificação de insetos
class ModelConfig {
  // Caminhos dos arquivos do modelo aprimorado
  static const String modelPath =
      'assets/models/insect_classifier_enhanced.tflite';
  static const String modelInfoPath = 'assets/models/model_info_enhanced.json';

  // Configurações de performance do modelo
  static const double minConfidenceThreshold = 0.3; // 30% mínimo
  static const int topPredictionsCount = 3;

  // Informações do modelo
  static const String modelVersion = '2.0_enhanced';
  static const String modelArchitecture =
      'MobileNetV2 + Custom Dense Layers + Fine-tuning';
  static const double expectedAccuracy = 0.6752; // 67.52%
  static const double expectedTop3Accuracy = 0.8529; // 85.29%

  // Classes de insetos suportadas
  static const List<String> supportedClasses = [
    'aranhas',
    'besouro_carabideo',
    'crisopideo',
    'joaninhas',
    'libelulas',
    'mosca_asilidea',
    'mosca_dolicopodidea',
    'mosca_sirfidea',
    'mosca_taquinidea',
    'percevejo_geocoris',
    'percevejo_orius',
    'percevejo_pentatomideo',
    'percevejo_reduviideo',
    'tesourinha',
    'vespa_parasitoide',
    'vespa_predadora'
  ];

  // Configurações de imagem
  static const int imageSize = 224;
  static const int imageChannels = 3; // RGB

  // Mensagens de feedback
  static const String highConfidenceMessage =
      'Identificação de alta confiança!';
  static const String mediumConfidenceMessage =
      'Identificação com boa confiança.';
  static const String lowConfidenceMessage =
      'Confiança baixa. Tente uma foto mais nítida.';

  // Métodos utilitários
  static String getConfidenceMessage(double confidence) {
    if (confidence >= 0.8) return highConfidenceMessage;
    if (confidence >= 0.5) return mediumConfidenceMessage;
    return lowConfidenceMessage;
  }

  static bool isHighConfidence(double confidence) {
    return confidence >= 0.8;
  }

  static bool isAcceptableConfidence(double confidence) {
    return confidence >= minConfidenceThreshold;
  }
}
