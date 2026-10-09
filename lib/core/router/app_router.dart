import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mush_app/data/models/user_model.dart';
import 'package:mush_app/data/models/service_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/services/services_list_screen.dart';
import '../../presentation/screens/services/service_details_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/update_profile_screen.dart';
import '../../presentation/screens/categories/categories_screen.dart';
import '../../presentation/screens/about/about_us_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_services_screen.dart';
import '../../presentation/screens/admin/providers_management_screen.dart';
import '../../presentation/screens/admin/categories_management_screen.dart';
import '../../presentation/screens/admin/advertisements_screen.dart';
import '../../presentation/screens/provider/provider_dashboard_screen.dart';
import '../../presentation/screens/provider/add_service_screen.dart';
import '../../presentation/screens/provider/manage_services_screen.dart';

// Route Names
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String categories = '/categories';
  static const String services = '/services';
  static const String serviceDetails = '/services/:id';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String about = '/about';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminServices = '/admin/services';
  static const String providersManagement = '/admin/providers';
  static const String categoriesManagement = '/admin/categories';
  static const String advertisementsManagement = '/admin/advertisements';

  // Provider
  static const String providerDashboard = '/provider';
  static const String addService = '/provider/services/add';
  static const String manageServices = '/provider/services';
  static const String editService = '/provider/services/:id/edit';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    // أثناء التحميل لا نقوم بأي توجيه حتى ننتظر نتيجة المصادقة
    if (authState.isLoading) return null;

    final user = authState.value;
    final isLoggedIn = user != null;
    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.onboarding;

    // حماية المسارات المقيّدة
    if (!isLoggedIn && !isAuthRoute) {
      final protectedRoutes = [
        AppRoutes.profile,
        AppRoutes.updateProfile,
        AppRoutes.adminDashboard,
        AppRoutes.providersManagement,
        AppRoutes.categoriesManagement,
        AppRoutes.advertisementsManagement,
        AppRoutes.providerDashboard,
        AppRoutes.addService,
        AppRoutes.manageServices,
      ];

      if (protectedRoutes.any((r) => state.matchedLocation.startsWith(r))) {
        return AppRoutes.login;
      }
    }

    // إذا سجل المستخدم دخوله وهو في صفحة الدخول، يتم توجيهه حسب دوره
    if (isLoggedIn && isAuthRoute) {
      if (user.isAdmin) return AppRoutes.adminDashboard;
      if (user.isProvider) return AppRoutes.providerDashboard;
      return AppRoutes.home;
    }

    // توجيه المدير إلى لوحة الأدمن إذا كان في الرئيسية
    if (isLoggedIn && user.isAdmin && state.matchedLocation == AppRoutes.home) {
      return AppRoutes.adminDashboard;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final isOnboardingDoneProvider = Provider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final isOnboardingDone = ref.watch(isOnboardingDoneProvider);

  return GoRouter(
    initialLocation: isOnboardingDone ? AppRoutes.home : AppRoutes.onboarding,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.services,
        name: 'services',
        builder: (_, state) {
          final categoryId = state.uri.queryParameters['category'];
          final categoryName = state.uri.queryParameters['name'];
          return ServicesListScreen(
              categoryId: categoryId, categoryName: categoryName);
        },
      ),
      GoRoute(
        path: AppRoutes.serviceDetails,
        name: 'serviceDetails',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ServiceDetailsScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.updateProfile,
        name: 'updateProfile',
        builder: (_, __) => const UpdateProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (_, __) => const AboutUsScreen(),
      ),
      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminServices,
        name: 'adminServices',
        builder: (_, __) => const AdminServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.providersManagement,
        name: 'providersManagement',
        builder: (_, __) => const ProvidersManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.categoriesManagement,
        name: 'categoriesManagement',
        builder: (_, __) => const CategoriesManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.advertisementsManagement,
        name: 'advertisementsManagement',
        builder: (_, __) => const AdvertisementsScreen(),
      ),
      // Provider Routes
      GoRoute(
        path: AppRoutes.providerDashboard,
        name: 'providerDashboard',
        builder: (_, __) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.addService,
        name: 'addService',
        builder: (_, state) => AddServiceScreen(
          serviceToEdit: state.extra as ServiceModel?,
        ),
      ),
      GoRoute(
        path: AppRoutes.editService,
        name: 'editService',
        builder: (_, state) => AddServiceScreen(
          serviceToEdit: state.extra as ServiceModel?,
        ),
      ),
      GoRoute(
        path: AppRoutes.manageServices,
        name: 'manageServices',
        builder: (_, __) => const ManageServicesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
