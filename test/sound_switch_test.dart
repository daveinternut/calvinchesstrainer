import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/audio/sound_switch.dart';
import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what reaches the audio plugins, and which haptics fire.
class _Platform {
  _Platform() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    void record(String channel, List<String> into) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async {
        into.add(call.method);
        return null;
      });
    }

    record('com.ryanheise.just_audio.methods', audio);
    record('com.ryanheise.audio_session', session);
    record('flutter_tts', tts);
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  }

  final audio = <String>[];
  final session = <String>[];
  final tts = <String>[];
  final haptics = <String>[];

  void clear() {
    for (final log in [audio, session, tts, haptics]) {
      log.clear();
    }
  }
}

Future<SharedPreferences> _prefs(Map<String, Object> stored) {
  SharedPreferences.setMockInitialValues(stored);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('soundOnProvider', () {
    test('sound is on until switched off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(soundOnProvider), isTrue);
    });

    test('the switch survives a restart', () async {
      final prefs = await _prefs({});
      var container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container.read(soundOnProvider.notifier).toggle();
      expect(container.read(soundOnProvider), isFalse);
      container.dispose();

      // A fresh container over the same store is a cold start.
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(soundOnProvider), isFalse);
    });

    test('an unreadable saved value means sound on', () async {
      final prefs = await _prefs({'sound_on_v1': 'off'});
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(soundOnProvider), isTrue);
    });
  });

  group('AudioService with sound off', () {
    late _Platform platform;
    setUp(() => platform = _Platform());

    test('plays nothing, but haptics still fire', () async {
      final audio = AudioService()..muted = true;
      addTearDown(audio.dispose);
      await pumpEventQueue();
      platform.clear();

      await audio.playCorrect();
      await audio.playIncorrect();
      await audio.speakSquare('e', '4');
      await audio.speakMove('knight', 'f', '3', isCheck: true);
      await audio.playCheckCall();
      await audio.playMilestone(5);
      await audio.playNewRecord();
      await audio.speak('Castles kingside');

      expect(platform.audio, isEmpty);
      expect(platform.session, isEmpty);
      expect(platform.tts, isEmpty);
      expect(platform.haptics, containsAll(const [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]));
    });

    test('switching sound off cuts off what is playing', () async {
      final audio = AudioService();
      addTearDown(audio.dispose);
      audio.muted = true;
      await pumpEventQueue();
      expect(platform.tts, contains('stop'));
    });

    test('audioServiceProvider follows the switch, from the saved state on',
        () async {
      final prefs = await _prefs({'sound_on_v1': false});
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final audio = container.read(audioServiceProvider);
      expect(audio.muted, isTrue);
      container.read(soundOnProvider.notifier).toggle();
      expect(audio.muted, isFalse);
      container.read(soundOnProvider.notifier).toggle();
      expect(audio.muted, isTrue);
    });
  });

  testWidgets('the speaker button flips the switch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: SoundButton())),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SoundButton)),
    );
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Turn sound off'));
    await tester.pump();
    expect(container.read(soundOnProvider), isFalse);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Turn sound on'));
    await tester.pump();
    expect(container.read(soundOnProvider), isTrue);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });
}
