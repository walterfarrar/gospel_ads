# gospel_ads

Full-screen gospel ads you can drop in front of another ad. The message catalog lives in this package. The chance of showing one is saved on the device and only rises, up to a cap you set per app.

## Use it from another app

```yaml
dependencies:
  gospel_ads:
    git:
      url: https://github.com/walterfarrar/gospel_ads.git
      ref: main
```

Attach the navigator key:

```dart
MaterialApp(
  navigatorKey: GospelAds.navigatorKey,
)
```

If the app already has a navigator key, keep that one and call this before `runApp`:

```dart
GospelAds.useNavigator(myNavigatorKey);
```

Before an ad slot, roll and maybe show one:

```dart
await GospelAds.configure(
  initialChance: 1, // starting percent when nothing is saved yet
  maxChance: 15, // cap, in percent
  incrementPerAd: 0.25, // added after each completed ad
);

if (await GospelAds.shouldShow()) {
  final watched = await GospelAds.show();
  if (watched) {
    await GospelAds.recordAdWatched();
    // grant your reward
  }
} else {
  // show the normal ad, then:
  await GospelAds.recordAdWatched();
}
```

`show` returns true only when the viewer taps the X after the lines have faded in. `recordAdWatched` is what moves the chance up. Call it after a gospel ad and after your other ads, or the chance stays put.

`initialChance`, `maxChance`, and `incrementPerAd` are per app. A saved chance is not cleared when the app launches, and changing `initialChance` later does not pull an existing save back down.

## Updating the messages

Edit `lib/src/catalog.dart` and push to `main`. A line that starts with an em dash (`—`) is drawn as the citation.

Other apps stay on the commit in their `pubspec.lock` until you run:

```bash
flutter pub upgrade gospel_ads
```

Then ship a new build. An install that is already in the store keeps the catalog it was built with.
