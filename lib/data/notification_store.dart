import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'expense_store.dart';

class NotificationStore extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  CollectionReference<Map<String, dynamic>> get _notificationCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  /// Load saved notifications from Firestore.
  Future<void> loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await _notificationCollection
          .orderBy('time', descending: true)
          .limit(50)
          .get();

      _notifications.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final timestamp = data['time'] as Timestamp?;

        if (timestamp == null) continue;

        _notifications.add(
          AppNotification(
            id: doc.id,
            title: data['title'] as String? ?? '',
            message: data['message'] as String? ?? '',
            time: timestamp.toDate(),
            type: data['type'] as String? ?? 'general',
            isRead: data['isRead'] as bool? ?? false,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  void checkBudgetNotifications() {
    final budget = expenseStore.monthlyBudget;
    final spent = expenseStore.totalSpent;

    if (budget <= 0) return;

    final percentage = spent / budget;

    if (percentage >= 1) {
      _addNotification(
        title: 'Budget Exceeded',
        message: "You've exceeded your monthly budget.",
        type: 'budget_exceeded',
      );
      return;
    }

    if (percentage >= 0.8) {
      _addNotification(
        title: 'Budget Warning',
        message: "You've used 80% of your monthly budget.",
        type: 'budget_80',
      );
    }
  }

  void checkDailyReminder() {
    final now = DateTime.now();

    final hasExpenseToday = expenseStore.expenses.any(
      (expense) =>
          expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day,
    );

    if (!hasExpenseToday) {
      _addNotification(
        title: 'Spending Reminder',
        message: "You haven't tracked any expenses today.",
        type: 'daily_reminder',
      );
    }
  }

  void addCoachNotification(String message) {
    _addNotification(
      title: 'AI Coach',
      message: message,
      type: 'ai_coach',
    );
  }

  Future<void> _addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final now = DateTime.now();

    // Prevent duplicate notifications of the same type on the same day.
    final alreadyExists = _notifications.any(
      (notification) =>
          notification.type == type &&
          notification.time.year == now.year &&
          notification.time.month == now.month &&
          notification.time.day == now.day,
    );

    if (alreadyExists) return;

    try {
      final doc = await _notificationCollection.add({
        'title': title,
        'message': message,
        'type': type,
        'time': Timestamp.fromDate(now),
        'isRead': false,
      });

      _notifications.insert(
        0,
        AppNotification(
          id: doc.id,
          title: title,
          message: message,
          type: type,
          time: now,
          isRead: false,
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  /// Mark every notification as read.
  Future<void> markAllAsRead() async {
    final unreadNotifications =
        _notifications.where((notification) => !notification.isRead).toList();

    if (unreadNotifications.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final notification in unreadNotifications) {
        final docRef = _notificationCollection.doc(notification.id);

        batch.update(docRef, {
          'isRead': true,
        });
      }

      await batch.commit();

      for (int i = 0; i < _notifications.length; i++) {
        final notification = _notifications[i];

        if (!notification.isRead) {
          _notifications[i] = AppNotification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            time: notification.time,
            isRead: true,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }
}

final notificationStore = NotificationStore();
