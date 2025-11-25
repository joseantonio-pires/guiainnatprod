// Performance Configuration for InNat App
//
// This file centralizes all performance-related configurations
// to facilitate adjustments and maintenance.

class PerformanceConfig {
  // Image Cache Settings
  static const int imageCacheSize = 100; // MB
  static const Duration imageCacheDuration = Duration(days: 7);
  static const int thumbnailCacheWidth = 56;
  static const int thumbnailCacheHeight = 56;

  // ListView Settings
  static const bool addAutomaticKeepAlives = true;
  static const bool addRepaintBoundaries = true;
  static const bool addSemanticIndexes = true;

  // TensorFlow Lite Settings
  static const int maxClassificationCacheSize = 50;
  static const Duration classificationTimeout = Duration(seconds: 30);
  static const int maxConcurrentClassifications = 1;

  // Debounce Settings
  static const Duration classificationDebounce = Duration(milliseconds: 300);
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Build Settings
  static const bool enableRepaintBoundaries = true;
  static const bool enableConstWidgets = true;

  // Animation Settings
  static const Duration standardAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  // Memory Management Settings
  static const int maxPhotosCacheSize = 100;
  static const Duration photosCacheCleanupInterval = Duration(minutes: 10);

  // Network Settings
  static const Duration httpTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
