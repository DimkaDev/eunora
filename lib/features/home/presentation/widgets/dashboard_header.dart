import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/notification_history_provider.dart';

class DashboardHeader extends ConsumerWidget {
  final String userName;
  final String date;
  final String cycleInfo;
  final String profileImageUrl;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.date,
    required this.cycleInfo,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationHistoryProvider);
    final hasUnread = notifications.any((n) => !n.isRead);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE7E5E4).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Good morning, $userName',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    date.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF78716C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6D3D1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cycleInfo,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFA8A29E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppTheme.primary),
                    onPressed: () => context.push('/notification-center'),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.primary),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
