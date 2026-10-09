import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/category_model.dart';
import 'package:mush_app/data/models/requirement_model.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentAdIndex = 0;
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final adsAsync = ref.watch(advertisementsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null ? 'مرحباً، ${user.username}' : 'مرحباً بك',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          AppStrings.appFullName,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.about),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.search),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textHint),
                      const SizedBox(width: 12),
                      const Text(AppStrings.searchHint,
                          style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(advertisementsProvider);
            ref.invalidate(allCategoriesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Advertisements Banner
                adsAsync.when(
                  loading: () => const ShimmerCard(height: 180),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (ads) => ads.isEmpty
                      ? const SizedBox.shrink()
                      : _buildAdsCarousel(ads),
                ),

                const SizedBox(height: 24),

                // Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.categories,
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.categories),
                        child: const Text('عرض الكل'),
                      ),
                    ],
                  ),
                ),

                categoriesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerGrid(count: 9),
                  ),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (categories) => _buildCategoriesGrid(categories),
                ),

                const SizedBox(height: 24),

                // Latest Services
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(AppStrings.featuredServices,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 12),

                _buildLatestServices(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, user),
    );
  }

  Widget _buildAdsCarousel(List<AdvertisementModel> ads) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: ads.length,
          options: CarouselOptions(
            height: 180,
            viewportFraction: 0.9,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            onPageChanged: (index, _) => setState(() => _currentAdIndex = index),
          ),
          itemBuilder: (_, index, __) {
            final ad = ads[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppNetworkImage(
                imageUrl: ad.imageUrl,
                width: double.infinity,
                height: 180,
                fallbackIcon: Icons.campaign_outlined,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            ads.length,
            (i) => AnimatedContainer(
              duration: 300.ms,
              width: _currentAdIndex == i ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentAdIndex == i ? AppColors.primary : AppColors.divider,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(List<CategoryModel> categories) {
    final colors = [
      AppColors.healthColor,
      AppColors.educationColor,
      AppColors.safetyColor,
      AppColors.governmentColor,
      AppColors.tourismColor,
      AppColors.hospitalityColor,
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
    ];

    final icons = [
      Icons.local_hospital_outlined,
      Icons.school_outlined,
      Icons.local_police_outlined,
      Icons.account_balance_outlined,
      Icons.landscape_outlined,
      Icons.hotel_outlined,
      Icons.business_outlined,
      Icons.restaurant_outlined,
      Icons.directions_bus_outlined,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final color = colors[i % colors.length];
        final icon = icons[i % icons.length];

        return GestureDetector(
          onTap: () => context.push(
            '${AppRoutes.services}?category=${cat.id}&name=${cat.name}',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: i * 50))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        );
      },
    );
  }

  Widget _buildLatestServices() {
    final servicesAsync = ref.watch(servicesProvider);

    return servicesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerList(count: 3, itemHeight: 90),
      ),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (services) {
        if (services.isEmpty) {
          return const EmptyStateWidget(
            title: AppStrings.noServices,
            icon: Icons.inbox_outlined,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: services.length > 5 ? 5 : services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildServiceCard(services[i]),
        );
      },
    );
  }

  Widget _buildServiceCard(service) {
    return GestureDetector(
      onTap: () => context.push('/services/${service.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppNetworkImage(
                imageUrl: service.imageUrl,
                width: 60,
                height: 60,
                fallbackIcon: Icons.business_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  if (service.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(service.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                  if (service.workTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(service.workTime!,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav(BuildContext context, user) {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (i) async {
        if (i == 0) return;
        setState(() => _selectedNavIndex = i);
        switch (i) {
          case 1:
            await context.push(AppRoutes.categories);
            break;
          case 2:
            await context.push(AppRoutes.services);
            break;
          case 3:
            if (user != null) {
              await context.push(AppRoutes.profile);
            } else {
              await context.push(AppRoutes.login);
            }
            break;
        }
        if (mounted) {
          setState(() => _selectedNavIndex = 0);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: AppStrings.home),
        BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: AppStrings.categories),
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined), label: AppStrings.allServices),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: AppStrings.profile),
      ],
    );
  }
}
