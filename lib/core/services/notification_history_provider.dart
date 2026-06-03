import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'hrt', 'log', 'insight', 'report', 'subscription'

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  NotificationHistoryItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return NotificationHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type,
      };

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) =>
      NotificationHistoryItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        type: json['type'] as String,
      );
}

class NotificationHistoryNotifier extends StateNotifier<List<NotificationHistoryItem>> {
  NotificationHistoryNotifier() : super([]) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'eunora_notification_history';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        state = decoded
            .map((item) => NotificationHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _seedMockNotifications();
      }
    } catch (e) {
      _seedMockNotifications();
    }
  }

  void _seedMockNotifications() {
    final now = DateTime.now();
    state = [
      NotificationHistoryItem(
        id: 'mock_1',
        title: '📓 How are you feeling today?',
        body: 'Log your symptoms to track patterns and get better AI-powered insights.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
        type: 'log',
      ),
      NotificationHistoryItem(
        id: 'mock_2',
        title: '💊 Time for your HRT',
        body: 'Time to take your Estradiol. Stay consistent for best results.',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: false,
        type: 'hrt',
      ),
      NotificationHistoryItem(
        id: 'mock_3',
        title: '✨ New AI Insight Available',
        body: 'Eunora has spotted a pattern in your recent data. Tap to view.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        type: 'insight',
      ),
      NotificationHistoryItem(
        id: 'mock_4',
        title: '📄 Doctor Report Ready',
        body: 'Your monthly doctor report is ready. Tap to download or share.',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        type: 'report',
      ),
      NotificationHistoryItem(
        id: 'mock_5',
        title: '🔔 Welcome to Eunora Premium',
        body: 'Your account is active. Explore all features and insights!',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
        type: 'subscription',
      ),
    ];
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {}
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final newItem = NotificationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );
    state = [newItem, ...state];
    await _saveToPrefs();
  }

  Future<void> markAsRead(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    await _saveToPrefs();
  }

  Future<void> markAllAsRead() async {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    await _saveToPrefs();
  }

  Future<void> deleteNotification(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveToPrefs();
  }

  Future<void> clearAll() async {
    state = [];
    await _saveToPrefs();
  }
}

final notificationHistoryProvider =
    StateNotifierProvider<NotificationHistoryNotifier, List<NotificationHistoryItem>>((ref) {
  return NotificationHistoryNotifier();
});
