import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceService {
  // Debounce function to reduce unnecessary computations
  static Timer? _debounceTimer;
  static Future<void> debounce(
    Future<void> Function() callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(duration, () {
      callback();
    });
  }

  // Compute-intensive tasks offloading
  static Future<T> computeInBackground<T>(
    T Function() heavyComputation,
  ) async {
    return await compute(_computeWrapper, heavyComputation);
  }

  // Wrapper for compute to handle generic function
  static T _computeWrapper<T>(T Function() heavyComputation) {
    return heavyComputation();
  }

  // Caching mechanism for frequently accessed data
  static final Map<String, dynamic> _memoryCache = {};

  static void cacheData(String key, dynamic value) {
    _memoryCache[key] = value;
  }

  static dynamic getCachedData(String key) {
    return _memoryCache[key];
  }

  static void clearCache() {
    _memoryCache.clear();
  }

  // Persistent performance settings
  static Future<void> savePerfSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('perf_$key', value);
  }

  static Future<bool> getPerfSetting(String key, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('perf_$key') ?? defaultValue;
  }

  // Batch processing for large lists
  static List<T> processBatch<T>(
    List<T> items,
    T Function(T) processor, {
    int batchSize = 50,
  }) {
    final List<T> processedItems = [];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      processedItems.addAll(
        items.sublist(i, end).map(processor),
      );
    }
    return processedItems;
  }

  // Memory-efficient list filtering
  static Iterable<T> efficientFilter<T>(
    Iterable<T> items,
    bool Function(T) test,
  ) sync* {
    for (final item in items) {
      if (test(item)) {
        yield item;
      }
    }
  }
}
