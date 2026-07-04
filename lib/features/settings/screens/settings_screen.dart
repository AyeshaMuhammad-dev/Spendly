import 'dart:io';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/settings_provider.dart';
import '../../auth/screens/auth_screen.dart';
import '../../transactions/providers/transaction_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'Loading...';

  final List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  // Real Firebase user data
  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  }

  String get _userEmail {
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  String? get _photoUrl => null;

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._currencies.map(
                  (c) => GestureDetector(
                onTap: () {
                  ref.read(currencyProvider.notifier).setCurrency(c);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: context.colors.divider,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (ref.watch(currencyProvider) == c)
                        Icon(
                          Icons.check,
                          color: context.colors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Renamed to Log Out
  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Log Out',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Real Firebase sign out
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Fresh Start',
          style: TextStyle(
            color: context.colors.expense,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This will permanently delete all your transactions (income and expenses). This cannot be undone. Do you want to proceed?',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(addTransactionProvider.notifier).deleteAllTransactions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All data cleared successfully'),
                      backgroundColor: context.colors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: context.colors.expense,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final transactions = await repo.getAllTransactionsFuture();
      
      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      List<List<dynamic>> rows = [
        ['Date', 'Title', 'Category', 'Amount', 'Type', 'Note']
      ];

      for (var t in transactions) {
        rows.add([
          t.date.toIso8601String(),
          t.title,
          t.category,
          t.amount,
          t.isExpense ? 'Expense' : 'Income',
          t.note ?? ''
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spendly_export.csv');
      await file.writeAsString(csvData);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'My Spendly Data Export');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: context.colors.expense,
          ),
        );
      }
    }
  }

  Future<void> _pickNotificationTime() async {
    final currentTime = ref.read(notificationTimeProvider);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              onPrimary: Colors.white,
              surface: context.colors.surface,
              onSurface: context.colors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      await ref.read(notificationTimeProvider.notifier).setNotificationTime(picked);
      // Reschedule if notifications are enabled
      await ref.read(notificationsProvider.notifier).reschedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification time updated to ${picked.format(context)}'),
            backgroundColor: context.colors.primary,
          ),
        );
      }
    }
  }

  void _showReauthDialog(VoidCallback onReauthenticated) {
    final controller = TextEditingController();
    bool isReauthLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text(
            'Confirm Password',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For security, please enter your password to continue.',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (isReauthLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isReauthLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isReauthLoading
                  ? null
                  : () async {
                if (controller.text.isEmpty) return;
                setDialogState(() => isReauthLoading = true);
                try {
                  await ref
                      .read(addTransactionProvider.notifier)
                      .reauthenticate(controller.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    onReauthenticated();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Invalid password'),
                        backgroundColor: context.colors.expense,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setDialogState(() => isReauthLoading = false);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isLoading = ref.watch(addTransactionProvider).isLoading;

          return AlertDialog(
            backgroundColor: context.colors.surface,
            title: Text(
              'Delete Account',
              style: TextStyle(
                color: context.colors.expense,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete your account and all data. This cannot be undone.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: CircularProgressIndicator(
                      color: context.colors.expense,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  try {
                    await ref
                        .read(addTransactionProvider.notifier)
                        .deleteAccount();

                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AuthScreen()),
                            (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      if (e is FirebaseAuthException &&
                          e.code == 'requires-recent-login') {
                        Navigator.pop(context); // Close delete dialog
                        _showReauthDialog(() {
                          _showDeleteDialog(); // Re-open delete dialog after re-auth
                        });
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: context.colors.expense,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.expense,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: context.colors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile card — real Firebase data
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                      ),
                      child: Container(
                        padding:
                        const EdgeInsets.all(AppSpacing.cardPadding),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 4), // Small padding instead of icon
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userEmail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const EditProfileScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  setState(() {}); // Refresh to show new photo/name
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionLabel('Preferences'),
                    _settingRow(
                      icon: '💱',
                      iconBg: const Color(0xFF1a2a1a),
                      title: 'Currency',
                      subtitle: ref.watch(currencyProvider),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.colors.textTertiary,
                        size: 20,
                      ),
                      onTap: _showCurrencyPicker,
                    ),
                    _settingRow(
                      icon: '🔔',
                      iconBg: const Color(0xFF2a2a1a),
                      title: 'Notifications',
                      subtitle: 'Daily reminder at ${ref.watch(notificationTimeProvider).format(context)}',
                      trailing: Switch(
                        value: ref.watch(notificationsProvider),
                        onChanged: (v) => ref
                            .read(notificationsProvider.notifier)
                            .setNotificationsEnabled(v),
                        activeThumbColor: context.colors.primary,
                      ),
                      onTap: _pickNotificationTime,
                    ),


                    const SizedBox(height: 8),

                    _sectionLabel('Data'),
                    _settingRow(
                      icon: '🔄',
                      iconBg: const Color(0xFF2a1a1a),
                      title: 'Fresh Start',
                      subtitle: 'Clear all transactions',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.colors.textTertiary,
                        size: 20,
                      ),
                      onTap: _showClearDataDialog,
                    ),
                    _settingRow(
                      icon: '📤',
                      iconBg: const Color(0xFF1a2a2a),
                      title: 'Export Data',
                      subtitle: 'Download as CSV',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.colors.textTertiary,
                        size: 20,
                      ),
                      onTap: _exportData,
                    ),
                    _settingRow(
                      icon: '🔒',
                      iconBg: const Color(0xFF2a1a2a),
                      title: 'Privacy',
                      subtitle: 'Biometric lock',
                      trailing: Switch(
                        value: ref.watch(biometricProvider),
                        onChanged: (v) async {
                          if (v) {
                            // Try to authenticate before enabling
                            final localAuth = LocalAuthentication();
                            bool canCheckBiometrics = await localAuth.canCheckBiometrics;
                            bool isSupported = await localAuth.isDeviceSupported();
                            
                            if (canCheckBiometrics || isSupported) {
                              try {
                                bool didAuthenticate = await localAuth.authenticate(
                                  localizedReason: 'Please authenticate to enable biometric lock',
                                );
                                if (didAuthenticate) {
                                  ref.read(biometricProvider.notifier).setBiometricEnabled(true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: context.colors.expense),
                                  );
                                }
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Biometrics not supported on this device'), backgroundColor: context.colors.expense),
                                );
                              }
                            }
                          } else {
                            ref.read(biometricProvider.notifier).setBiometricEnabled(false);
                          }
                        },
                        activeThumbColor: context.colors.primary,
                      ),
                      onTap: null,
                    ),

                    const SizedBox(height: 8),

                    _sectionLabel('About'),
                    _settingRow(
                      icon: 'ℹ️',
                      iconBg: context.colors.surfaceVariant,
                      title: 'App Version',
                      subtitle: _appVersion,
                      trailing: null,
                      onTap: null,
                    ),

                    const SizedBox(height: 24),

                    // Log Out button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                      ),
                      child: GestureDetector(
                        onTap: _showLogOutDialog,
                        child: Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: context.colors.expenseContainer,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusSm,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.colors.expense,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                      ),
                      child: GestureDetector(
                        onTap: _showDeleteDialog,
                        child: Center(
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.textTertiary,
                              decoration: TextDecoration.underline,
                              decorationColor: context.colors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: 8,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingRow({
    required String icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
