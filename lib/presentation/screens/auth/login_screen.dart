import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/router/app_router.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.hasError) {
        AppHelpers.showError(context, next.error.toString());
      } else if (next.hasValue && next.value != null && !next.isLoading) {
        final user = next.value!;
        if (user.isAdmin) {
          context.go(AppRoutes.adminDashboard);
        } else if (user.isProvider) {
          context.go(AppRoutes.providerDashboard);
        } else {
          context.go(AppRoutes.home);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/icons/logo1.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appName,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          AppStrings.appTagline,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),

                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.login,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text('مرحباً بعودتك',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                )),
                        const SizedBox(height: 24),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return AppStrings.required;
                            if (!v.contains('@')) return AppStrings.invalidEmail;
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return AppStrings.required;
                            if (v.length < 6) return AppStrings.passwordTooShort;
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Forgot Password
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(AppStrings.forgotPassword),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Login Button
                        LoadingButton(
                          isLoading: isLoading,
                          onPressed: _login,
                          label: AppStrings.login,
                          icon: Icons.login_rounded,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.noAccount,
                            style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text(AppStrings.register),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  // Continue as Guest
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                      child: const Text('تصفح كضيف'),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
