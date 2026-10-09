import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/category_model.dart';
import 'package:mush_app/data/repositories/admin_repository.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends ConsumerState<CategoriesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.categoriesManagement),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تصنيف', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: categoriesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(count: 8),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(allCategoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد تصنيفات',
              subtitle: 'أضف تصنيفاً جديداً لتصنيف الخدمات ضمنه',
              icon: Icons.category_outlined,
            );
          }

          final filteredCategories = categories.where((c) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final nameMatches = c.name.toLowerCase().contains(query);
            final sectionMatches = c.mainSection?.name.toLowerCase().contains(query) ?? false;
            return nameMatches || sectionMatches;
          }).toList();

          return Column(
            children: [
              // Search Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث في التصنيفات أو الأقسام...',
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
              ),

              // Categories List
              Expanded(
                child: filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد تصنيفات مطابقة للبحث',
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(allCategoriesProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: filteredCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final cat = filteredCategories[i];
                            return _buildCategoryCard(context, ref, cat, i);
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

  Widget _buildCategoryCard(
      BuildContext context, WidgetRef ref, CategoryModel cat, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: cat.iconUrl != null && cat.iconUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    cat.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.category_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                )
              : const Icon(Icons.category_outlined, color: AppColors.primary, size: 24),
        ),
        title: Text(
          cat.name,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: cat.mainSection != null
            ? Text(
                'القسم: ${cat.mainSection!.name}',
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              tooltip: 'تعديل التصنيف',
              onPressed: () => _showEditCategoryDialog(context, ref, cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              tooltip: 'حذف التصنيف',
              onPressed: () => _deleteCategory(context, ref, cat.id, cat.name),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 25).clamp(0, 300))).fadeIn().slideY(begin: 0.05);
  }

  Future<void> _deleteCategory(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirm = await AppHelpers.showDeleteDialog(context, name);
    if (confirm != true) return;

    final repo = AdminRepository(ref.read(supabaseClientProvider));
    try {
      await repo.deleteCategory(id);
      ref.invalidate(allCategoriesProvider);
      ref.invalidate(categoriesProvider(null));
      if (context.mounted) AppHelpers.showSuccess(context, 'تم حذف التصنيف بنجاح');
    } catch (e) {
      if (context.mounted) AppHelpers.showError(context, e.toString());
    }
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final sections = await ref.read(mainSectionsProvider(null).future);

    if (!context.mounted) return;
    if (sections.isEmpty) {
      AppHelpers.showError(context, 'لا توجد أقسام رئيسية مضافة في النظام');
      return;
    }

    String selectedSectionId = sections.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة تصنيف جديد',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم التصنيف *'),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedSectionId,
                decoration: const InputDecoration(labelText: 'القسم الرئيسي *'),
                items: sections
                    .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: const TextStyle(fontFamily: 'Cairo'))))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedSectionId = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final repo = AdminRepository(ref.read(supabaseClientProvider));
                try {
                  await repo.addCategory(
                    name: nameCtrl.text.trim(),
                    mainSectionId: selectedSectionId,
                  );
                  ref.invalidate(allCategoriesProvider);
                  ref.invalidate(categoriesProvider(null));
                  if (context.mounted) {
                    AppHelpers.showSuccess(context, 'تم إضافة التصنيف بنجاح');
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

  void _showEditCategoryDialog(
      BuildContext context, WidgetRef ref, CategoryModel category) async {
    final nameCtrl = TextEditingController(text: category.name);
    final sections = await ref.read(mainSectionsProvider(null).future);

    if (!context.mounted) return;
    if (sections.isEmpty) {
      AppHelpers.showError(context, 'لا توجد أقسام رئيسية');
      return;
    }

    String selectedSectionId = category.mainSectionId;
    if (!sections.any((s) => s.id == selectedSectionId)) {
      selectedSectionId = sections.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل التصنيف',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم التصنيف *'),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedSectionId,
                decoration: const InputDecoration(labelText: 'القسم الرئيسي *'),
                items: sections
                    .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: const TextStyle(fontFamily: 'Cairo'))))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedSectionId = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final repo = AdminRepository(ref.read(supabaseClientProvider));
                try {
                  await repo.updateCategory(
                    id: category.id,
                    name: nameCtrl.text.trim(),
                    mainSectionId: selectedSectionId,
                  );
                  ref.invalidate(allCategoriesProvider);
                  ref.invalidate(categoriesProvider(null));
                  if (context.mounted) {
                    AppHelpers.showSuccess(context, 'تم تحديث التصنيف بنجاح');
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
}
