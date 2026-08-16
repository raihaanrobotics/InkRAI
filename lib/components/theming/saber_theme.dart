import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/theming/yaru_builder.dart';
import 'package:saber/data/prefs.dart';
import 'package:sbn/font_fallbacks.dart';
import 'package:yaru/yaru.dart';

abstract class SaberTheme {
  static ThemeData createTheme(
    ColorScheme colorScheme,
    TargetPlatform platform,
  ) {
    colorScheme = _adjustColorScheme(colorScheme, platform);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _Components.textTheme(platform, colorScheme),
      platform: platform,
      progressIndicatorTheme: _Components.progressIndicatorTheme,
      cardColor: colorScheme.surface,
      cardTheme: _Components.cardTheme(colorScheme),
      cupertinoOverrideTheme: _Components.cupertinoOverrideTheme,
      appBarTheme: _Components.appBarTheme,
    );
  }

  static ThemeData createThemeFromSeed(
    Color seedColor,
    Brightness brightness,
    TargetPlatform platform, {
    @Deprecated(
      'High contrast is not implemented here. '
      'Use ColorScheme.withHighContrast() instead',
    )
    bool highContrast = false,
  }) {
    late final yaruVariant = YaruBuilder.getYaruVariant(seedColor);
    if (platform == TargetPlatform.linux) {
      return getThemeFromYaru(
        YaruThemeData(variant: yaruVariant),
        brightness,
        platform,
        highContrast,
      );
    }

    final ColorScheme colorScheme;
    if (platform.usesYaruColors) {
      colorScheme = brightness == Brightness.light
          ? yaruVariant.theme.colorScheme
          : yaruVariant.darkTheme.colorScheme;
    } else {
      colorScheme = ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: seedColor,
      );
    }
    return createTheme(colorScheme, platform);
  }

  /// Adjusts certain colors in the [ColorScheme].
  static ColorScheme _adjustColorScheme(
    ColorScheme colorScheme,
    TargetPlatform platform,
  ) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    // Custom aesthetic palette tokens
    final Color customBg = isDark ? const Color(0xFF0B0E14) : const Color(0xFFFFFFFF);
    final Color customSurface = isDark ? const Color(0xCC161B22) : const Color(0xCCF8F9FA);
    final Color customPrimary = isDark ? const Color(0xFF00E5FF) : const Color(0xFF00B4D8); // Turquoise
    final Color customSecondary = isDark ? const Color(0xFFC6A0F6) : const Color(0xFFB8C0E0); // Lilac
    final Color customTertiary = isDark ? const Color(0xFFF5BDE6) : const Color(0xFFF4B4D6); // Pink
    final Color customContainer = isDark ? const Color(0xFF3D5A80) : const Color(0xFF1D2D44); // Navy

    return colorScheme.copyWith(
      surface: platform.isCupertino
          ? (colorScheme.brightness == Brightness.light
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray)
          : customBg,
      surfaceContainer: Color.lerp(
        customSurface,
        colorScheme.surfaceTint,
        0.02,
      )!,
      primary: customPrimary,
      secondary: customSecondary,
      tertiary: customTertiary,
      primaryContainer: customContainer,
    );
  }

  static ThemeData getThemeFromYaru(
    YaruThemeData yaru,
    Brightness brightness,
    TargetPlatform platform,
    bool highContrast,
  ) {
    final base = highContrast
        ? (brightness == Brightness.light ? yaruHighContrastLight : yaruHighContrastDark)
        : (brightness == Brightness.light ? yaru.theme : yaru.darkTheme);
    return getThemeFromYaruFixed(base, platform);
  }

  static ThemeData getThemeFromYaruFixed(
    ThemeData base,
    TargetPlatform platform,
  ) {
    final textTheme = _Components.textTheme(platform, base.colorScheme);
    final fontFamily = textTheme.bodyMedium!.fontFamily;
    final fontFamilyFallback = textTheme.bodyMedium!.fontFamilyFallback;
    return base.copyWith(
      platform: platform,
      textTheme: textTheme,
      progressIndicatorTheme: _Components.progressIndicatorTheme,
      cardTheme: _Components.cardTheme(base.colorScheme),
      cupertinoOverrideTheme: _Components.cupertinoOverrideTheme,
      listTileTheme: base.listTileTheme.copyWith(
        // Yaru forces list tiles to use Ubuntu font, fix that
        titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        subtitleTextStyle: base.listTileTheme.subtitleTextStyle?.copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        leadingAndTrailingTextStyle: base
            .listTileTheme
            .leadingAndTrailingTextStyle
            ?.copyWith(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFamilyFallback,
            ),
      ),
      // Leave Yaru's app bar theme, since it adds a border bottom.
      // appBarTheme: _Components.appBarTheme,
    );
  }
}

abstract class _Components {
  static TextTheme textTheme(TargetPlatform platform, ColorScheme colorScheme) {
    final typography = Typography.material2021(
      platform: platform,
      colorScheme: colorScheme,
    );
    final textTheme = colorScheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;

    if (stows.hyperlegibleFont.value) {
      return textTheme.withFont(
        fontFamily: 'AtkinsonHyperlegibleNext',
        fontFamilyFallback: saberSansSerifFontFallbacks,
      );
    } else if (platform == TargetPlatform.linux) {
      // Flutter picks Roboto but Adwaita Sans is a better default
      return textTheme.withFont(fontFamily: 'Adwaita Sans');
    } else {
      return textTheme;
    }
  }

  static const progressIndicatorTheme = ProgressIndicatorThemeData(
    // ignore: deprecated_member_use
    year2023: false,
    stopIndicatorColor: Colors.transparent,
  );

  static CardThemeData cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kYaruContainerRadius)),
        side: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }

  static const cupertinoOverrideTheme = NoDefaultCupertinoThemeData(
    applyThemeToAll: true,
  );

  static const appBarTheme = AppBarTheme(centerTitle: false);
}

extension SaberThemePlatform on TargetPlatform {
  /// iOS uses Yaru's colorscheme since it looks more native than M3.
  bool get usesYaruColors => switch (this) {
    TargetPlatform.linux => true,
    TargetPlatform.iOS => true,
    TargetPlatform.macOS => true,
    _ => false,
  };

  bool get isCupertino => switch (this) {
    TargetPlatform.iOS => true,
    TargetPlatform.macOS => true,
    _ => false,
  };
}
