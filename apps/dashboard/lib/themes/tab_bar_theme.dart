import 'package:dashboard/theme/app_colors.dart';
import 'package:flutter/material.dart';

final tabBarThemeData = TabBarThemeData(
  labelStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
  unselectedLabelStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ),
  dividerColor: AppColors.light.divider,
  indicator: UnderlineTabIndicator(
    borderSide: BorderSide(color: AppColors.light.textPrimary, width: 2),
  ),
  indicatorSize: TabBarIndicatorSize.label,
  labelColor: AppColors.light.textPrimary,
  unselectedLabelColor: AppColors.light.textTertiary,
);
