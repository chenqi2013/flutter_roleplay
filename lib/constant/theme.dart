import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.dark),
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.black, elevation: 0, surfaceTintColor: Colors.transparent),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
  hoverColor: Colors.transparent,
  textButtonTheme: const TextButtonThemeData(style: ButtonStyle(overlayColor: WidgetStatePropertyAll<Color?>(Colors.transparent))),
  elevatedButtonTheme: const ElevatedButtonThemeData(style: ButtonStyle(overlayColor: WidgetStatePropertyAll<Color?>(Colors.transparent))),
  outlinedButtonTheme: const OutlinedButtonThemeData(style: ButtonStyle(overlayColor: WidgetStatePropertyAll<Color?>(Colors.transparent))),
);
