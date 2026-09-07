import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/expense_store.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'budget_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You will need to log in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _openNotificationPreferences(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPreferencesScreen(),
      ),
    );
  }

  void _openPrivacySecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacySecurityScreen(),
      ),
    );
  }

  void _openHelpSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';
    final initial = email.isNotEmpty
        ? email[0].toUpperCase()
        : '?';

    return AnimatedBuilder(
      animation: expenseStore,
      builder: (context, _) {
        final budget = expenseStore.monthlyBudget;
        final spent = expenseStore.totalSpent;
        final remaining = expenseStore.remainingBudget;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),

          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FC),
            elevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  // ==========================
                  // PROFILE CARD
                  // ==========================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Signed in as',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                email,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==========================
                  // BUDGET OVERVIEW
                  // ==========================

                  const Text(
                    'Budget Overview',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE3E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        _statColumn(
                          'Budget',
                          '₹${budget.toStringAsFixed(0)}',
                        ),

                        _statColumn(
                          'Spent',
                          '₹${spent.toStringAsFixed(0)}',
                        ),

                        _statColumn(
                          'Remaining',
                          '₹${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==========================
                  // SETTINGS
                  // ==========================

                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // EDIT BUDGET

                  _menuTile(
                    icon: Icons
                        .account_balance_wallet_outlined,
                    label: 'Edit Monthly Budget',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BudgetSetupScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // NOTIFICATIONS

                  _menuTile(
                    icon:
                        Icons.notifications_none_rounded,
                    label: 'Notification Preferences',
                    onTap: () {
                      _openNotificationPreferences(
                        context,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // PRIVACY

                  _menuTile(
                    icon:
                        Icons.privacy_tip_outlined,
                    label: 'Privacy & Security',
                    onTap: () {
                      _openPrivacySecurity(context);
                    },
                  ),

                  const SizedBox(height: 10),

                  // HELP

                  _menuTile(
                    icon:
                        Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {
                      _openHelpSupport(context);
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==========================
                  // LOGOUT
                  // ==========================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _logout(context);
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE3E8F0),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================
  // STAT COLUMN
  // ==========================

  Widget _statColumn(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==========================
  // MENU TILE
  // ==========================

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3E8FF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF7C3AED),
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF172033),
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// NOTIFICATION PREFERENCES SCREEN
// ============================================================

class NotificationPreferencesScreen
    extends StatefulWidget {
  const NotificationPreferencesScreen({
    super.key,
  });

  @override
  State<NotificationPreferencesScreen>
      createState() =>
          _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {

  bool budgetAlerts = true;
  bool spendingAlerts = true;
  bool dailyReminders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FC),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF172033),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Notification Preferences',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // HEADER

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3E8FF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons
                            .notifications_active_outlined,
                        color:
                            Color(0xFF7C3AED),
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Stay informed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF172033),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Choose which spending reminders you want to receive.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // BUDGET ALERTS

              _notificationCard(
                icon: Icons
                    .account_balance_wallet_outlined,
                title: 'Budget Alerts',
                description:
                    'Get alerts when you are nearing your monthly budget.',
                value: budgetAlerts,
                onChanged: (value) {
                  setState(() {
                    budgetAlerts = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              // SPENDING ALERTS

              _notificationCard(
                icon:
                    Icons.trending_up_rounded,
                title: 'Spending Alerts',
                description:
                    'Get alerts when your spending is unusually high.',
                value: spendingAlerts,
                onChanged: (value) {
                  setState(() {
                    spendingAlerts = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              // DAILY REMINDERS

              _notificationCard(
                icon:
                    Icons.access_time_rounded,
                title: 'Daily Reminders',
                description:
                    'Receive a reminder to review your daily expenses.',
                value: dailyReminders,
                onChanged: (value) {
                  setState(() {
                    dailyReminders = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF3E8FF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF7C3AED),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Switch(
            value: value,
            activeColor:
                const Color(0xFF7C3AED),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


// ============================================================
// PRIVACY & SECURITY SCREEN
// ============================================================

class PrivacySecurityScreen
    extends StatelessWidget {
  const PrivacySecurityScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FC),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF172033),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // HEADER

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3E8FF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color:
                            Color(0xFF7C3AED),
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Your data matters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF172033),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'SpendWise uses Firebase services to protect your account and data.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _securityCard(
                icon:
                    Icons.lock_outline_rounded,
                title:
                    'Secure Authentication',
                description:
                    'Your SpendWise account is protected using Firebase Authentication.',
              ),

              const SizedBox(height: 14),

              _securityCard(
                icon:
                    Icons.cloud_outlined,
                title:
                    'Secure Data Storage',
                description:
                    'Your budget and expense information is stored securely in Firebase.',
              ),

              const SizedBox(height: 14),

              _securityCard(
                icon:
                    Icons.security_outlined,
                title: 'Data Protection',
                description:
                    'SpendWise uses Firebase security services to help protect your information.',
              ),

              const SizedBox(height: 14),

              _securityCard(
                icon:
                    Icons.privacy_tip_outlined,
                title: 'Your Privacy',
                description:
                    'Your personal spending information is associated with your authenticated account.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _securityCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF3E8FF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF7C3AED),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// HELP & SUPPORT SCREEN
// ============================================================

class HelpSupportScreen
    extends StatelessWidget {
  const HelpSupportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FC),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF172033),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // HEADER

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3E8FF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons
                            .support_agent_rounded,
                        color:
                            Color(0xFF7C3AED),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'How can we help?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF172033),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Find answers to common questions about SpendWise.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 14),

              _faqTile(
                question:
                    'How does OCR expense scanning work?',
                answer:
                    'SpendWise uses your transaction screenshot to extract details such as the amount, merchant, date and category automatically.',
              ),

              const SizedBox(height: 10),

              _faqTile(
                question:
                    'Can I edit a transaction?',
                answer:
                    'Yes. Open All Transactions, select a transaction and choose Edit Transaction to update its details.',
              ),

              const SizedBox(height: 10),

              _faqTile(
                question:
                    'Can I delete a transaction?',
                answer:
                    'Yes. Open a transaction, choose Delete Transaction and confirm the deletion. The transaction is removed from your account.',
              ),

              const SizedBox(height: 10),

              _faqTile(
                question:
                    'How does the AI Coach work?',
                answer:
                    'The AI Coach uses your budget and spending history to answer questions, identify spending patterns and provide personalized suggestions.',
              ),

              const SizedBox(height: 10),

              _faqTile(
                question:
                    'How is my monthly budget calculated?',
                answer:
                    'Your monthly budget is the amount you set in SpendWise. Your dashboard and alerts use your current month spending to calculate your remaining budget.',
              ),

              const SizedBox(height: 28),

              // SUPPORT CARD

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        const Color(0xFFE3E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFFF3E8FF),
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons
                            .chat_bubble_outline_rounded,
                        color:
                            Color(0xFF7C3AED),
                        size: 24,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'If you are facing an issue, check the FAQs above or contact your SpendWise support team.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqTile({
    required String question,
    required String answer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),

        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),

        iconColor:
            const Color(0xFF7C3AED),

        collapsedIconColor:
            Colors.grey,

        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF172033),
          ),
        ),

        children: [
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}