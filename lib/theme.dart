import 'package:material_ui/material_ui.dart';

/// Kleuren uit de design-richting (Page): papier/inkt, groen = opnieuw,
/// koraal = spijt, indigo als merk. Kleur nooit alleen: altijd ook icoon/tekst.
class AppColors {
  static const keep = Color(0xFF14B87A);
  static const regret = Color(0xFFF2614B);
  static const brand = Color(0xFF4B4AE8);
  static const brandDeep = Color(0xFF2E2DB8);
  static const ink = Color(0xFF1B1F2A);
  static const paper = Color(0xFFF6F4EF);
  static const card = Color(0xFFFFFFFF);
  static const night = Color(0xFF101319);
  static const stone = Color(0xFF8A8F9C);
  static const line = Color(0xFFE4E1DA);
  static const sample = Color(0xFFF2B33D);
  static const sampleInk = Color(0xFF8A5A00);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101319), Color(0xFF1E1F5C), Color(0xFF3A39C9)],
    stops: [0, 0.55, 1],
  );
}

class AppRadius {
  static const card = 24.0;
  static const button = 18.0;
  static const chip = 999.0;
}

/// Bedragen: Inter met tabular figures, zodat cijfers niet dansen.
const tabular = [FontFeature.tabularFigures()];

TextStyle moneyStyle(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w900}) =>
    TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -size * 0.035,
      height: 1.05,
      fontFeatures: tabular,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.paper,
    splashFactory: InkSparkle.splashFactory,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
    fontFamily: 'Inter',
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
