import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mush_app/core/constants/app_colors.dart';
import 'package:mush_app/core/constants/app_strings.dart';
import 'package:mush_app/core/widgets/shared_widgets.dart';
import 'package:mush_app/presentation/providers/services_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: AppStrings.searchHint,
            hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
            ),
        ],
      ),
      body: query.length < 2
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: AppColors.divider),
                  SizedBox(height: 16),
                  Text('اكتب للبحث...',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: AppColors.textSecondary)),
                ],
              ),
            )
          : resultsAsync.when(
              loading: () => const ShimmerList(count: 5),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (results) {
                if (results.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.noResults,
                    subtitle: 'لا توجد نتائج لـ "$query"',
                    icon: Icons.search_off_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final service = results[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppNetworkImage(
                          imageUrl: service.imageUrl,
                          width: 52,
                          height: 52,
                          fallbackIcon: Icons.business_outlined,
                        ),
                      ),
                      title: Text(service.name,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      subtitle: service.address != null
                          ? Text(service.address!,
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))
                          : null,
                      trailing: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                      onTap: () => context.push('/services/${service.id}'),
                    );
                  },
                );
              },
            ),
    );
  }
}
