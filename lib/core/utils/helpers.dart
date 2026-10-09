import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class AppHelpers {
  AppHelpers._();

  /// تنسيق رقم واتساب مع رمز الدولة (967 لليمن) بذكاء
  static String formatWhatsAppNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    // إزالة الصفرين الدوليين في البداية إن وُجدا (00967...)
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }
    // إزالة الصفر المحلي في البداية (مثل 0771234567)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    // إذا لم يكن يبدأ بـ 967، نضيف 967
    if (!cleaned.startsWith('967')) {
      cleaned = '967$cleaned';
    }
    return cleaned;
  }

  /// فتح رقم الهاتف
  static Future<void> callPhone(String phone, {BuildContext? context}) async {
    try {
      final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri(scheme: 'tel', path: cleaned);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context != null && context.mounted) {
        showError(context, 'تعذر فتح لوحة الاتصال');
      }
    } catch (_) {
      if (context != null && context.mounted) {
        showError(context, 'تعذر إجراء الاتصال بالرقم $phone');
      }
    }
  }

  /// فتح واتساب
  static Future<void> openWhatsApp(String phone, {BuildContext? context}) async {
    final formattedNumber = formatWhatsAppNumber(phone);
    final whatsappSchemeUri = Uri.parse('whatsapp://send?phone=$formattedNumber');
    final webUri = Uri.parse('https://wa.me/$formattedNumber');

    // 1. محاولة فتح تطبيق واتساب مباشرة
    try {
      final launchedScheme = await launchUrl(whatsappSchemeUri, mode: LaunchMode.externalApplication);
      if (launchedScheme) return;
    } catch (_) {}

    // 2. محاولة فتح رابط wa.me في تطبيق خارجي
    try {
      final launchedWeb = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launchedWeb) return;
    } catch (_) {}

    // 3. محاولة فتح رابط wa.me في المتصفح الداخلي/الافتراضي
    try {
      final launchedDefault = await launchUrl(webUri, mode: LaunchMode.platformDefault);
      if (launchedDefault) return;
    } catch (_) {}

    if (context != null && context.mounted) {
      showError(context, 'تعذر فتح واتساب، يرجى التأكد من تثبيت التطبيق على جهازك');
    }
  }

  /// فتح موقع إلكتروني
  static Future<void> openWebsite(String url, {BuildContext? context}) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    final fullUrl = (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'))
        ? cleanUrl
        : 'https://$cleanUrl';

    try {
      final uri = Uri.parse(fullUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final launchedFallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!launchedFallback && context != null && context.mounted) {
          showError(context, 'تعذر فتح الموقع الإلكتروني');
        }
      }
    } catch (_) {
      if (context != null && context.mounted) {
        showError(context, 'رابط الموقع الإلكتروني غير صالح');
      }
    }
  }

  /// نسخ للحافظة
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 2)),
      );
    }
  }

  /// عرض Snackbar نجاح
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض Snackbar خطأ
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// حوار تأكيد الحذف
  static Future<bool?> showDeleteDialog(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "$itemName"؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// تنسيق رقم الهاتف
  static String formatPhone(String phone) {
    if (phone.isEmpty) return '';
    if (phone.startsWith('967')) return '+$phone';
    if (phone.startsWith('0')) return '+967${phone.substring(1)}';
    return phone;
  }

  /// اختصار النص الطويل
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
