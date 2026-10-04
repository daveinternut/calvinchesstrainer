import 'package:flutter/material.dart';

/// The app's colour tokens. One accent (brand green) carries meaning: actions
/// and "found". Amber marks targets, vermilion marks misses. Everything else
/// is a cool, near-neutral ground so the board and the feedback stand out.
class AppColors {
  // Ground and surfaces.
  static const ground = Color(0xFFF4F6F5);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE1E6E3);
  static const line2 = Color(0xFFC9D2CD);
  static const well = Color(0xFFE9EEEB);

  // Text.
  static const ink = Color(0xFF0E1B16);
  static const ink2 = Color(0xFF44524C);
  static const ink3 = Color(0xFF5E6B66);

  // Brand: actions, selection, found.
  static const brand = Color(0xFF0F6B4C);
  static const brandDeep = Color(0xFF0A4A34);
  static const brandSoft = Color(0xFFE3F1EA);

  // Targets.
  static const amber = Color(0xFFE8A33D);
  static const amberSoft = Color(0xFFFBEFD9);
  static const amberInk = Color(0xFF7A4F08);

  // Misses and loose pieces.
  static const verm = Color(0xFFD2512C);
  static const vermSoft = Color(0xFFFBE7E0);
  static const vermInk = Color(0xFF9A3416);

  // The board.
  static const boardLight = Color(0xFFE7ECE9);
  static const boardDark = Color(0xFF9DB2A8);

  /// Board highlight for found / correct squares: a brighter green than
  /// [brand] so a 60% wash over a dark square still reads as "yes".
  static const found = Color(0xFF1F8A5B);

  // The trainers' original names, mapped onto the system.
  static const correctGreen = found;
  static const incorrectRed = verm;
  static const highlightYellow = amber;
  static const goalAmber = amber;
  static const primary = brand;
  static const primaryLight = Color(0xFF3E8E6E);
  static const background = ground;
  static const textPrimary = ink;
  static const textSecondary = ink3;
}

/// Font families bundled in pubspec.yaml.
class AppFonts {
  /// Display and interface: Bricolage Grotesque.
  static const ui = 'Bricolage';

  /// Notation, numbers and timers: Geist Mono. "e4", "Nf3", "0:41".
  static const mono = 'GeistMono';
}

/// Text styles the design system uses directly. Sizes are logical pixels.
class AppText {
  static const display = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.05,
    color: AppColors.ink,
  );

  static const title = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.15,
    color: AppColors.ink,
  );

  static const cardTitle = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    height: 1.2,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.ink2,
  );

  static const caption = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.ink3,
  );

  /// Small section label ("Mode", "Your piece").
  static const label = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.ink3,
  );

  /// Scores, streaks and timers: the UI face with fixed-width digits, so a
  /// count doesn't jiggle as it changes (and zero isn't Geist Mono's
  /// slashed zero).
  static const number = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Chess notation: squares, moves, piece letters ("e4", "Nf3", "K").
  static const mono = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brandDeep,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.ink3,
      outline: AppColors.line2,
      outlineVariant: AppColors.line,
      error: AppColors.verm,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.ui,
      scaffoldBackgroundColor: AppColors.ground,
    );

    final text = base.textTheme.apply(
      fontFamily: AppFonts.ui,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    const pill = StadiumBorder();
    return base.copyWith(
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: pill,
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: pill,
          side: const BorderSide(color: AppColors.line2),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0x290E1B16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}
