import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/notification_history_provider.dart';
import 'package:eunora/core/utils/animation_system.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (itemDate == today) {
      return 'TODAY';
    } else if (itemDate == yesterday) {
      return 'YESTERDAY';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dt.month - 1].toUpperCase()} ${dt.day}';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'hrt':
        return Icons.medication;
      case 'log':
        return Icons.edit_calendar;
      case 'insight':
        return Icons.auto_awesome;
      case 'report':
        return Icons.assignment;
      case 'subscription':
        return Icons.stars;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'hrt':
        return const Color(0xFFD946EF); // Pink/purple
      case 'log':
        return const Color(0xFF06B6D4); // Cyan
      case 'insight':
        return AppTheme.primary; // Primary purple
      case 'report':
        return const Color(0xFFF59E0B); // Amber
      case 'subscription':
        return const Color(0xFF10B981); // Emerald
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationHistoryProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    // Group notifications by day
    final Map<String, List<NotificationHistoryItem>> grouped = {};
    for (final item in notifications) {
      final key = _formatDateGroup(item.timestamp);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0), // Matching cream/sand background from HomePage
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0).withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.notoSerif(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                style: GoogleFonts.manrope(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Up to date',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF78716C),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () => ref.read(notificationHistoryProvider.notifier).markAllAsRead(),
              child: Text(
                'Read All',
                style: GoogleFonts.manrope(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFFF7F5F0),
                    title: Text(
                      'Clear all notifications',
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete all notifications from your history?',
                      style: GoogleFonts.manrope(color: AppTheme.onSurface),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.manrope(color: const Color(0xFF78716C)),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ref.read(notificationHistoryProvider.notifier).clearAll();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      color: AppTheme.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New notifications and insights will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF78716C),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                final dateGroup = grouped.keys.elementAt(index);
                final items = grouped[dateGroup]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                      child: Text(
                        dateGroup,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                    ),
                    ...items.map((item) {
                      final typeColor = _getColorForType(item.type);
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(notificationHistoryProvider.notifier).deleteNotification(item.id);
                        },
                        child: Bounceable(
                          onTap: () {
                            ref.read(notificationHistoryProvider.notifier).markAsRead(item.id);
                            // Highlight or act based on type if needed
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isRead
                                    ? const Color(0xFFE7E5E4)
                                    : AppTheme.primary.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForType(item.type),
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.manrope(
                                                  fontWeight: item.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppTheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(item.timestamp),
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                color: const Color(0xFFA8A29E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFF78716C),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
