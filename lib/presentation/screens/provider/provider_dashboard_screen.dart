import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.providerDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.business, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، ${user?.username ?? ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                        ),
                        Text(
                          user?.isGovtProvider == true ? '🏛️ مزود حكومي' : '🏢 مزود خاص',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // Services Count
            if (user != null)
              _buildServicesSummary(context, ref, user.id),

            const SizedBox(height: 28),
            Text('الإجراءات', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),

            // Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(context,
                    icon: Icons.add_circle_outline,
                    title: AppStrings.addService,
                    color: AppColors.success,
                    onTap: () => context.push(AppRoutes.addService),
                    delay: 0),
                _buildActionCard(context,
                    icon: Icons.list_alt_outlined,
                    title: AppStrings.myServices,
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.manageServices),
                    delay: 50),
                _buildActionCard(context,
                    icon: Icons.person_outline,
                    title: AppStrings.myProfile,
                    color: AppColors.info,
                    onTap: () => context.push(AppRoutes.profile),
                    delay: 100),
                _buildActionCard(context,
                    icon: Icons.home_outlined,
                    title: AppStrings.home,
                    color: AppColors.accent,
                    onTap: () => context.go(AppRoutes.home),
                    delay: 150),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSummary(BuildContext context, WidgetRef ref, String providerId) {
    final servicesAsync = ref.watch(providerServicesProvider(providerId));

    return servicesAsync.when(
      loading: () => Container(
        height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (services) {
        final active = services.where((s) => s.isActive).length;
        final suspended = services.where((s) => s.isSuspended).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard('خدمات نشطة', active.toString(), AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('موقفة', suspended.toString(), AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('المجموع', services.length.toString(), AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap,
      required int delay}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
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
