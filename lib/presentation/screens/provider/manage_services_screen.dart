import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/service_model.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class ManageServicesScreen extends ConsumerStatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  ConsumerState<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends ConsumerState<ManageServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'active', 'suspended'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('غير مصرح')));
    }

    final servicesAsync = ref.watch(providerServicesProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myServices),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addService),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addService, style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: servicesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(count: 5),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(providerServicesProvider(user.id)),
        ),
        data: (allServices) {
          if (allServices.isEmpty) {
            return EmptyStateWidget(
              title: AppStrings.noServices,
              subtitle: 'لم تقم بإضافة أي خدمة بعد. ابدأ بإضافة أول خدمة لك الآن!',
              icon: Icons.business_outlined,
              action: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addService),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addService),
              ),
            );
          }

          final activeCount = allServices.where((s) => !s.isSuspended).length;
          final suspendedCount = allServices.where((s) => s.isSuspended).length;

          // Filter by status and search query
          final filteredServices = allServices.where((s) {
            final matchesStatus = switch (_selectedStatus) {
              'active' => !s.isSuspended,
              'suspended' => s.isSuspended,
              _ => true,
            };

            final matchesQuery = _searchQuery.isEmpty ||
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (s.category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (s.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

            return matchesStatus && matchesQuery;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث في خدماتك...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 10),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('الكل (${allServices.length})', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('النشطة ($activeCount)', 'active', color: AppColors.success),
                          const SizedBox(width: 8),
                          _buildFilterChip('الموقفة ($suspendedCount)', 'suspended', color: AppColors.warning),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد خدمات مطابقة للبحث أو الفلتر',
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(providerServicesProvider(user.id)),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: filteredServices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            return _buildServiceCard(context, service, user.id, index);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _selectedStatus == value;
    final activeColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedStatus = value),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceModel service, String providerId, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: service.isSuspended
            ? Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.2)
            : Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Column(
        children: [
          // Upper Info Section
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => context.push('/services/${service.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Image / Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primary.withOpacity(0.08),
                      child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                          ? Image.network(
                              service.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.business_outlined,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            )
                          : const Icon(
                              Icons.business_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Service Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: service.isSuspended
                                    ? AppColors.warning.withOpacity(0.12)
                                    : AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    service.isSuspended ? Icons.pause_circle_filled : Icons.check_circle,
                                    size: 12,
                                    color: service.isSuspended ? AppColors.warning : AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    service.isSuspended ? 'موقفة' : 'نشطة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: service.isSuspended ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (service.category != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              service.category!.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],

                        if (service.address != null && service.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  service.address!,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.8),

          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Preview Button
                TextButton.icon(
                  onPressed: () => context.push('/services/${service.id}'),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.info),
                  label: const Text(
                    'معاينة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.info),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                // Edit Button
                TextButton.icon(
                  onPressed: () => context.push('/provider/services/${service.id}/edit', extra: service),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    AppStrings.edit,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                const Spacer(),

                // Toggle Suspension Button
                IconButton(
                  tooltip: service.isSuspended ? AppStrings.activateService : AppStrings.suspendService,
                  icon: Icon(
                    service.isSuspended ? Icons.play_circle_outline : Icons.pause_circle_outline,
                    color: service.isSuspended ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  onPressed: () => _toggleSuspension(context, ref, service, providerId),
                ),

                // Delete Button
                IconButton(
                  tooltip: AppStrings.deleteService,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _deleteService(context, ref, service.id, providerId),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: (index * 40).clamp(0, 300))).fadeIn().slideY(begin: 0.08);
  }

  Future<void> _toggleSuspension(
      BuildContext context, WidgetRef ref, ServiceModel service, String providerId) async {
    final nextStatus = !service.isSuspended;
    await ref
        .read(serviceCrudProvider.notifier)
        .toggleSuspension(service.id, nextStatus, providerId: providerId);

    if (context.mounted) {
      AppHelpers.showSuccess(
        context,
        nextStatus ? 'تم تعليق الخدمة مؤقتاً' : 'تم تفعيل الخدمة بنجاح',
      );
    }
  }

  Future<void> _deleteService(
      BuildContext context, WidgetRef ref, String serviceId, String providerId) async {
    final confirm = await AppHelpers.showDeleteDialog(context, 'هذه الخدمة');
    if (confirm != true) return;

    await ref.read(serviceCrudProvider.notifier).deleteService(serviceId, providerId: providerId);

    if (context.mounted) {
      AppHelpers.showSuccess(context, 'تم حذف الخدمة بنجاح');
    }
  }
}
