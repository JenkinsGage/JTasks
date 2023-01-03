import 'package:flutter/material.dart';

bool isDarkMode(BuildContext context) {
  var brightness = MediaQuery.of(context).platformBrightness;
  return brightness == Brightness.dark;
}

const ColorScheme flexSchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffd0bcff),
  onPrimary: Color(0xff141214),
  primaryContainer: Color(0xff4f378b),
  onPrimaryContainer: Color(0xffece8f5),
  secondary: Color(0xffccc2dc),
  onSecondary: Color(0xff141314),
  secondaryContainer: Color(0xff4a4458),
  onSecondaryContainer: Color(0xffebeaed),
  tertiary: Color(0xffefb8c8),
  onTertiary: Color(0xff141213),
  tertiaryContainer: Color(0xff633b48),
  onTertiaryContainer: Color(0xffefe9eb),
  error: Color(0xffcf6679),
  onError: Color(0xff140c0d),
  errorContainer: Color(0xffb1384e),
  onErrorContainer: Color(0xfffbe8ec),
  background: Color(0xff1c1b1f),
  onBackground: Color(0xffededed),
  surface: Color(0xff1c1b1f),
  onSurface: Color(0xffededed),
  surfaceVariant: Color(0xff27252d),
  onSurfaceVariant: Color(0xffdddcde),
  outline: Color(0xffa1a1a1),
  shadow: Color(0xff000000),
  inverseSurface: Color(0xfffcfbff),
  onInverseSurface: Color(0xff131314),
  inversePrimary: Color(0xff696078),
  surfaceTint: Color(0xffd0bcff),
);

const ColorScheme flexSchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff6750a4),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xffeaddff),
  onPrimaryContainer: Color(0xff131214),
  secondary: Color(0xff625b71),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffe8def8),
  onSecondaryContainer: Color(0xff131214),
  tertiary: Color(0xff7d5260),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffffd8e4),
  onTertiaryContainer: Color(0xff141213),
  error: Color(0xffb00020),
  onError: Color(0xffffffff),
  errorContainer: Color(0xfffcd8df),
  onErrorContainer: Color(0xff141213),
  background: Color(0xfff9f8fb),
  onBackground: Color(0xff090909),
  surface: Color(0xfff9f8fb),
  onSurface: Color(0xff090909),
  surfaceVariant: Color(0xfff4f2f8),
  onSurfaceVariant: Color(0xff131213),
  outline: Color(0xff565656),
  shadow: Color(0xff000000),
  inverseSurface: Color(0xff141316),
  onInverseSurface: Color(0xfff5f5f5),
  inversePrimary: Color(0xfff0e9ff),
  surfaceTint: Color(0xff6750a4),
);

ColorScheme flexScheme(BuildContext context) {
  if (isDarkMode(context)) {
    return flexSchemeDark;
  } else {
    return flexSchemeLight;
  }
}
