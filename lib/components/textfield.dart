import 'package:flutter/material.dart';

class Textfield extends StatelessWidget {
  final String labelText;
  final bool isPassword;
  final TextEditingController controller;

  const Textfield({
    super.key,
    required this.labelText,
    required this.isPassword,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        labelText: labelText,
      ),
      obscureText: isPassword,
    );
  }
}