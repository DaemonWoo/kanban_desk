import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.background,

    cardColor: AppColors.cardBackground,

    dividerColor: AppColors.border,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.cardBackground,
    ),
  );
}
