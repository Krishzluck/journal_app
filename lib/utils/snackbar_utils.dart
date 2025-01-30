import 'package:flutter/material.dart';

void showThemedSnackBar(BuildContext context, String message, {bool isError = false}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.white,
        ),
      ),
      backgroundColor: isError 
          ? Colors.red 
          : Theme.of(context).primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
} 