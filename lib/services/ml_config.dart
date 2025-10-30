class MLConfig {
  // Limiar global de confiança para aceitar a classificação como "inseto"
  static const double minConfidenceThreshold = 0.60;
  // Margem mínima entre as duas maiores probabilidades
  static const double minTop2Margin = 0.15;
}
