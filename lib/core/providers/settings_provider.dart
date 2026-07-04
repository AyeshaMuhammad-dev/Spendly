import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class SettingsNotifier extends StateNotifier<bool> {
  SettingsNotifier() : super(false) {
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    state = enabled;
  }
}

final biometricProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier();
});

class NotificationTimeNotifier extends StateNotifier<TimeOfDay> {
  NotificationTimeNotifier() : super(const TimeOfDay(hour: 21, minute: 0)) {
    _loadNotificationTime();
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 21;
    final minute = prefs.getInt('notification_minute') ?? 0;
    state = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);
    state = time;
  }
}

final notificationTimeProvider =
    StateNotifierProvider<NotificationTimeNotifier, TimeOfDay>((ref) {
  return NotificationTimeNotifier();
});

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  NotificationsNotifier(this._ref) : super(false) {
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? false;
    
    // Ensure schedule matches state on app start
    if (state) {
      final time = _ref.read(notificationTimeProvider);
      await NotificationService().scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    state = enabled;

    if (enabled) {
      final time = _ref.read(notificationTimeProvider);
      await NotificationService().requestPermission();
      await NotificationService().scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> reschedule() async {
    if (state) {
      final time = _ref.read(notificationTimeProvider);
      await NotificationService().scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
    }
  }
}

final notificationsProvider =
StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref);
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('PKR') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('selected_currency') ?? 'PKR';
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
    state = currency;
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  switch (currency) {
    case 'PKR':
      return 'Rs';
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return 'Rs';
  }
});
