import 'package:flutter/material.dart';

class AppColors {
  const AppColors();

  static const background     = Color(0xFF0D0D0D);
  static const surface        = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF242424);
  static const elevated       = Color(0xFF2A2A2A);

  static const primary          = Color(0xFF00D4AA);
  static const primaryDark      = Color(0xFF00A886);
  static const primaryContainer = Color(0xFF003D30);

  static const income           = Color(0xFF00D4AA);
  static const expense          = Color(0xFFFF5B5B);
  static const expenseContainer = Color(0xFF3D1515);

  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const textTertiary  = Color(0xFF616161);

  static const divider = Color(0xFF242424);
  static const error   = Color(0xFFFF5B5B);
  static const warning = Color(0xFFFFB020);

  static const catFood          = Color(0xFFFF8C42);
  static const catTransport     = Color(0xFF4ECDC4);
  static const catShopping      = Color(0xFFFF6B9D);
  static const catHealth        = Color(0xFF95E1D3);
  static const catEntertainment = Color(0xFFA855F7);
  static const catBills         = Color(0xFFFFB020);
  static const catOther         = Color(0xFF9E9E9E);

  // Instance getters for context.colors access
  Color get backgroundProp => background;
  Color get surfaceProp => surface;
  // ... this is getting messy. Let's use a better approach.
}

extension AppColorsExtension on BuildContext {
  _AppColorsProxy get colors => const _AppColorsProxy();
}

class _AppColorsProxy {
  const _AppColorsProxy();

  Color get background => AppColors.background;
  Color get surface => AppColors.surface;
  Color get surfaceVariant => AppColors.surfaceVariant;
  Color get elevated => AppColors.elevated;
  Color get primary => AppColors.primary;
  Color get primaryDark => AppColors.primaryDark;
  Color get primaryContainer => AppColors.primaryContainer;
  Color get income => AppColors.income;
  Color get expense => AppColors.expense;
  Color get expenseContainer => AppColors.expenseContainer;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;
  Color get textTertiary => AppColors.textTertiary;
  Color get divider => AppColors.divider;
  Color get error => AppColors.error;
  Color get warning => AppColors.warning;
  Color get catFood => AppColors.catFood;
  Color get catTransport => AppColors.catTransport;
  Color get catShopping => AppColors.catShopping;
  Color get catHealth => AppColors.catHealth;
  Color get catEntertainment => AppColors.catEntertainment;
  Color get catBills => AppColors.catBills;
  Color get catOther => AppColors.catOther;
}