import 'package:flutter_test/flutter_test.dart';
import 'package:gospel_ads/gospel_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gospel_ad_chance');
    GospelAds.resetForTest();
  });

  test('starts at the configured initial chance', () async {
    await GospelAds.configure(
      initialChance: 3,
      maxChance: 15,
      incrementPerAd: 0.5,
    );

    await GospelAds.shouldShow();

    expect(GospelAds.chanceForTest, 3);
  });

  test('rises by the increment and stops at the cap', () async {
    await GospelAds.configure(
      initialChance: 14,
      maxChance: 15,
      incrementPerAd: 0.75,
    );

    await GospelAds.recordAdWatched();
    expect(GospelAds.chanceForTest, 14.75);

    await GospelAds.recordAdWatched();
    expect(GospelAds.chanceForTest, 15);

    await GospelAds.recordAdWatched();
    expect(GospelAds.chanceForTest, 15);
  });

  test('keeps a saved chance instead of starting over', () async {
    await GospelAds.configure(
      initialChance: 1,
      maxChance: 20,
      incrementPerAd: 2,
    );
    await GospelAds.recordAdWatched();
    expect(GospelAds.chanceForTest, 3);

    GospelAds.resetForTest();
    await GospelAds.configure(
      initialChance: 1,
      maxChance: 20,
      incrementPerAd: 2,
    );
    await GospelAds.shouldShow();

    expect(GospelAds.chanceForTest, 3);
  });

  test('clamps a saved chance down to a lower cap', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gospel_ad_chance', 18);
    GospelAds.resetForTest();

    await GospelAds.configure(
      initialChance: 1,
      maxChance: 15,
      incrementPerAd: 1,
    );
    await GospelAds.shouldShow();

    expect(GospelAds.chanceForTest, 15);
    expect(prefs.getDouble('gospel_ad_chance'), 15);
  });
}
