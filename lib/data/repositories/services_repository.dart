import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../models/category_model.dart';
import '../models/requirement_model.dart';
import '../../core/errors/exceptions.dart';

class ServicesRepository {
  final SupabaseClient _supabase;

  ServicesRepository(this._supabase);

  // ====== الخدمات ======

  /// جلب كل الخدمات النشطة مع pagination
  Future<List<ServiceModel>> getServices({
    String? categoryId,
    String? placeId,
    String? searchQuery,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var filterQuery = _supabase
          .from('services')
          .select('''
            *,
            categories(
              id, name, icon_url, main_section_id,
              main_sections(id, name, place_id, places(id, name))
            ),
            requirements(*)
          ''')
          .eq('is_deleted', false)
          .eq('is_suspended', false);

      if (categoryId != null) {
        filterQuery = filterQuery.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filterQuery = filterQuery.ilike('name', '%$searchQuery%');
      }

      final data = await filterQuery
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      return (data as List).map((e) => ServiceModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل الخدمات: ${e.toString()}');
    }
  }

  /// جلب خدمة واحدة بالتفاصيل الكاملة
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            categories(
              id, name, icon_url, main_section_id,
              main_sections(id, name, place_id, places(id, name))
            ),
            requirements(*)
          ''')
          .eq('id', id)
          .single();

      return ServiceModel.fromMap(data);
    } catch (e) {
      throw NotFoundException('الخدمة غير موجودة');
    }
  }

  /// البحث عن خدمات
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final clean = query.trim();
      if (clean.isEmpty) return [];

      final data = await _supabase
          .from('services')
          .select('''
            *,
            categories(id, name, icon_url, main_section_id)
          ''')
          .eq('is_deleted', false)
          .eq('is_suspended', false)
          .ilike('name', '%$clean%')
          .order('name')
          .limit(30);

      return (data as List).map((e) => ServiceModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل البحث: ${e.toString()}');
    }
  }

  /// جلب خدمات المزود
  Future<List<ServiceModel>> getProviderServices(String providerId) async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            categories(id, name, icon_url, main_section_id),
            requirements(*)
          ''')
          .eq('provider_id', providerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ServiceModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل خدماتك');
    }
  }

  /// إضافة خدمة جديدة
  Future<ServiceModel> addService(ServiceModel service, {String? documents, String? fees}) async {
    try {
      final data = await _supabase
          .from('services')
          .insert(service.toMap())
          .select()
          .single();

      final created = ServiceModel.fromMap(data);
      if ((documents != null && documents.isNotEmpty) || (fees != null && fees.isNotEmpty)) {
        try {
          await _supabase.from('requirements').insert({
            'service_id': created.id,
            'documents': documents,
            'fees': fees,
          });
        } catch (_) {}
      }

      return created;
    } catch (e) {
      throw ServerException('فشل إضافة الخدمة: ${e.toString()}');
    }
  }

  /// تعديل خدمة
  Future<ServiceModel> updateService(
    String id,
    Map<String, dynamic> updates, {
    String? documents,
    String? fees,
  }) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('services')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      if (documents != null || fees != null) {
        try {
          final existing = await _supabase
              .from('requirements')
              .select('id')
              .eq('service_id', id)
              .maybeSingle();

          if (existing != null) {
            await _supabase.from('requirements').update({
              'documents': documents,
              'fees': fees,
            }).eq('service_id', id);
          } else if ((documents != null && documents.isNotEmpty) ||
              (fees != null && fees.isNotEmpty)) {
            await _supabase.from('requirements').insert({
              'service_id': id,
              'documents': documents,
              'fees': fees,
            });
          }
        } catch (_) {}
      }

      return ServiceModel.fromMap(data);
    } catch (e) {
      throw ServerException('فشل تعديل الخدمة');
    }
  }

  /// حذف خدمة (Soft Delete)
  Future<void> deleteService(String id) async {
    try {
      await _supabase.from('services').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الخدمة');
    }
  }

  /// تعليق / تفعيل خدمة
  Future<void> toggleServiceSuspension(String id, bool suspend) async {
    try {
      await _supabase.from('services').update({
        'is_suspended': suspend,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تغيير حالة الخدمة');
    }
  }

  // ====== التصنيفات ======

  Future<List<CategoryModel>> getCategories({String? mainSectionId}) async {
    try {
      var filterQuery = _supabase
          .from('categories')
          .select('*, main_sections(id, name, place_id, places(id, name))');

      if (mainSectionId != null) {
        filterQuery = filterQuery.eq('main_section_id', mainSectionId);
      }

      final data = await filterQuery.order('name');
      return (data as List).map((e) => CategoryModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل التصنيفات');
    }
  }

  Future<List<PlaceModel>> getPlaces() async {
    try {
      final data = await _supabase.from('places').select().order('name');
      return (data as List).map((e) => PlaceModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل الأماكن');
    }
  }

  Future<List<MainSectionModel>> getMainSections({String? placeId}) async {
    try {
      var filterQuery = _supabase
          .from('main_sections')
          .select('*, places(id, name)');

      if (placeId != null) {
        filterQuery = filterQuery.eq('place_id', placeId);
      }

      final data = await filterQuery.order('name');
      return (data as List).map((e) => MainSectionModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل الأقسام');
    }
  }

  // ====== الإعلانات ======

  Future<List<AdvertisementModel>> getActiveAdvertisements() async {
    try {
      final data = await _supabase
          .from('advertisements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (data as List).map((e) => AdvertisementModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل الإعلانات');
    }
  }
}
