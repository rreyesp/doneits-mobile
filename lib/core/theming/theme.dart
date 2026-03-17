import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE97A16),
    surfaceTint: Color(0xFFE97A16),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD8B5),
    onPrimaryContainer: Color(0xFF2B1600),
    secondary: Color(0xFFF2A64A),
    onSecondary: Color(0xFF402000),
    secondaryContainer: Color(0xFFFFE6CC),
    onSecondaryContainer: Color(0xFF4A2800),
    tertiary: Color(0xFF0EA5D9),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCBEFFF),
    onTertiaryContainer: Color(0xFF002B3A),
    error: Color(0xffba1a1a),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff93000a),
    surface: Color(0xFFFFFBF7),
    onSurface: Color(0xFF231A12),
    onSurfaceVariant: Color(0xFF5A4A3D),
    outline: Color(0xFF8B7768),
    outlineVariant: Color(0xFFE4D4C7),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFF392E25),
    inversePrimary: Color(0xFFFFB876),
    primaryFixed: Color(0xFFFFE3CA),
    onPrimaryFixed: Color(0xFF2B1600),
    primaryFixedDim: Color(0xFFFFB876),
    onPrimaryFixedVariant: Color(0xFF8A4300),
    secondaryFixed: Color(0xFFFFE3CA),
    onSecondaryFixed: Color(0xFF2B1600),
    secondaryFixedDim: Color(0xFFF2A64A),
    onSecondaryFixedVariant: Color(0xFF6A3B00),
    tertiaryFixed: Color(0xFFCBEFFF),
    onTertiaryFixed: Color(0xFF001F2A),
    tertiaryFixedDim: Color(0xFF7ED3F7),
    onTertiaryFixedVariant: Color(0xFF00526E),
    surfaceDim: Color(0xFFE8D8CB),
    surfaceBright: Color(0xFFFFFBF7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFCF4EE),
    surfaceContainer: Color(0xFFF7EFE8),
    surfaceContainerHigh: Color(0xFFF1E9E2),
    surfaceContainerHighest: Color(0xFFEBE3DC),
  );
}

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8A4300),
    surfaceTint: Color(0xFFE97A16),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCF6500),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF7A4300),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0932F),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF005F80),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF1299CC),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xff740006),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffcf2c27),
    onErrorContainer: Color(0xffffffff),
    surface: Color(0xFFFFFBF7),
    onSurface: Color(0xFF1A120B),
    onSurfaceVariant: Color(0xFF46372B),
    outline: Color(0xFF645245),
    outlineVariant: Color(0xFF7F6C5E),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFF392E25),
    inversePrimary: Color(0xFFFFB876),
    primaryFixed: Color(0xFFCF6500),
    onPrimaryFixed: Color(0xFFFFFFFF),
    primaryFixedDim: Color(0xFFA65000),
    onPrimaryFixedVariant: Color(0xFFFFFFFF),
    secondaryFixed: Color(0xFFE0932F),
    onSecondaryFixed: Color(0xFFFFFFFF),
    secondaryFixedDim: Color(0xFFB86D11),
    onSecondaryFixedVariant: Color(0xFFFFFFFF),
    tertiaryFixed: Color(0xFF1299CC),
    onTertiaryFixed: Color(0xFFFFFFFF),
    tertiaryFixedDim: Color(0xFF0077A1),
    onTertiaryFixedVariant: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFD6C7BB),
    surfaceBright: Color(0xFFFFFBF7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFCF4EE),
    surfaceContainer: Color(0xFFF1E9E2),
    surfaceContainerHigh: Color(0xFFE7DFD8),
    surfaceContainerHighest: Color(0xFFDDD5CE),
  );
}

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6D3400),
    surfaceTint: Color(0xFFE97A16),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF9C4C00),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF643600),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF9A5B00),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF004D67),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF00749D),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xff600004),
    onError: Color(0xffffffff),
    errorContainer: Color(0xff98000a),
    onErrorContainer: Color(0xffffffff),
    surface: Color(0xFFFFFBF7),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF000000),
    outline: Color(0xFF3A2D22),
    outlineVariant: Color(0xFF5A4A3D),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFF392E25),
    inversePrimary: Color(0xFFFFB876),
    primaryFixed: Color(0xFF9C4C00),
    onPrimaryFixed: Color(0xFFFFFFFF),
    primaryFixedDim: Color(0xFF7A3A00),
    onPrimaryFixedVariant: Color(0xFFFFFFFF),
    secondaryFixed: Color(0xFF9A5B00),
    onSecondaryFixed: Color(0xFFFFFFFF),
    secondaryFixedDim: Color(0xFF744000),
    onSecondaryFixedVariant: Color(0xFFFFFFFF),
    tertiaryFixed: Color(0xFF00749D),
    onTertiaryFixed: Color(0xFFFFFFFF),
    tertiaryFixedDim: Color(0xFF00566F),
    onTertiaryFixedVariant: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFCABBAF),
    surfaceBright: Color(0xFFFFFBF7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F0E9),
    surfaceContainer: Color(0xFFEBE3DC),
    surfaceContainerHigh: Color(0xFFDED6CF),
    surfaceContainerHighest: Color(0xFFD1C9C2),
  );
}

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB876),
    surfaceTint: Color(0xFFFFB876),
    onPrimary: Color(0xFF4B2500),
    primaryContainer: Color(0xFFE97A16),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFF2C38C),
    onSecondary: Color(0xFF4A2800),
    secondaryContainer: Color(0xFF8B5000),
    onSecondaryContainer: Color(0xFFFFE6CC),
    tertiary: Color(0xFF7ED3F7),
    onTertiary: Color(0xFF003547),
    tertiaryContainer: Color(0xFF0EA5D9),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),
    surface: Color(0xFF17120D),
    onSurface: Color(0xFFF0E0D3),
    onSurfaceVariant: Color(0xFFD8C3B3),
    outline: Color(0xFFA58E7E),
    outlineVariant: Color(0xFF5A4A3D),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFFF0E0D3),
    inversePrimary: Color(0xFF8A4300),
    primaryFixed: Color(0xFFFFE3CA),
    onPrimaryFixed: Color(0xFF2B1600),
    primaryFixedDim: Color(0xFFFFB876),
    onPrimaryFixedVariant: Color(0xFF8A4300),
    secondaryFixed: Color(0xFFFFE3CA),
    onSecondaryFixed: Color(0xFF2B1600),
    secondaryFixedDim: Color(0xFFF2A64A),
    onSecondaryFixedVariant: Color(0xFF6A3B00),
    tertiaryFixed: Color(0xFFCBEFFF),
    onTertiaryFixed: Color(0xFF001F2A),
    tertiaryFixedDim: Color(0xFF7ED3F7),
    onTertiaryFixedVariant: Color(0xFF00526E),
    surfaceDim: Color(0xFF17120D),
    surfaceBright: Color(0xFF40352B),
    surfaceContainerLowest: Color(0xFF120D09),
    surfaceContainerLow: Color(0xFF231D18),
    surfaceContainer: Color(0xFF28211C),
    surfaceContainerHigh: Color(0xFF332B25),
    surfaceContainerHighest: Color(0xFF3E352F),
  );
}

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFD8B5),
    surfaceTint: Color(0xFFFFB876),
    onPrimary: Color(0xFF3D1D00),
    primaryContainer: Color(0xFFFF9B3D),
    onPrimaryContainer: Color(0xFF000000),
    secondary: Color(0xFFFFDFC1),
    onSecondary: Color(0xFF3B1E00),
    secondaryContainer: Color(0xFFF2A64A),
    onSecondaryContainer: Color(0xFF000000),
    tertiary: Color(0xFFCBEFFF),
    onTertiary: Color(0xFF00293A),
    tertiaryContainer: Color(0xFF45BCEB),
    onTertiaryContainer: Color(0xFF000000),
    error: Color(0xffffd2cc),
    onError: Color(0xff540003),
    errorContainer: Color(0xffff5449),
    onErrorContainer: Color(0xff000000),
    surface: Color(0xFF17120D),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFF0DCCC),
    outline: Color(0xFFC3AB9A),
    outlineVariant: Color(0xFFA58E7E),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFFF0E0D3),
    inversePrimary: Color(0xFF7A3A00),
    primaryFixed: Color(0xFFFFE3CA),
    onPrimaryFixed: Color(0xFF1A0C00),
    primaryFixedDim: Color(0xFFFFB876),
    onPrimaryFixedVariant: Color(0xFF6D3400),
    secondaryFixed: Color(0xFFFFE3CA),
    onSecondaryFixed: Color(0xFF1A0C00),
    secondaryFixedDim: Color(0xFFF2A64A),
    onSecondaryFixedVariant: Color(0xFF643600),
    tertiaryFixed: Color(0xFFCBEFFF),
    onTertiaryFixed: Color(0xFF00131C),
    tertiaryFixedDim: Color(0xFF7ED3F7),
    onTertiaryFixedVariant: Color(0xFF004D67),
    surfaceDim: Color(0xFF17120D),
    surfaceBright: Color(0xFF4B4036),
    surfaceContainerLowest: Color(0xFF0D0905),
    surfaceContainerLow: Color(0xFF251F19),
    surfaceContainer: Color(0xFF302924),
    surfaceContainerHigh: Color(0xFF3B332D),
    surfaceContainerHighest: Color(0xFF473D37),
  );
}

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFF0E3),
    surfaceTint: Color(0xFFFFB876),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFFFFD1A3),
    onPrimaryContainer: Color(0xFF130900),
    secondary: Color(0xFFFFF0E3),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFFFFD1A3),
    onSecondaryContainer: Color(0xFF130900),
    tertiary: Color(0xFFF1FAFF),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFFBEEBFF),
    onTertiaryContainer: Color(0xFF00131C),
    error: Color(0xffffece9),
    onError: Color(0xff000000),
    errorContainer: Color(0xffffaea4),
    onErrorContainer: Color(0xff220001),
    surface: Color(0xFF17120D),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFFFFFFF),
    outline: Color(0xFFFFF0E3),
    outlineVariant: Color(0xFFD8C3B3),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xFFF0E0D3),
    inversePrimary: Color(0xFF7A3A00),
    primaryFixed: Color(0xFFFFE3CA),
    onPrimaryFixed: Color(0xFF000000),
    primaryFixedDim: Color(0xFFFFB876),
    onPrimaryFixedVariant: Color(0xFF1A0C00),
    secondaryFixed: Color(0xFFFFE3CA),
    onSecondaryFixed: Color(0xFF000000),
    secondaryFixedDim: Color(0xFFF2A64A),
    onSecondaryFixedVariant: Color(0xFF1A0C00),
    tertiaryFixed: Color(0xFFCBEFFF),
    onTertiaryFixed: Color(0xFF000000),
    tertiaryFixedDim: Color(0xFF7ED3F7),
    onTertiaryFixedVariant: Color(0xFF00131C),
    surfaceDim: Color(0xFF17120D),
    surfaceBright: Color(0xFF564A41),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF28211C),
    surfaceContainer: Color(0xFF392F29),
    surfaceContainerHigh: Color(0xFF443B34),
    surfaceContainerHighest: Color(0xFF504640),
  );
}

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  /// success
  static const success = ExtendedColor(
    seed: Color(0xff00db60),
    value: Color(0xff00db60),
    light: ColorFamily(
      color: Color(0xff006e2c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xff006e2c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xff006e2c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
    dark: ColorFamily(
      color: Color(0xff43f879),
      onColor: Color(0xff003913),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xff43f879),
      onColor: Color(0xff003913),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xff43f879),
      onColor: Color(0xff003913),
      colorContainer: Color(0xff00db60),
      onColorContainer: Color(0xff005a23),
    ),
  );

  /// danger
  static const danger = ExtendedColor(
    seed: Color(0xffff4136),
    value: Color(0xffff4136),
    light: ColorFamily(
      color: Color(0xffbb020c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffe02923),
      onColorContainer: Color(0xfffffbff),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xffbb020c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffe02923),
      onColorContainer: Color(0xfffffbff),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xffbb020c),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffe02923),
      onColorContainer: Color(0xfffffbff),
    ),
    dark: ColorFamily(
      color: Color(0xffffb4aa),
      onColor: Color(0xff690003),
      colorContainer: Color(0xffff5446),
      onColorContainer: Color(0xff4f0002),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xffffb4aa),
      onColor: Color(0xff690003),
      colorContainer: Color(0xffff5446),
      onColorContainer: Color(0xff4f0002),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xffffb4aa),
      onColor: Color(0xff690003),
      colorContainer: Color(0xffff5446),
      onColorContainer: Color(0xff4f0002),
    ),
  );

  /// warning
  static const warning = ExtendedColor(
    seed: Color(0xffff851b),
    value: Color(0xffff851b),
    light: ColorFamily(
      color: Color(0xff964900),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xff964900),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xff964900),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
    dark: ColorFamily(
      color: Color(0xffffb787),
      onColor: Color(0xff502400),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xffffb787),
      onColor: Color(0xff502400),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xffffb787),
      onColor: Color(0xff502400),
      colorContainer: Color(0xffff851b),
      onColorContainer: Color(0xff612d00),
    ),
  );

  List<ExtendedColor> get extendedColors => [success, danger, warning];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
