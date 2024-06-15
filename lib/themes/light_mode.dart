import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.grey.shade900,
    secondary: Colors.black,
    background: Colors.white,
    onBackground: Colors.grey.shade300,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.grey.shade900,
    displayColor: Colors.black,
  ),
);