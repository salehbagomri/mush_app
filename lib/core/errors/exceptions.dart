/// أخطاء التطبيق المخصصة
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class AppAuthException extends AppException {
  const AppAuthException([super.message = 'خطأ في المصادقة']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'خطأ في الخادم']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'البيانات غير موجودة']);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'ليس لديك صلاحية']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'بيانات غير صالحة']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'خطأ في رفع الملف']);
}
