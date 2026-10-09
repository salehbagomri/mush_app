import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/data/repositories/admin_repository.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final repo = AdminRepository(ref.watch(supabaseClientProvider));
  return repo.getDashboardStats();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، ${user?.username ?? 'مدير النظام'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '👑 لوحة التحكم والإشراف العام على دليل الخدمات',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Stats Cards
              statsAsync.when(
                loading: () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: List.generate(
                    4,
                    (_) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatCard(
                      label: 'الخدمات',
                      value: stats['services']?.toString() ?? '0',
                      icon: Icons.business_outlined,
                      color: AppColors.primary,
                      delay: 0,
                      onTap: () => context.push(AppRoutes.adminServices),
                    ),
                    _buildStatCard(
                      label: 'المزودون',
                      value: stats['providers']?.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: AppColors.info,
                      delay: 50,
                      onTap: () => context.push(AppRoutes.providersManagement),
                    ),
                    _buildStatCard(
                      label: 'المستخدمون',
                      value: stats['users']?.toString() ?? '0',
                      icon: Icons.person_outline,
                      color: AppColors.success,
                      delay: 100,
                      onTap: null,
                    ),
                    _buildStatCard(
                      label: 'التصنيفات',
                      value: stats['categories']?.toString() ?? '0',
                      icon: Icons.category_outlined,
                      color: AppColors.accent,
                      delay: 150,
                      onTap: () => context.push(AppRoutes.categoriesManagement),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text('إدارة النظام', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Management Cards
              _buildManagementCard(
                context,
                icon: Icons.business_outlined,
                title: AppStrings.servicesManagement,
                subtitle: 'مراقبة، تفعيل، تعليق، وحذف كافة الخدمات',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.adminServices),
                delay: 0,
              ),
              _buildManagementCard(
                context,
                icon: Icons.people_outline,
                title: AppStrings.providerManagement,
                subtitle: 'إضافة، تعديل، حجب مزودي الخدمات',
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.providersManagement),
                delay: 50,
              ),
              _buildManagementCard(
                context,
                icon: Icons.category_outlined,
                title: AppStrings.categoriesManagement,
                subtitle: 'إدارة وتعديل تصنيفات الخدمات والأقسام',
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.categoriesManagement),
                delay: 100,
              ),
              _buildManagementCard(
                context,
                icon: Icons.campaign_outlined,
                title: AppStrings.advertisementsManagement,
                subtitle: 'رفع، تفعيل، وإدارة بنرات الإعلانات',
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.advertisementsManagement),
                delay: 150,
              ),
              _buildManagementCard(
                context,
                icon: Icons.person_outline,
                title: AppStrings.myProfile,
                subtitle: 'الملف الشخصي وإعدادات الحساب وتسجيل الخروج',
                color: AppColors.textSecondary,
                onTap: () => context.push(AppRoutes.profile),
                delay: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.18), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 12, color: color.withOpacity(0.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.15);
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ),
        onTap: onTap,
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.08);
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}
