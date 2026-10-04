import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PersonalBestsNotifier (in memory)', () {
    late ProviderContainer container;
    late PersonalBestsNotifier bests;

    setUp(() {
      container = ProviderContainer();
      bests = container.read(personalBestsProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('first non-zero score is a record; ties and lower scores are not', () {
      expect(bests.best('k'), isNull);
      expect(bests.submit('k', 0), isFalse, reason: 'zero never counts');
      expect(bests.submit('k', 5), isTrue);
      expect(bests.submit('k', 5), isFalse, reason: 'a tie is not a record');
      expect(bests.submit('k', 3), isFalse);
      expect(bests.submit('k', 6), isTrue);
      expect(bests.best('k'), 6);
    });

    test('lower-is-better times: any first time counts, then only faster', () {
      expect(bests.submit('t', 42, lowerIsBetter: true), isTrue);
      expect(bests.submit('t', 50, lowerIsBetter: true), isFalse);
      expect(bests.submit('t', 42, lowerIsBetter: true), isFalse);
      expect(bests.submit('t', 30, lowerIsBetter: true), isTrue);
      expect(bests.best('t'), 30);
    });

    test('keys are independent', () {
      bests.submit('a', 4);
      expect(bests.best('b'), isNull);
      expect(bests.submit('b', 1), isTrue);
    });
  });

  group('PersonalBestsNotifier (persisted)', () {
    Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
      SharedPreferences.setMockInitialValues(stored);
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    }

    test('bests survive a restart', () async {
      var container = await containerWith({});
      container.read(personalBestsProvider.notifier).submit('vision.x', 7);
      container.dispose();

      // A fresh container over the same store is a cold start.
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(
        container.read(personalBestsProvider.notifier).best('vision.x'),
        7,
      );
      container.dispose();
    });

    test('an unreadable store is ignored, not fatal', () async {
      final container = await containerWith({'personal_bests_v1': '{not json'});
      expect(container.read(personalBestsProvider), isEmpty);
      container.dispose();
    });
  });
}
