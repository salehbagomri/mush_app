import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.myProfile)),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('يرجى تسجيل الدخول أولاً',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(AppStrings.login),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? const Icon(Icons.person, size: 46, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.username,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleLabel(user.role),
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Menu Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.edit_outlined,
                        title: AppStrings.updateProfile,
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.updateProfile),
                      ),
                      if (user.isProvider)
                        _buildMenuItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          title: AppStrings.providerDashboard,
                          color: AppColors.info,
                          onTap: () => context.push(AppRoutes.providerDashboard),
                        ),
                      if (user.isAdmin)
                        _buildMenuItem(
                          context,
                          icon: Icons.admin_panel_settings_outlined,
                          title: AppStrings.adminDashboard,
                          color: AppColors.governmentColor,
                          onTap: () => context.push(AppRoutes.adminDashboard),
                        ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline,
                        title: AppStrings.aboutUs,
                        color: AppColors.textSecondary,
                        onTap: () => context.push(AppRoutes.about),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: AppStrings.logout,
                        color: AppColors.error,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  String _getRoleLabel(role) {
    switch (role.toString()) {
      case 'UserRole.admin':
        return '👑 مدير النظام';
      case 'UserRole.providerGovt':
        return '🏛️ مزود حكومي';
      case 'UserRole.providerPrivate':
        return '🏢 مزود خاص';
      default:
        return '👤 مستخدم';
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(AppStrings.logout)),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}
