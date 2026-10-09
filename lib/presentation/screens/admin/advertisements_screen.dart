import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/requirement_model.dart';
import 'package:mush_app/data/repositories/admin_repository.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class AdvertisementsScreen extends ConsumerWidget {
  const AdvertisementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(advertisementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.advertisementsManagement)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadAdvertisement(context, ref),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('إضافة إعلان', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: adsAsync.when(
        loading: () => const ShimmerList(count: 4, itemHeight: 160),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (ads) {
          if (ads.isEmpty) {
            return const EmptyStateWidget(
              title: 'لا توجد إعلانات',
              subtitle: 'أضف إعلاناً جديداً',
              icon: Icons.campaign_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final ad = ads[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AppNetworkImage(
                        imageUrl: ad.imageUrl,
                        height: 150,
                        width: double.infinity,
                        fallbackIcon: Icons.campaign_outlined,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ad.isActive
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ad.isActive ? 'نشط' : 'متوقف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: ad.isActive ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                            tooltip: 'تعديل الإعلان وتغيير الصورة',
                            onPressed: () => _showEditAdDialog(context, ref, ad),
                          ),
                          IconButton(
                            icon: Icon(
                              ad.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                              color: AppColors.warning,
                            ),
                            tooltip: ad.isActive ? 'إيقاف مؤقت' : 'تفعيل',
                            onPressed: () => _toggleAd(context, ref, ad.id, ad.isActive),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            tooltip: 'حذف',
                            onPressed: () => _deleteAd(context, ref, ad.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _uploadAdvertisement(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    final imageFile = File(file.path);
    final supabase = ref.read(supabaseClientProvider);
    final repo = AdminRepository(supabase);

    try {
      final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('advertisements').upload(fileName, imageFile,
          fileOptions: const FileOptions(upsert: false));
      final url = supabase.storage.from('advertisements').getPublicUrl(fileName);

      await repo.addAdvertisement(imageUrl: url);
      ref.invalidate(advertisementsProvider);

      if (context.mounted) AppHelpers.showSuccess(context, 'تم رفع الإعلان بنجاح');
    } catch (e) {
      if (context.mounted) AppHelpers.showError(context, e.toString());
    }
  }

  void _showEditAdDialog(
      BuildContext context, WidgetRef ref, AdvertisementModel ad) {
    File? newSelectedImage;
    final linkController = TextEditingController(text: ad.linkUrl ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'تعديل الإعلان',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: newSelectedImage != null
                            ? Image.file(
                                newSelectedImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : AppNetworkImage(
                                imageUrl: ad.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fallbackIcon: Icons.campaign_outlined,
                              ),
                      ),
                      if (newSelectedImage != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'صورة جديدة محددة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (file != null) {
                              setDialogState(() {
                                newSelectedImage = File(file.path);
                              });
                            }
                          },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      newSelectedImage == null
                          ? 'اختيار صورة جديدة من المعرض'
                          : 'تغيير الصورة المحددة',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: linkController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'رابط الإعلان (اختياري)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final newLink = linkController.text.trim();
                      if (newSelectedImage == null &&
                          newLink == (ad.linkUrl ?? '')) {
                        Navigator.pop(ctx);
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        final supabase = ref.read(supabaseClientProvider);
                        final repo = AdminRepository(supabase);
                        String? newImageUrl;

                        if (newSelectedImage != null) {
                          final fileName =
                              'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          await supabase.storage
                              .from('advertisements')
                              .upload(fileName, newSelectedImage!,
                                  fileOptions:
                                      const FileOptions(upsert: false));
                          newImageUrl = supabase.storage
                              .from('advertisements')
                              .getPublicUrl(fileName);
                        }

                        await repo.updateAdvertisement(
                          id: ad.id,
                          imageUrl: newImageUrl,
                          linkUrl: newLink.isEmpty ? null : newLink,
                        );

                        ref.invalidate(advertisementsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          AppHelpers.showSuccess(
                              context, 'تم تحديث الإعلان وتغيير الصورة بنجاح');
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          AppHelpers.showError(
                              context, 'فشل تحديث الإعلان: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'حفظ التعديلات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAd(
      BuildContext context, WidgetRef ref, String id, bool isActive) async {
    final repo = AdminRepository(ref.read(supabaseClientProvider));
    await repo.toggleAdvertisement(id, !isActive);
    ref.invalidate(advertisementsProvider);
  }

  Future<void> _deleteAd(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await AppHelpers.showDeleteDialog(context, 'هذا الإعلان');
    if (confirm != true) return;

    final repo = AdminRepository(ref.read(supabaseClientProvider));
    await repo.deleteAdvertisement(id);
    ref.invalidate(advertisementsProvider);
    if (context.mounted) AppHelpers.showSuccess(context, 'تم حذف الإعلان');
  }
}
