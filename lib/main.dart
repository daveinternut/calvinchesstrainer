import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/analytics_service.dart';
import 'core/services/personal_bests_service.dart';
import 'core/services/stockfish_service.dart';
import 'firebase_options.dart';

void main() {
  // Nothing below may take the app down. An uncaught async error from a
  // plugin would otherwise escape to the top level and leave the visitor
  // staring at the splash screen forever.
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Hot restart leaves the previous isolate's native engine thread alive;
      // free it. Release builds have no hot restart, so they skip this (it
      // would otherwise poke the native layer on every cold start).
      if (kDebugMode) {
        try {
          stockfishCleanupForRestart();
        } catch (e) {
          debugPrint('Stockfish cleanup skipped: $e');
        }
      }

      // Firebase must never gate startup, so it initializes in the background
      // and analytics drops events until it is ready. The timeout matters: on
      // web a blocked SDK import rejects as an *unhandled JS promise* rather
      // than a Dart error, so initializeApp() can neither complete nor throw.
      unawaited(
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
            .timeout(const Duration(seconds: 8))
            .then((_) => markFirebaseReady())
            .catchError((Object e) {
              debugPrint(
                'Firebase unavailable; continuing without analytics: $e',
              );
            }),
      );

      // Saved personal bests. Bounded too: without them bests simply last for
      // the session, which beats a hang.
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 3),
        );
      } catch (e) {
        debugPrint('Saved bests unavailable; keeping them in memory: $e');
      }

      // Holds on iPhone. iPad ignores it: the app supports multitasking, and
      // iPadOS 26 refuses programmatic orientation changes, so every screen
      // also lays out for landscape (see TrainerLayout).
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e) {
        debugPrint('Orientation lock skipped: $e');
      }

      // Inter ships in assets/google_fonts/; never download fonts at runtime.
      GoogleFonts.config.allowRuntimeFetching = false;
      LicenseRegistry.addLicense(() async* {
        final license = await rootBundle.loadString(
          'assets/google_fonts/OFL.txt',
        );
        yield LicenseEntryWithLineBreaks(['Inter font'], license);
      });

      FlutterNativeSplash.remove();

      runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const CalvinChessTrainerApp(),
        ),
      );
    },
    (error, stack) {
      // Anything the guards above and the framework's own handlers didn't
      // catch, for the whole life of the app. Log and keep going — never let
      // telemetry or a plugin kill the app.
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}
