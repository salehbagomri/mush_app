import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/utils/helpers.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/data/models/service_model.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      body: serviceAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(serviceDetailProvider(serviceId)),
          ),
        ),
        data: (service) => _buildContent(context, service),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServiceModel service) {
    return CustomScrollView(
      slivers: [
        // SliverAppBar with image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  imageUrl: service.imageUrl,
                  height: 250,
                  borderRadius: 0,
                  fallbackIcon: Icons.business_outlined,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (service.isSuspended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('موقف مؤقتاً',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.1),

                if (service.category != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(service.category!.name),
                    avatar: const Icon(Icons.category_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                ],

                if (service.description != null) ...[
                  const SizedBox(height: 16),
                  Text(service.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          )).animate().fadeIn(delay: 100.ms),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Info Cards
                _buildInfoSection(context, service),

                // Action Buttons
                if (service.hasPhone || service.hasWhatsapp || service.hasWebsite) ...[
                  const SizedBox(height: 24),
                  _buildActionButtons(context, service),
                ],

                // Requirements
                if (service.requirement != null &&
                    service.requirement!.hasAnyRequirement) ...[
                  const SizedBox(height: 24),
                  _buildRequirements(context, service),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, ServiceModel service) {
    final items = <Map<String, dynamic>>[];

    if (service.address != null)
      items.add({'icon': Icons.location_on_outlined, 'label': 'العنوان', 'value': service.address, 'color': AppColors.primary});
    if (service.phone != null)
      items.add({'icon': Icons.phone_outlined, 'label': 'الهاتف', 'value': service.phone, 'color': AppColors.success});
    if (service.whatsapp != null)
      items.add({'icon': Icons.chat_outlined, 'label': 'واتساب', 'value': service.whatsapp, 'color': const Color(0xFF25D366)});
    if (service.email != null)
      items.add({'icon': Icons.email_outlined, 'label': 'البريد الإلكتروني', 'value': service.email, 'color': AppColors.info});
    if (service.website != null)
      items.add({'icon': Icons.language_outlined, 'label': 'الموقع الإلكتروني', 'value': service.website, 'color': AppColors.accent});
    if (service.workDays != null)
      items.add({'icon': Icons.calendar_today_outlined, 'label': AppStrings.workDays, 'value': service.workDays, 'color': AppColors.primaryDark});
    if (service.workTime != null)
      items.add({'icon': Icons.access_time, 'label': AppStrings.workTime, 'value': service.workTime, 'color': AppColors.primaryDark});

    return Column(
      children: items
          .map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (item['color'] as Color).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData,
                        color: item['color'] as Color, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: (item['color'] as Color),
                                fontWeight: FontWeight.w600,
                              )),
                          Text(item['value'] as String,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceModel service) {
    return Column(
      children: [
        const Text(
          'تواصل مع الخدمة',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (service.hasPhone)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AppHelpers.callPhone(service.phone!, context: context),
                  icon: const Icon(Icons.phone),
                  label: const Text(AppStrings.callNow),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            if (service.hasPhone && service.hasWhatsapp) const SizedBox(width: 10),
            if (service.hasWhatsapp)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AppHelpers.openWhatsApp(service.whatsapp!, context: context),
                  icon: const Icon(Icons.chat),
                  label: const Text(AppStrings.whatsappNow),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
          ],
        ),
        if (service.hasWebsite) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppHelpers.openWebsite(service.website!, context: context),
              icon: const Icon(Icons.language),
              label: const Text(AppStrings.visitWebsite),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequirements(BuildContext context, ServiceModel service) {
    final req = service.requirement!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(AppStrings.requirements,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      )),
            ],
          ),
          const Divider(height: 20),
          if (req.documents != null && req.documents!.isNotEmpty)
            _reqRow(Icons.description_outlined, AppStrings.documents, req.documents!),
          if (req.fees != null && req.fees!.isNotEmpty)
            _reqRow(Icons.attach_money, AppStrings.fees, req.fees!),
          if (req.age != null && req.age!.isNotEmpty)
            _reqRow(Icons.cake_outlined, 'السن', req.age!),
          if (req.gender != null && req.gender!.isNotEmpty)
            _reqRow(Icons.people_outline, 'الجنس', req.gender!),
          if (req.needsPersonalPhoto)
            _reqRow(Icons.photo_camera_outlined, 'صورة شخصية', 'مطلوبة'),
          if (req.needsImmunizationRecord)
            _reqRow(Icons.vaccines_outlined, 'بطاقة التطعيم', 'مطلوبة'),
        ],
      ),
    );
  }

  Widget _reqRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
