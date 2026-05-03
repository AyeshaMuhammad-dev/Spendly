import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/screens/auth_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'PKR';

  final List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP'];

  // Real Firebase user data
  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  }

  String get _userEmail {
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._currencies.map(
                  (c) => GestureDetector(
                onTap: () {
                  setState(() => _selectedCurrency = c);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedCurrency == c)
                        const Icon(
                          Icons.check,
                          color: AppColors.primary,
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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: AppColors.textSecondary,
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
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: AppColors.expense,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
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
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Center(
                                child: Text(
                                  '👤',
                                  style: TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userEmail,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const EditProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
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
                      subtitle: _selectedCurrency,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onTap: _showCurrencyPicker,
                    ),
                    _settingRow(
                      icon: '🔔',
                      iconBg: const Color(0xFF2a2a1a),
                      title: 'Notifications',
                      subtitle: 'Daily reminder at 9 PM',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                        activeColor: AppColors.primary,
                      ),
                      onTap: null,
                    ),
                    _settingRow(
                      icon: '🌙',
                      iconBg: const Color(0xFF1a1a2a),
                      title: 'Dark Mode',
                      subtitle: ref.watch(themeProvider) == ThemeMode.dark
                          ? 'Currently enabled'
                          : 'Currently disabled',
                      trailing: Switch(
                        value: ref.watch(themeProvider) == ThemeMode.dark,
                        onChanged: (v) =>
                            ref.read(themeProvider.notifier).setDarkMode(v),
                        activeColor: AppColors.primary,
                      ),
                      onTap: null,
                    ),

                    const SizedBox(height: 8),

                    _sectionLabel('Data'),
                    _settingRow(
                      icon: '📤',
                      iconBg: const Color(0xFF1a2a2a),
                      title: 'Export Data',
                      subtitle: 'Download as CSV',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export coming soon'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    _settingRow(
                      icon: '🔒',
                      iconBg: const Color(0xFF2a1a2a),
                      title: 'Privacy',
                      subtitle: 'Biometric lock',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onTap: () {},
                    ),

                    const SizedBox(height: 8),

                    _sectionLabel('About'),
                    _settingRow(
                      icon: 'ℹ️',
                      iconBg: AppColors.surfaceVariant,
                      title: 'App Version',
                      subtitle: '1.0.0',
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
                            color: AppColors.expenseContainer,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusSm,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.expense,
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
                        child: const Center(
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textTertiary,
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
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
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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