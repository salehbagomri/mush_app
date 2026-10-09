import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/requirement_model.dart';
import '../../core/errors/exceptions.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // ====== إدارة المزودين ======

  Future<List<UserModel>> getAllProviders() async {
    try {
      final data = await _supabase
          .from('user_profiles')
          .select()
          .or('role.eq.provider_govt,role.eq.provider_private')
          .order('created_at', ascending: false);

      return (data as List).map((e) => UserModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل قائمة المزودين');
    }
  }

  Future<UserModel> addProvider({
    required String email,
    required String password,
    required String username,
    required UserRole role,
    String? categoryId,
  }) async {
    try {
      final res = await _supabase.rpc('admin_create_provider', params: {
        'new_email': email,
        'new_password': password,
        'new_username': username,
        'new_role': role.name,
        'new_category_id': categoryId,
      });

      final userId = res.toString();

      return UserModel(
        id: userId,
        username: username,
        email: email,
        role: role,
        categoryId: categoryId,
      );
    } catch (e) {
      throw ServerException('فشل إضافة المزود: ${e.toString()}');
    }
  }

  Future<void> updateProvider({
    required String userId,
    required String username,
    required String email,
    required UserRole role,
    String? newPassword,
    String? categoryId,
  }) async {
    try {
      // Try updating via admin_update_provider RPC if exists
      try {
        await _supabase.rpc('admin_update_provider', params: {
          'target_user_id': userId,
          'new_username': username,
          'new_email': email,
          'new_role': role.name,
          'new_password': (newPassword != null && newPassword.isNotEmpty) ? newPassword : null,
        });
        return;
      } catch (_) {
        // Fallback: update user_profiles table directly
      }

      final updates = <String, dynamic>{
        'username': username,
        'email': email,
        'role': role.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (categoryId != null) updates['category_id'] = categoryId;

      await _supabase.from('user_profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw ServerException('فشل تحديث بيانات المزود: ${e.toString()}');
    }
  }

  Future<void> toggleBlockProvider(String userId, bool block) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'is_blocked': block}).eq('id', userId);
    } catch (e) {
      throw ServerException(block ? 'فشل حجب المزود' : 'فشل رفع الحجب عن المزود');
    }
  }

  Future<void> deleteProvider(String userId) async {
    try {
      await _supabase.rpc('delete_user_by_admin', params: {
        'target_user_id': userId,
      });
      await _supabase.from('user_profiles').delete().eq('id', userId);
    } catch (e) {
      throw ServerException('فشل حذف المزود: ${e.toString()}');
    }
  }

  // ====== إدارة التصنيفات ======

  Future<CategoryModel> addCategory({
    required String name,
    required String mainSectionId,
    String? iconUrl,
  }) async {
    try {
      final data = await _supabase.from('categories').insert({
        'name': name,
        'main_section_id': mainSectionId,
        'icon_url': iconUrl,
      }).select('*, main_sections(id, name, place_id, places(id, name))').single();

      return CategoryModel.fromMap(data);
    } catch (e) {
      throw ServerException('فشل إضافة التصنيف');
    }
  }

  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String mainSectionId,
    String? iconUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
        'main_section_id': mainSectionId,
      };
      if (iconUrl != null) updates['icon_url'] = iconUrl;

      final data = await _supabase
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select('*, main_sections(id, name, place_id, places(id, name))')
          .single();

      return CategoryModel.fromMap(data);
    } catch (e) {
      throw ServerException('فشل تحديث التصنيف');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف التصنيف');
    }
  }

  // ====== إدارة كافة الخدمات (Admin Services) ======

  Future<List<ServiceModel>> getAllAdminServices() async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            categories(id, name, icon_url, main_section_id),
            requirements(*)
          ''')
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ServiceModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException('فشل تحميل قائمة كافة الخدمات');
    }
  }

  // ====== إدارة الإعلانات ======

  Future<AdvertisementModel> addAdvertisement({
    required String imageUrl,
    String? linkUrl,
  }) async {
    try {
      final data = await _supabase.from('advertisements').insert({
        'image_url': imageUrl,
        'link_url': linkUrl,
        'is_active': true,
      }).select().single();

      return AdvertisementModel.fromMap(data);
    } catch (e) {
      throw ServerException('فشل إضافة الإعلان');
    }
  }

  Future<void> updateAdvertisement({
    required String id,
    String? imageUrl,
    String? linkUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (linkUrl != null) updates['link_url'] = linkUrl;

      await _supabase.from('advertisements').update(updates).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تعديل الإعلان');
    }
  }

  Future<void> toggleAdvertisement(String id, bool active) async {
    try {
      await _supabase.from('advertisements').update({'is_active': active}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تغيير حالة الإعلان');
    }
  }

  Future<void> deleteAdvertisement(String id) async {
    try {
      await _supabase.from('advertisements').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الإعلان');
    }
  }

  // ====== إحصائيات ======

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final servicesCount = await _supabase
          .from('services')
          .select()
          .eq('is_deleted', false)
          .count();

      final providersCount = await _supabase
          .from('user_profiles')
          .select()
          .or('role.eq.provider_govt,role.eq.provider_private')
          .count();

      final usersCount = await _supabase
          .from('user_profiles')
          .select()
          .eq('role', 'user')
          .count();

      final categoriesCount = await _supabase.from('categories').select().count();

      return {
        'services': servicesCount.count,
        'providers': providersCount.count,
        'users': usersCount.count,
        'categories': categoriesCount.count,
      };
    } catch (e) {
      throw ServerException('فشل تحميل الإحصائيات');
    }
  }
}
