import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/errors/exceptions.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// تسجيل الدخول
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AppAuthException('فشل تسجيل الدخول');
      }

      return await _getUserProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AppAuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AppAuthException('خطأ غير متوقع: ${e.toString()}');
    }
  }

  /// إنشاء حساب جديد
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user == null) {
        throw const AppAuthException('فشل إنشاء الحساب');
      }

      // محاولة إنشاء الملف الشخصي (قد يتم إنشاؤه تلقائياً بواسطة Database Trigger)
      try {
        await _supabase.from('user_profiles').upsert({
          'id': response.user!.id,
          'username': username,
          'email': email,
          'role': 'user',
        });
      } catch (_) {
        // إذا فشل الإدخال من العميل يتولى الـ Trigger إنشاؤه بأمان
      }

      return UserModel(
        id: response.user!.id,
        username: username,
        email: email,
        role: UserRole.user,
      );
    } on AuthException catch (e) {
      throw AppAuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AppAuthException('خطأ في إنشاء الحساب: ${e.toString()}');
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw const AppAuthException('خطأ في تسجيل الخروج');
    }
  }

  /// الحصول على المستخدم الحالي
  Future<UserModel?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    try {
      return await _getUserProfile(authUser.id);
    } catch (_) {
      return null;
    }
  }

  /// الاستماع لتغييرات الجلسة
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// تحديث الملف الشخصي
  Future<UserModel> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase.from('user_profiles').update(updates).eq('id', userId);

      return await _getUserProfile(userId);
    } catch (e) {
      throw ServerException('فشل تحديث الملف الشخصي');
    }
  }

  // ======== Private ========

  Future<UserModel> _getUserProfile(String userId) async {
    final data = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw const NotFoundException('الملف الشخصي غير موجود');
    }

    return UserModel.fromMap(data);
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (message.contains('User already registered')) {
      return 'هذا البريد الإلكتروني مسجل مسبقاً';
    } else if (message.contains('Password should be at least')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    } else if (message.contains('Unable to validate email address')) {
      return 'البريد الإلكتروني غير صالح';
    }
    return message;
  }
}
