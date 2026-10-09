import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';

class UpdateProfileScreen extends ConsumerStatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  ConsumerState<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends ConsumerState<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value;
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.updateProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null)
                              as ImageProvider?,
                      child: (_pickedImage == null && user?.avatarUrl == null)
                          ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.username,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
              ),

              const SizedBox(height: 32),

              // Save Button
              LoadingButton(
                isLoading: _isSaving,
                onPressed: _saveProfile,
                label: AppStrings.saveChanges,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (xFile != null) {
      setState(() => _pickedImage = File(xFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? avatarUrl;

      // Upload image to Supabase Storage if picked
      if (_pickedImage != null) {
        final user = ref.read(authNotifierProvider).value!;
        final supabase = ref.read(supabaseClientProvider);
        final fileName = '${user.id}_avatar.jpg';
        await supabase.storage.from('avatars').upload(
              fileName,
              _pickedImage!,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      await ref.read(authNotifierProvider.notifier).updateProfile(
            username: _usernameController.text.trim(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        AppHelpers.showSuccess(context, 'تم تحديث الملف الشخصي بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppHelpers.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
