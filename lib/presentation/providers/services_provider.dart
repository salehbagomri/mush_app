import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/requirement_model.dart';
import '../../data/repositories/services_repository.dart';
import 'auth_provider.dart';

// ====== Repository Provider ======

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ref.watch(supabaseClientProvider));
});

// ====== Places & Sections ======

final placesProvider = FutureProvider<List<PlaceModel>>((ref) {
  return ref.watch(servicesRepositoryProvider).getPlaces();
});

final mainSectionsProvider =
    FutureProvider.family<List<MainSectionModel>, String?>((ref, placeId) {
  return ref.watch(servicesRepositoryProvider).getMainSections(placeId: placeId);
});

// ====== Categories ======

final categoriesProvider =
    FutureProvider.family<List<CategoryModel>, String?>((ref, mainSectionId) {
  return ref.watch(servicesRepositoryProvider).getCategories(mainSectionId: mainSectionId);
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(servicesRepositoryProvider).getCategories();
});

// ====== Advertisements ======

final advertisementsProvider = FutureProvider<List<AdvertisementModel>>((ref) {
  return ref.watch(servicesRepositoryProvider).getActiveAdvertisements();
});

// ====== Services Filter State ======

class ServicesFilter {
  final String? categoryId;
  final String? searchQuery;
  final int page;

  const ServicesFilter({this.categoryId, this.searchQuery, this.page = 0});

  ServicesFilter copyWith({String? categoryId, String? searchQuery, int? page}) {
    return ServicesFilter(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }
}

final servicesFilterProvider = StateProvider<ServicesFilter>((ref) {
  return const ServicesFilter();
});

// ====== Services List ======

final servicesProvider = FutureProvider.autoDispose<List<ServiceModel>>((ref) {
  final filter = ref.watch(servicesFilterProvider);
  return ref.watch(servicesRepositoryProvider).getServices(
        categoryId: filter.categoryId,
        searchQuery: filter.searchQuery,
        page: filter.page,
      );
});

// ====== Single Service ======

final serviceDetailProvider =
    FutureProvider.autoDispose.family<ServiceModel, String>((ref, id) {
  return ref.watch(servicesRepositoryProvider).getServiceById(id);
});

// ====== Search ======

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<ServiceModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return Future.value([]);
  return ref.watch(servicesRepositoryProvider).searchServices(query);
});

// ====== Provider's Services ======

final providerServicesProvider =
    FutureProvider.autoDispose.family<List<ServiceModel>, String>((ref, providerId) {
  return ref.watch(servicesRepositoryProvider).getProviderServices(providerId);
});

// ====== Service CRUD Notifier ======

class ServiceCrudNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addService(ServiceModel service, {String? documents, String? fees}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(servicesRepositoryProvider).addService(service, documents: documents, fees: fees));
    ref.invalidate(servicesProvider);
    if (service.providerId != null) {
      ref.invalidate(providerServicesProvider(service.providerId!));
    }
  }

  Future<void> updateService(
    String id,
    Map<String, dynamic> updates, {
    String? providerId,
    String? documents,
    String? fees,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(servicesRepositoryProvider).updateService(id, updates, documents: documents, fees: fees));
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceDetailProvider(id));
    if (providerId != null) {
      ref.invalidate(providerServicesProvider(providerId));
    }
  }

  Future<void> deleteService(String id, {String? providerId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(servicesRepositoryProvider).deleteService(id));
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceDetailProvider(id));
    if (providerId != null) {
      ref.invalidate(providerServicesProvider(providerId));
    }
  }

  Future<void> toggleSuspension(String id, bool suspend, {String? providerId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(servicesRepositoryProvider).toggleServiceSuspension(id, suspend));
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceDetailProvider(id));
    if (providerId != null) {
      ref.invalidate(providerServicesProvider(providerId));
    }
  }
}

final serviceCrudProvider = AsyncNotifierProvider<ServiceCrudNotifier, void>(() {
  return ServiceCrudNotifier();
});
