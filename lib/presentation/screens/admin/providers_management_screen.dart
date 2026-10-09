import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/user_model.dart';
import 'package:mush_app/data/repositories/admin_repository.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';

final allProvidersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  final repo = AdminRepository(ref.watch(supabaseClientProvider));
  return repo.getAllProviders();
});

class ProvidersManagementScreen extends ConsumerStatefulWidget {
  const ProvidersManagementScreen({super.key});

  @override
  ConsumerState<ProvidersManagementScreen> createState() => _ProvidersManagementScreenState();
}

class _ProvidersManagementScreenState extends ConsumerState<ProvidersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'govt', 'private', 'blocked'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(allProvidersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.providerManagement),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProviderDialog(context, ref),
        shape: const StadiumBorder(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(AppStrings.addProvider, style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: providersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(count: 6),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(allProvidersProvider),
        ),
        data: (allProviders) {
          if (allProviders.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا يوجد مزودون',
              subtitle: 'أضف مزوداً جديداً للبدء في إدارة الخدمات',
              icon: Icons.people_outline,
            );
          }

          final govtCount = allProviders.where((p) => p.isGovtProvider).length;
          final privateCount = allProviders.where((p) => !p.isGovtProvider).length;
          final blockedCount = allProviders.where((p) => p.isBlocked).length;

          final filteredProviders = allProviders.where((p) {
            final matchesFilter = switch (_selectedFilter) {
              'govt' => p.isGovtProvider,
              'private' => !p.isGovtProvider,
              'blocked' => p.isBlocked,
              _ => true,
            };

            final matchesQuery = _searchQuery.isEmpty ||
                p.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.email.toLowerCase().contains(_searchQuery.toLowerCase());

            return matchesFilter && matchesQuery;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن مزود بالاسم أو البريد...',
                        hintStyle: const TextStyle(
                            fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('الكل (${allProviders.length})', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('حكومي ($govtCount)', 'govt', color: AppColors.governmentColor),
                          const SizedBox(width: 8),
                          _buildFilterChip('خاص ($privateCount)', 'private', color: AppColors.primary),
                          const SizedBox(width: 8),
                          _buildFilterChip('محجوب ($blockedCount)', 'blocked', color: AppColors.error),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Providers List
              Expanded(
                child: filteredProviders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لا يوجد مزودون يطابقون البحث أو الفلتر',
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(allProvidersProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: filteredProviders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final provider = filteredProviders[i];
                            return _buildProviderCard(context, ref, provider, i);
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
    final isSelected = _selectedFilter == value;
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
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildProviderCard(
      BuildContext context, WidgetRef ref, UserModel provider, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: provider.isBlocked
            ? Border.all(color: AppColors.error.withOpacity(0.4), width: 1.2)
            : Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: provider.isGovtProvider
              ? AppColors.governmentColor.withOpacity(0.12)
              : AppColors.primary.withOpacity(0.12),
          backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
          child: provider.avatarUrl == null
              ? Icon(
                  provider.isGovtProvider
                      ? Icons.account_balance_outlined
                      : Icons.business_outlined,
                  color: provider.isGovtProvider ? AppColors.governmentColor : AppColors.primary,
                  size: 26,
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                provider.username,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (provider.isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('محجوب',
                    style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('نشط',
                    style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(provider.email,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              provider.isGovtProvider ? '🏛️ جهة حكومية' : '🏢 منشأة خاصة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: provider.isGovtProvider ? AppColors.governmentColor : AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, ref, action, provider),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    provider.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                    color: provider.isBlocked ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.isBlocked ? AppStrings.unblockProvider : AppStrings.blockProvider,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error),
                  SizedBox(width: 8),
                  Text(AppStrings.deleteProvider,
                      style: TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 30).clamp(0, 300))).fadeIn().slideX(begin: 0.05);
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action, UserModel provider) async {
    final repo = AdminRepository(ref.read(supabaseClientProvider));

    if (action == 'edit') {
      _showEditProviderDialog(context, ref, provider);
    } else if (action == 'block') {
      await repo.toggleBlockProvider(provider.id, !provider.isBlocked);
      ref.invalidate(allProvidersProvider);
      if (context.mounted) {
        AppHelpers.showSuccess(
          context,
          provider.isBlocked ? 'تم رفع الحجب عن المزود' : 'تم حجب المزود',
        );
      }
    } else if (action == 'delete') {
      final confirm = await AppHelpers.showDeleteDialog(context, provider.username);
      if (confirm != true) return;
      await repo.deleteProvider(provider.id);
      ref.invalidate(allProvidersProvider);
      if (context.mounted) AppHelpers.showSuccess(context, 'تم حذف المزود بنجاح');
    }
  }

  void _showEditProviderDialog(BuildContext context, WidgetRef ref, UserModel provider) {
    final usernameCtrl = TextEditingController(text: provider.username);
    final emailCtrl = TextEditingController(text: provider.email);
    final passwordCtrl = TextEditingController();
    UserRole selectedRole = provider.role;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل بيانات المزود الكاملة',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المزود / المنشأة *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'نوع المزود *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.providerGovt,
                        child: Text('🏛️ حكومي', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(
                        value: UserRole.providerPrivate,
                        child: Text('🏢 خاص', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'تعيين كلمة مرور جديدة (اختياري)',
                    hintText: 'اتركها فارغة للإبقاء على الحالية',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                  AppHelpers.showError(context, 'يرجى إدخال اسم المزود والبريد الإلكتروني');
                  return;
                }
                Navigator.pop(ctx);

                final repo = AdminRepository(ref.read(supabaseClientProvider));
                try {
                  await repo.updateProvider(
                    userId: provider.id,
                    username: usernameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: selectedRole,
                    newPassword: passwordCtrl.text.trim().isNotEmpty
                        ? passwordCtrl.text.trim()
                        : null,
                  );
                  ref.invalidate(allProvidersProvider);
                  if (context.mounted) {
                    AppHelpers.showSuccess(context, 'تم تحديث كافة بيانات المزود بنجاح');
                  }
                } catch (e) {
                  if (context.mounted) AppHelpers.showError(context, e.toString());
                }
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProviderDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    UserRole selectedRole = UserRole.providerGovt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(AppStrings.addProvider,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المزود / المنشأة'),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'كلمة المرور (اختياري: الافتراضي Mush@2024)'),
                  obscureText: true,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'نوع المزود'),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.providerGovt,
                        child: Text('🏛️ حكومي', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(
                        value: UserRole.providerPrivate,
                        child: Text('🏢 خاص', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty || usernameCtrl.text.isEmpty) return;
                Navigator.pop(ctx);

                final repo = AdminRepository(ref.read(supabaseClientProvider));
                try {
                  await repo.addProvider(
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text.isEmpty ? 'Mush@2024' : passwordCtrl.text,
                    username: usernameCtrl.text.trim(),
                    role: selectedRole,
                  );
                  ref.invalidate(allProvidersProvider);
                  if (context.mounted) {
                    AppHelpers.showSuccess(context, 'تم إضافة المزود بنجاح');
                  }
                } catch (e) {
                  if (context.mounted) AppHelpers.showError(context, e.toString());
                }
              },
              child: const Text(AppStrings.add),
            ),
          ],
        ),
      ),
    );
  }
}
