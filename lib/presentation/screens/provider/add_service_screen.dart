import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/service_model.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final ServiceModel? serviceToEdit;

  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _workDaysController = TextEditingController();
  final _workTimeController = TextEditingController();
  final _feesController = TextEditingController();
  final _documentsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _pickedImage;
  bool _showManualUrl = false;

  String? _selectedCategoryId;
  bool _isSaving = false;
  String _savingStatusText = '';

  bool get _isEditing => widget.serviceToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.serviceToEdit!;
      _nameController.text = s.name;
      _descController.text = s.description ?? '';
      _addressController.text = s.address ?? '';
      _phoneController.text = s.phone ?? '';
      _whatsappController.text = s.whatsapp ?? '';
      _emailController.text = s.email ?? '';
      _websiteController.text = s.website ?? '';
      _workDaysController.text = s.workDays ?? '';
      _workTimeController.text = s.workTime ?? '';
      _imageUrlController.text = s.imageUrl ?? '';
      _selectedCategoryId = s.categoryId;
      _feesController.text = s.requirement?.fees ?? '';
      _documentsController.text = s.requirement?.documents ?? '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showError(context, 'تعذر اختيار الصورة: $e');
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختيار صورة الخدمة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('المعرض (الاستوديو)', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('التقاط صورة بالكاميرا', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedImage != null || _imageUrlController.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('إزالة الصورة الحالية',
                      style: TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _imageUrlController.clear();
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editService : AppStrings.addService),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Picker Section
            _buildImagePickerCard(),

            const SizedBox(height: 20),

            _section('معلومات الخدمة الأساسية', [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'اسم الخدمة *', prefixIcon: Icon(Icons.business_outlined)),
                validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'وصف الخدمة', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 14),
              categoriesAsync.when(
                loading: () => const ShimmerCard(height: 56),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                      labelText: 'التصنيف *', prefixIcon: Icon(Icons.category_outlined)),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo'))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? AppStrings.required : null,
                ),
              ),
            ]),

            const SizedBox(height: 20),

            _section('بيانات التواصل والموقع', [
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'العنوان أو الموقع', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الواتساب', prefixIcon: Icon(Icons.chat_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'الموقع الإلكتروني', prefixIcon: Icon(Icons.language_outlined)),
              ),
            ]),

            const SizedBox(height: 20),

            _section('أوقات العمل', [
              TextFormField(
                controller: _workDaysController,
                decoration: const InputDecoration(
                    labelText: 'أيام العمل (مثال: السبت - الخميس)',
                    prefixIcon: Icon(Icons.calendar_today_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _workTimeController,
                decoration: const InputDecoration(
                    labelText: 'ساعات العمل (مثال: 8:00 ص - 2:00 م)',
                    prefixIcon: Icon(Icons.access_time)),
              ),
            ]),

            const SizedBox(height: 20),

            _section('متطلبات الخدمة والرسوم (اختياري)', [
              TextFormField(
                controller: _documentsController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'المستندات المطلوبة',
                    prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _feesController,
                decoration: const InputDecoration(
                    labelText: 'الرسوم المالية', prefixIcon: Icon(Icons.attach_money)),
              ),
            ]),

            const SizedBox(height: 28),

            if (_isSaving && _savingStatusText.isNotEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _savingStatusText,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            LoadingButton(
              isLoading: _isSaving,
              onPressed: _submit,
              label: _isEditing ? AppStrings.saveChanges : AppStrings.addService,
              icon: _isEditing ? Icons.save_outlined : Icons.add_circle_outline,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerCard() {
    final hasPickedFile = _pickedImage != null;
    final hasRemoteUrl = _imageUrlController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'صورة الخدمة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showManualUrl = !_showManualUrl),
                child: Text(
                  _showManualUrl ? 'إخفاء الرابط اليدوي' : 'إدخال رابط بديل',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Image Preview & Pick Area
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: hasPickedFile
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_pickedImage!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'تغيير الصورة',
                                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : hasRemoteUrl
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text('تعذر تحميل الصورة', style: TextStyle(fontFamily: 'Cairo')),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'تغيير الصورة',
                                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'اضغط هنا لرفع صورة من الهاتف (المعرض أو الكاميرا)',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'سيتم حفظ الصورة تلقائياً في السحابة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),

          // Manual URL Input (Optional)
          if (_showManualUrl) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'أو أدخل رابط صورة مباشر',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<String?> _uploadImageIfPicked(String userId) async {
    if (_pickedImage == null) return null;

    setState(() => _savingStatusText = 'جاري رفع صورة الخدمة...');

    final supabase = ref.read(supabaseClientProvider);
    final ext = _pickedImage!.path.split('.').last.toLowerCase();
    final fileName = 'service_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    // Try service-images bucket first, fallback to advertisements or avatars if bucket isn't configured
    final candidateBuckets = ['service-images', 'services', 'advertisements'];

    for (final bucket in candidateBuckets) {
      try {
        await supabase.storage.from(bucket).upload(
              fileName,
              _pickedImage!,
              fileOptions: const FileOptions(upsert: false),
            );
        return supabase.storage.from(bucket).getPublicUrl(fileName);
      } catch (e) {
        // Continue to try next bucket if 404 / bucket not found
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('bucket not found') || errStr.contains('not found') || errStr.contains('404')) {
          continue;
        }
        // If other error, throw to alert user
        rethrow;
      }
    }

    throw 'تعذر رفع الصورة: يرجى التأكد من إنشاء مستودع "service-images" في Supabase Storage وجعله Public.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _savingStatusText = 'جاري حفظ البيانات...';
    });

    try {
      final user = ref.read(authNotifierProvider).value!;

      // Handle image upload from file or fallback to text controller
      String? imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      if (_pickedImage != null) {
        imageUrl = await _uploadImageIfPicked(user.id);
      }

      final docs = _documentsController.text.trim().isEmpty ? null : _documentsController.text.trim();
      final fees = _feesController.text.trim().isEmpty ? null : _feesController.text.trim();

      if (_isEditing) {
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'whatsapp': _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          'work_days': _workDaysController.text.trim().isEmpty ? null : _workDaysController.text.trim(),
          'work_time': _workTimeController.text.trim().isEmpty ? null : _workTimeController.text.trim(),
          'image_url': imageUrl,
          'category_id': _selectedCategoryId!,
        };

        setState(() => _savingStatusText = 'جاري تحديث بيانات الخدمة...');
        await ref.read(serviceCrudProvider.notifier).updateService(
              widget.serviceToEdit!.id,
              updates,
              providerId: user.id,
              documents: docs,
              fees: fees,
            );

        if (mounted) {
          AppHelpers.showSuccess(context, 'تم تعديل الخدمة وحفظ الصورة بنجاح');
          context.pop();
        }
      } else {
        final service = ServiceModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          workDays: _workDaysController.text.trim().isEmpty ? null : _workDaysController.text.trim(),
          workTime: _workTimeController.text.trim().isEmpty ? null : _workTimeController.text.trim(),
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId!,
          providerId: user.id,
        );

        setState(() => _savingStatusText = 'جاري حفظ الخدمة الجديدة...');
        await ref.read(serviceCrudProvider.notifier).addService(
              service,
              documents: docs,
              fees: fees,
            );

        if (mounted) {
          AppHelpers.showSuccess(context, 'تم إضافة الخدمة ورفع الصورة بنجاح');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) AppHelpers.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingStatusText = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _workDaysController.dispose();
    _workTimeController.dispose();
    _feesController.dispose();
    _documentsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
