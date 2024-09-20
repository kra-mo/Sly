import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

final lightThemeData = ThemeData(
  useMaterial3: true,
  fontFamily: 'Geist',
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  disabledColor: const Color(0xFFDADBDF),
  focusColor: const Color(0xFF212A40).withOpacity(0.12),
  hoverColor: const Color(0xFF212A40).withOpacity(0.06),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF2E3133),
    onPrimary: Colors.white,
    secondary: const Color(0xFFDBDFE7),
    onSecondary: const Color(0xFF2E3133),
    error: Colors.red.shade200,
    onError: Colors.black,
    surface: const Color(0xFFF3F4F6),
    onSurface: const Color(0xFF2E3133),
  ),
);

final darkThemeData = ThemeData(
  useMaterial3: true,
  fontFamily: 'Geist',
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  disabledColor: Colors.grey.shade700,
  hintColor: Colors.grey.shade500,
  focusColor: Colors.white12,
  hoverColor: Colors.white10,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.grey.shade900,
    secondary: Colors.grey.shade800,
    onSecondary: Colors.white,
    error: Colors.red.shade900,
    onError: Colors.white,
    surface: Colors.grey.shade900,
    onSurface: Colors.white,
  ),
);

class LightTheme extends StatelessWidget {
  const LightTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.light),
      child: Theme(data: lightThemeData, child: child),
    );
  }
}

class DarkTheme extends StatelessWidget {
  const DarkTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: Theme(data: darkThemeData, child: child),
    );
  }
}