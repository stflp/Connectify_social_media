import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  scaffoldBackgroundColor: Colors.black,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade400,
    secondary: Colors.white,
    background: Colors.black,
    onBackground: Colors.grey.shade900,
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.grey.shade200,
    displayColor: Colors.white,
  ),
);