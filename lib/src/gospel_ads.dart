import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'gospel_ad_screen.dart';

/// Full-screen gospel ads and the chance they replace another ad.
///
/// The saved chance never resets on launch. It only moves up, by
/// [incrementPerAd], until it reaches [maxChance]. Both of those, and the
/// starting chance used when nothing is saved yet, come from [configure].
class GospelAds {
  GospelAds._();

  static const String _chanceKey = 'gospel_ad_chance';
  static final _random = Random();

  /// Attach this to [MaterialApp.navigatorKey] unless the app already has one.
  /// If it does, pass that key to [useNavigator] before [runApp].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> _navigatorKey = navigatorKey;

  static double _initialChance = 1.0;
  static double _maxChance = 15.0;
  static double _incrementPerAd = 0.25;
  static double? _currentChance;
  static Future<void>? _loading;

  /// Use the app's existing navigator key instead of [navigatorKey].
  static void useNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Per-app rates. Does not reset a chance that is already saved.
  ///
  /// [initialChance], [maxChance], and [incrementPerAd] are percentages:
  /// `1.0` is 1%, `15.0` is 15%, `0.25` adds a quarter of a point per ad.
  static Future<void> configure({
    required double initialChance,
    required double maxChance,
    required double incrementPerAd,
  }) async {
    _initialChance = initialChance;
    _maxChance = maxChance;
    _incrementPerAd = incrementPerAd;
    final current = _currentChance;
    if (current != null && current > _maxChance) {
      _currentChance = _maxChance;
      await _persist(_maxChance);
    }
  }

  /// True when this ad slot should be a gospel ad.
  ///
  /// Loads the saved chance first, so the first roll of a process uses it.
  static Future<bool> shouldShow() async {
    await _ensureLoaded();
    return _random.nextDouble() * 100 < _currentChance!;
  }

  /// Call after any completed ad, gospel or otherwise, so the chance can rise.
  static Future<void> recordAdWatched() async {
    await _ensureLoaded();
    final max = _maxChance;
    final current = _currentChance!;
    if (current > max) {
      _currentChance = max;
      await _persist(max);
      return;
    }
    if (current >= max) return;

    _currentChance = (current + _incrementPerAd).clamp(0.0, max);
    await _persist(_currentChance!);
  }

  /// Shows one random catalog ad.
  ///
  /// Returns true only when the viewer closes it with the X. Returns false
  /// when the navigator is missing or the route is dismissed any other way.
  static Future<bool> show() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || gospelAds.isEmpty) return false;

    final ad = gospelAds[_random.nextInt(gospelAds.length)];
    return GospelAdScreen.show(navigator, ad);
  }

  static Future<void> _ensureLoaded() async {
    if (_currentChance != null) return;
    try {
      _loading ??= _load();
      await _loading;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_chanceKey);
    final chance = (saved ?? _initialChance).clamp(0.0, _maxChance);
    _currentChance = chance;
    if (saved != null && saved != chance) {
      await _persist(chance);
    }
  }

  static Future<void> _persist(double chance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chanceKey, chance);
  }

  @visibleForTesting
  static double? get chanceForTest => _currentChance;

  @visibleForTesting
  static void resetForTest() {
    _currentChance = null;
    _loading = null;
    _initialChance = 1.0;
    _maxChance = 15.0;
    _incrementPerAd = 0.25;
    _navigatorKey = navigatorKey;
  }
}
