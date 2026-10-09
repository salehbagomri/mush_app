import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../providers/services_provider.dart';
import '../../../core/widgets/shared_widgets.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<IconData> _categoryIcons = [
    Icons.account_balance_outlined,
    Icons.local_hospital_outlined,
    Icons.school_outlined,
    Icons.directions_bus_outlined,
    Icons.business_outlined,
    Icons.shield_outlined,
    Icons.bolt_outlined,
    Icons.water_drop_outlined,
    Icons.wifi_outlined,
    Icons.shopping_bag_outlined,
    Icons.sports_soccer_outlined,
    Icons.handshake_outlined,
  ];

  static const List<Color> _categoryColors = [
    Color(0xFF00897B),
    Color(0xFF0288D1),
    Color(0xFF7B1FA2),
    Color(0xFFE64A19),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF5D4037),
    Color(0xFF0097A7),
    Color(0xFFC2185B),
    Color(0xFF455A64),
  ];

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
        title: const Text(AppStrings.categories),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allCategoriesProvider);
        },
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن تصنيف...',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),

            // Categories Grid
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerGrid(count: 12),
                ),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(allCategoriesProvider),
                ),
                data: (categories) {
                  final filtered = categories.where((cat) {
                    return _searchQuery.isEmpty ||
                        cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.category_outlined,
                      title: 'لا توجد تصنيفات',
                      subtitle: 'لم يتم العثور على تصنيفات تطابق بحثك',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.88,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final cat = filtered[i];
                      final color = _categoryColors[i % _categoryColors.length];
                      final icon = _categoryIcons[i % _categoryIcons.length];

                      return GestureDetector(
                        onTap: () => context.push(
                          '${AppRoutes.services}?category=${cat.id}&name=${Uri.encodeComponent(cat.name)}',
                        ),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(delay: Duration(milliseconds: (i % 9) * 35))
                            .fadeIn(duration: 250.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
