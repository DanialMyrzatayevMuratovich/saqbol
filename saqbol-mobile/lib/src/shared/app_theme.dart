import 'package:flutter/material.dart';

/// Semantic colours of SaqBol, one set per brightness, taken from the shield
/// logo (sky blue, navy, amber). Widgets read them with `context.saq` and never
/// hard-code a hex value, so both themes stay in sync.
///
/// Text colours keep at least 4.5:1 contrast on `surface` and `background`,
/// and verdict colours also on their own tint (`VerdictStyle.tint`), checked
/// in test/verdict_contrast_test.dart. Verdict colours always come with an
/// icon and a word, so colour is never the only signal (red/green colour
/// blindness).
@immutable
class SaqColors extends ThemeExtension<SaqColors> {
  const SaqColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.amber,
    required this.scam,
    required this.suspicious,
    required this.safe,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color amber;
  final Color scam;
  final Color suspicious;
  final Color safe;

  static const dark = SaqColors(
    background: Color(0xFF0B1220),
    surface: Color(0xFF131C2E),
    surfaceRaised: Color(0xFF1C2741),
    border: Color(0xFF26324D),
    text: Color(0xFFEEF3FA),
    muted: Color(0xFF97A6BF),
    accent: Color(0xFF2BA8E0),
    onAccent: Color(0xFF04121D),
    amber: Color(0xFFF2A33A),
    scam: Color(0xFFFF6B5E),
    suspicious: Color(0xFFF2A33A),
    safe: Color(0xFF34C99A),
  );

  static const light = SaqColors(
    background: Color(0xFFF3F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEAF0F7),
    border: Color(0xFFDCE4EE),
    text: Color(0xFF0B1220),
    muted: Color(0xFF55657C),
    accent: Color(0xFF12679F),
    onAccent: Color(0xFFFFFFFF),
    amber: Color(0xFFF2A33A),
    scam: Color(0xFFB42318),
    suspicious: Color(0xFF975500),
    safe: Color(0xFF09724F),
  );

  @override
  SaqColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? amber,
    Color? scam,
    Color? suspicious,
    Color? safe,
  }) {
    return SaqColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      amber: amber ?? this.amber,
      scam: scam ?? this.scam,
      suspicious: suspicious ?? this.suspicious,
      safe: safe ?? this.safe,
    );
  }

  @override
  SaqColors lerp(ThemeExtension<SaqColors>? other, double t) {
    if (other is! SaqColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SaqColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      border: mix(border, other.border),
      text: mix(text, other.text),
      muted: mix(muted, other.muted),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      amber: mix(amber, other.amber),
      scam: mix(scam, other.scam),
      suspicious: mix(suspicious, other.suspicious),
      safe: mix(safe, other.safe),
    );
  }
}

extension SaqThemeContext on BuildContext {
  /// Falls back to the dark palette under a theme without SaqBol colours (tests).
  SaqColors get saq => Theme.of(this).extension<SaqColors>() ?? SaqColors.dark;
}

/// Spacing on an 8-point grid (4 for the tightest gaps).
class Gap {
  const Gap._();

  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class Radii {
  const Radii._();

  static const control = 16.0;
  static const card = 20.0;
}

/// Taller than the 48 dp minimum: many users are older people.
const kButtonHeight = 56.0;

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SaqColors.dark : SaqColors.light;
  final isLight = brightness == Brightness.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.amber,
    onSecondary: const Color(0xFF1F1405),
    error: c.scam,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.text,
    surfaceContainerHighest: c.surfaceRaised,
    outline: c.border,
    outlineVariant: c.border,
  );

  final base = (isLight ? Typography.blackMountainView : Typography.whiteMountainView)
      .apply(bodyColor: c.text, displayColor: c.text);
  final text = base.copyWith(
    displaySmall: base.displaySmall?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15),
    headlineSmall: base.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2),
    titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleMedium: base.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
    titleSmall: base.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
    bodySmall: base.bodySmall?.copyWith(fontSize: 13, height: 1.35, color: c.muted),
    labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    labelMedium: base.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
  );

  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        // White on near-white needs an edge; dark cards stand out by tone alone.
        side: isLight ? BorderSide(color: c.border) : BorderSide.none,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceRaised,
      hintStyle: TextStyle(color: c.muted),
      labelStyle: TextStyle(color: c.muted),
      floatingLabelStyle: TextStyle(color: c.accent),
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.l),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.control), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.control), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceRaised,
        disabledForegroundColor: c.muted,
        minimumSize: const Size.fromHeight(kButtonHeight),
        textStyle: text.labelLarge,
        shape: controlShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: c.border),
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
        shape: controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.accent, textStyle: text.labelLarge?.copyWith(fontSize: 15)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      height: 72,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.accent : c.muted),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.onAccent : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.surfaceRaised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.transparent : c.border,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceRaised,
      selectedColor: c.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(color: c.text, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent.withValues(alpha: 0.16) : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.text,
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      subtitleTextStyle: text.bodySmall,
      minVerticalPadding: Gap.m,
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.surfaceRaised),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceRaised,
      contentTextStyle: TextStyle(color: c.text),
      behavior: SnackBarBehavior.floating,
      shape: controlShape,
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: c.surfaceRaised, surfaceTintColor: Colors.transparent),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(c.onAccent),
      side: BorderSide(color: c.muted, width: 1.5),
    ),
  );
}
