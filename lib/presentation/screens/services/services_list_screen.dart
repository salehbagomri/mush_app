import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const ServicesListScreen({super.key, this.categoryId, this.categoryName});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(servicesFilterProvider.notifier).state =
          ServicesFilter(categoryId: widget.categoryId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final current = ref.read(servicesFilterProvider);
    ref.read(servicesFilterProvider.notifier).state =
        current.copyWith(searchQuery: query.trim());
  }

  void _selectCategory(String? catId) {
    final current = ref.read(servicesFilterProvider);
    ref.read(servicesFilterProvider.notifier).state = ServicesFilter(
      categoryId: catId,
      searchQuery: current.searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final currentFilter = ref.watch(servicesFilterProvider);

    // Determine screen title
    String screenTitle = AppStrings.allServices;
    if (currentFilter.categoryId != null) {
      final cats = categoriesAsync.asData?.value;
      final matched = cats?.where((c) => c.id == currentFilter.categoryId).firstOrNull;
      if (matched != null) {
        screenTitle = matched.name;
      } else if (widget.categoryName != null) {
        screenTitle = widget.categoryName!;
      }
    }

    final hasActiveFilter = currentFilter.categoryId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'تصفية',
                onPressed: () => _showFilterSheet(categoriesAsync.asData?.value ?? []),
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن خدمة بالاسم أو الوصف...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                    fontFamily: 'Cairo',
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  _onSearchChanged(val);
                  setState(() {});
                },
              ),
            ),
          ),

          // 2. Horizontal Categories Filter Chips
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: const Text('الكل',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        selected: currentFilter.categoryId == null,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: currentFilter.categoryId == null
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => _selectCategory(null),
                      ),
                    ),
                    ...categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(cat.name,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          selected: currentFilter.categoryId == cat.id,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: currentFilter.categoryId == cat.id
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => _selectCategory(cat.id),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 6),

          // 3. Services List
          Expanded(
            child: servicesAsync.when(
              loading: () => const ShimmerList(count: 8, itemHeight: 100),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(servicesProvider),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.noServices,
                    subtitle: currentFilter.searchQuery?.isNotEmpty == true
                        ? 'لا توجد خدمات تطابق بحثك'
                        : 'لا توجد خدمات في هذا التصنيف حالياً',
                    icon: Icons.business_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(servicesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final service = services[i];
                      return GestureDetector(
                        onTap: () => context.push('/services/${service.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: AppNetworkImage(
                                  imageUrl: service.imageUrl,
                                  width: 100,
                                  height: 100,
                                  borderRadius: 0,
                                  fallbackIcon: Icons.business_outlined,
                                ),
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (service.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          service.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (service.hasPhone)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.phone,
                                                      size: 12, color: AppColors.success),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'اتصال',
                                                    style: TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontSize: 10,
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (service.hasWhatsapp) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF25D366)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'واتساب',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 10,
                                                  color: Color(0xFF25D366),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.chevron_left,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(List<dynamic> categories) {
    final currentCatId = ref.read(servicesFilterProvider).categoryId;
    String? tempSelected = currentCatId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تصفية الخدمات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() => tempSelected = null);
                      _selectCategory(null);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'إعادة تعيين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              const Text(
                'اختر التصنيف:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('جميع التصنيفات',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        selected: tempSelected == null,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: tempSelected == null
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setSheetState(() => tempSelected = null),
                      ),
                      ...categories.map(
                        (cat) => ChoiceChip(
                          label: Text(cat.name,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          selected: tempSelected == cat.id,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: tempSelected == cat.id
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setSheetState(() => tempSelected = cat.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _selectCategory(tempSelected);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'تطبيق التصفية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
