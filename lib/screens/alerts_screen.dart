import 'package:flutter/material.dart';
import '../data/expense_store.dart';
import '../data/notification_store.dart';
import '../models/app_notification.dart';
import '../utils/responsive.dart';

enum AlertLevel { info, warning, danger }

class SmartAlert {
  final IconData icon;
  final String title;
  final String message;
  final AlertLevel level;

  SmartAlert({
    required this.icon,
    required this.title,
    required this.message,
    required this.level,
  });
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  List<SmartAlert> _buildAlerts() {
    final alerts = <SmartAlert>[];

    final expenses = expenseStore.expenses;
    final budget = expenseStore.monthlyBudget;
    final spent = expenseStore.totalSpent;
    final now = DateTime.now();

    // ---------------------------------------------------------
    // 1. No budget set yet
    // ---------------------------------------------------------
    if (!expenseStore.hasBudget) {
      alerts.add(
        SmartAlert(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No budget set',
          message:
              'Set up your monthly budget so I can track your spending pace.',
          level: AlertLevel.info,
        ),
      );
    }

    // ---------------------------------------------------------
    // 2. Haven't logged an expense in a while
    // ---------------------------------------------------------
    if (expenses.isEmpty) {
      alerts.add(
        SmartAlert(
          icon: Icons.edit_note_rounded,
          title: 'No expenses yet',
          message:
              'You haven\'t logged any expenses yet. Add one to start tracking.',
          level: AlertLevel.info,
        ),
      );
    } else {
      final lastExpenseDate = expenses.first.date;
      final daysSinceLastEntry = DateTime(now.year, now.month, now.day)
          .difference(
            DateTime(
              lastExpenseDate.year,
              lastExpenseDate.month,
              lastExpenseDate.day,
            ),
          )
          .inDays;

      if (daysSinceLastEntry == 1) {
        alerts.add(
          SmartAlert(
            icon: Icons.schedule_rounded,
            title: 'Missing yesterday\'s expenses',
            message:
                'You haven\'t updated your expenses since yesterday. Add today\'s spending to keep your budget accurate.',
            level: AlertLevel.warning,
          ),
        );
      } else if (daysSinceLastEntry >= 2) {
        alerts.add(
          SmartAlert(
            icon: Icons.schedule_rounded,
            title: 'Expenses not updated',
            message:
                'It\'s been $daysSinceLastEntry days since your last entry. Log your recent spending so your insights stay accurate.',
            level: AlertLevel.warning,
          ),
        );
      }
    }

    // ---------------------------------------------------------
    // 3. Spending pace vs. budget projection
    // ---------------------------------------------------------
    if (expenseStore.hasBudget && spent > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;

      final dailyAverage = spent / dayOfMonth;
      final projectedSpend = dailyAverage * daysInMonth;

      if (projectedSpend > budget) {
        final overBy = projectedSpend - budget;

        alerts.add(
          SmartAlert(
            icon: Icons.trending_up_rounded,
            title: 'On track to go over budget',
            message:
                'Based on your current pace, you could spend about ₹${projectedSpend.toStringAsFixed(0)} this month — '
                '₹${overBy.toStringAsFixed(0)} more than your ₹${budget.toStringAsFixed(0)} budget. Consider slowing down.',
            level: AlertLevel.danger,
          ),
        );
      }

      final usedPercent = (spent / budget) * 100;

      if (usedPercent >= 90 && projectedSpend <= budget) {
        alerts.add(
          SmartAlert(
            icon: Icons.warning_amber_rounded,
            title: 'Almost at your limit',
            message:
                'You\'ve used ${usedPercent.toStringAsFixed(0)}% of your monthly budget. Only ₹${expenseStore.remainingBudget.toStringAsFixed(0)} left.',
            level: AlertLevel.warning,
          ),
        );
      } else if (usedPercent >= 75 && usedPercent < 90) {
        alerts.add(
          SmartAlert(
            icon: Icons.info_outline_rounded,
            title: 'Budget check-in',
            message:
                'You\'ve used ${usedPercent.toStringAsFixed(0)}% of your monthly budget with ${DateTime(now.year, now.month + 1, 0).day - now.day} days left in the month.',
            level: AlertLevel.info,
          ),
        );
      }
    }

    // ---------------------------------------------------------
    // 4. Biggest category flag
    // ---------------------------------------------------------
    final categories = expenseStore.categoryTotals;

    if (categories.isNotEmpty && budget > 0) {
      final topEntry = categories.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      final categoryShare = (topEntry.value / budget) * 100;

      if (categoryShare >= 40) {
        alerts.add(
          SmartAlert(
            icon: Icons.pie_chart_outline_rounded,
            title: '${topEntry.key} is your biggest spend',
            message:
                '${topEntry.key} makes up ${categoryShare.toStringAsFixed(0)}% of your monthly budget so far (₹${topEntry.value.toStringAsFixed(0)}).',
            level: AlertLevel.info,
          ),
        );
      }
    }

    // ---------------------------------------------------------
    // Fallback: everything looks fine
    // ---------------------------------------------------------
    if (alerts.isEmpty) {
      alerts.add(
        SmartAlert(
          icon: Icons.check_circle_outline_rounded,
          title: 'All good',
          message:
              'No alerts right now — your spending looks healthy and up to date.',
          level: AlertLevel.info,
        ),
      );
    }

    return alerts;
  }

  Color _levelColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.danger:
        return const Color(0xFFE0433D);
      case AlertLevel.warning:
        return const Color(0xFFE8A33D);
      case AlertLevel.info:
        return const Color(0xFF7C3AED);
    }
  }

  Color _levelBackground(AlertLevel level) {
    switch (level) {
      case AlertLevel.danger:
        return const Color(0xFFFDEAEA);
      case AlertLevel.warning:
        return const Color(0xFFFDF3E3);
      case AlertLevel.info:
        return const Color(0xFFF3E8FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        expenseStore,
        notificationStore,
      ]),
      builder: (context, _) {
        final alerts = _buildAlerts();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FC),
            elevation: 0,
            title: const Text(
              'Alerts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 20,
              ),
              children: [
                const Text(
                  'Stay on top of your spending',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Smart reminders based on your budget and activity.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 22),

                ...alerts.map((alert) => _alertCard(alert)),

                ...notificationStore.notifications.map(
                  (notification) => _notificationCard(notification),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _alertCard(SmartAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _levelBackground(alert.level),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              alert.icon,
              color: _levelColor(alert.level),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFF4B5565),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(AppNotification notification) {
    IconData icon;
    AlertLevel level;

    switch (notification.type) {
      case 'budget_exceeded':
        icon = Icons.warning_rounded;
        level = AlertLevel.danger;
        break;

      case 'budget_80':
        icon = Icons.notifications_active_rounded;
        level = AlertLevel.warning;
        break;

      case 'daily_reminder':
        icon = Icons.edit_note_rounded;
        level = AlertLevel.info;
        break;

      case 'ai_coach':
        icon = Icons.auto_awesome_rounded;
        level = AlertLevel.info;
        break;

      default:
        icon = Icons.notifications_outlined;
        level = AlertLevel.info;
    }

    return _alertCard(
      SmartAlert(
        icon: icon,
        title: notification.title,
        message: notification.message,
        level: level,
      ),
    );
  }
}