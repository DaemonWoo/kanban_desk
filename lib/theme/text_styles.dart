import 'package:flutter/material.dart';

import 'colors.dart';

class AppTextStyles {
  static const columnTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const taskText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.cardText,
  );

  static const secondary = TextStyle(
    fontSize: 12,
    color: AppColors.secondaryText,
  );
}
