import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class TeamMember {
  final String name;
  final String email;
  final String role;
  final String imageAsset;

  const TeamMember({
    required this.name,
    required this.email,
    required this.role,
    required this.imageAsset,
  });
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const List<TeamMember> teamMembers = [
    TeamMember(
      name: 'د.م. إبراهيم فاضل أسكندر',
      email: 'ibrahimeskandarfadhel@gmail.com',
      role: 'مشرف المشروع',
      imageAsset: 'assets/images/team/member1.png',
    ),
    TeamMember(
      name: 'م. صالح أحمد باقمري',
      email: 's.bagomri@gmail.com',
      role: 'عضو فريق العمل',
      imageAsset: 'assets/images/team/member2.png',
    ),
    TeamMember(
      name: 'م. سالم علي الموزعي',
      email: 'salemali71261@gmail.com',
      role: 'عضو فريق العمل',
      imageAsset: 'assets/images/team/member3.png',
    ),
    TeamMember(
      name: 'م. أحمد سالم شيخان',
      email: 'alnino77g@gmail.com',
      role: 'عضو فريق العمل',
      imageAsset: 'assets/images/team/member4.png',
    ),
    TeamMember(
      name: 'م. عبدالعزيز محمد بن محمود',
      email: 'abdulazizbinmahmoud12@gmail.com',
      role: 'عضو فريق العمل',
      imageAsset: 'assets/images/team/member5.png',
    ),
    TeamMember(
      name: 'م. محمد عبدالله العطاس',
      email: 'mohammedalatas1@gmail.com',
      role: 'عضو فريق العمل',
      imageAsset: 'assets/images/team/member6.png',
    ),
  ];

  Future<void> _sendEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('البريد: $email')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('البريد: $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('من نحن'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting Illustration Banner
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/team_header.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.groups_outlined,
                            size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'فريق العمل',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),

            const SizedBox(height: 14),

            // Team Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final member = teamMembers[i];
                final isLead = i == 0; // Supervisor

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isLead
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: _buildAvatar(member, i),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isLead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مشرف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: () => _sendEmail(context, member.email),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                member.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1, curve: Curves.easeOut);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(TeamMember member, int index) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          member.imageAsset,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // Elegant fallback avatar with member initials if image file not yet copied
            final initial = member.name.replaceAll('د.م. ', '').replaceAll('م. ', '').characters.firstOrNull ?? 'م';
            final colors = [
              AppColors.primary,
              const Color(0xFF0288D1),
              const Color(0xFF7B1FA2),
              const Color(0xFFE64A19),
              const Color(0xFF388E3C),
              const Color(0xFF5D4037),
            ];
            final color = colors[index % colors.length];

            return Container(
              color: color.withValues(alpha: 0.15),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
